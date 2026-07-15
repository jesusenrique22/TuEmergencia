import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../auth/domain/models/role.dart';
import '../../../../core/auth/app_session.dart';
import '../../../emergency/application/emergency_tracking_controller.dart';
import '../../../emergency/domain/models/emergency_models.dart';
import '../../../emergency/domain/repositories/emergency_repository.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../emergency/presentation/widgets/ambulance_delivery_tracking_ui.dart';
import '../../../emergency/presentation/widgets/live_ambulance_tracking_map.dart';

/// Panel compartido por conductor, paramédico y enfermero de ambulancia.
class AmbulanceCrewDashboard extends StatefulWidget {
  const AmbulanceCrewDashboard({super.key});

  @override
  State<AmbulanceCrewDashboard> createState() => _AmbulanceCrewDashboardState();
}

class _AmbulanceCrewDashboardState extends State<AmbulanceCrewDashboard>
    with TickerProviderStateMixin {
  final _emergency = sl<EmergencyRepository>();
  DriverLocationPublisher? _publisher;

  bool _loading = true;
  List<EmergencyRequest> _assignments = [];
  List<EmergencyRequest> _pendingRequests = [];
  String? _error;
  Timer? _refreshTimer;
  StreamSubscription<Map<String, dynamic>>? _incomingSub;
  StreamSubscription<Map<String, dynamic>>? _updatedSub;

  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final AnimationController _alertPulseController;

  bool get _isDriver => AppSession.activeRole == Role.driver;

  String get _panelTitle {
    return switch (AppSession.activeRole) {
      Role.paramedic => 'Panel paramédico',
      Role.ambulanceNurse => 'Panel enfermería',
      _ => 'Panel de conductor',
    };
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _alertPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _load();
    // Auto-refresh every 30s as fallback
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());

    // Connect socket and listen for new emergency requests in real-time
    unawaited(AppRealtime.connectIfNeeded());
    _incomingSub = AppRealtime.chatSocket.onEmergencyIncoming.listen((_) {
      _load();
      if (mounted) {
        _alertPulseController.forward(from: 0).then((_) {
          _alertPulseController.reverse();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text(
                  '🚨 Nueva solicitud de ambulancia entrante',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: AppColors.emergency,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    });

    _updatedSub = AppRealtime.chatSocket.onEmergencyUpdated.listen((_) => _load());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _alertPulseController.dispose();
    _refreshTimer?.cancel();
    _incomingSub?.cancel();
    _updatedSub?.cancel();
    _publisher?.stop();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _emergency.listMine();
      List<EmergencyRequest> pending = [];
      try {
        pending = await _emergency.getPendingRequests();
      } catch (_) {}
      if (!mounted) return;
      final hadNoPending = _pendingRequests.isEmpty;
      setState(() {
        _assignments = items;
        _pendingRequests = pending;
        _loading = false;
      });
      if (hadNoPending && pending.isNotEmpty) {
        _slideController.forward(from: 0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<EmergencyRequest> get _active =>
      _assignments.where((e) => !e.status.isTerminal).toList();

  Future<void> _startGps(EmergencyRequest assignment) async {
    _publisher ??= sl<DriverLocationPublisher>();
    await _publisher!.start(assignment);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.gps_fixed, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('GPS en tiempo real activo'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openEmergency(EmergencyRequest item) {
    Navigator.pushNamed(
      context,
      AppRoutes.ambulanceEmergencyDetail,
      arguments: {'emergencyId': item.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;

    return DefaultTabController(
      length: 2,
      child: ResponsiveScaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.airport_shuttle_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                _panelTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            labelColor: AppColors.emergency,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.emergency,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_shipping_rounded, size: 18),
                    const SizedBox(width: 6),
                    const Text('ACTIVAS'),
                    if (active.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emergency,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${active.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 18),
                    const SizedBox(width: 6),
                    const Text('NUEVAS'),
                    if (_pendingRequests.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color.lerp(AppColors.emergency, const Color(0xFFFF6B6B), _pulseController.value),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_pendingRequests.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Mi perfil',
              icon: const Icon(Icons.person_rounded, color: AppColors.textSecondary),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.ambulanceCrewProfile),
            ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            ),
            const NotificationBadge(),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Cargando servicios...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : _error != null
                ? _buildError()
                : TabBarView(
                    children: [
                      _buildActiveTab(active),
                      _buildPendingTab(),
                    ],
                  ),
        floatingActionButton: _isDriver && active.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _startGps(active.first),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.gps_fixed, color: Colors.white),
                label: const Text('GPS en vivo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.signal_wifi_off_rounded, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(List<EmergencyRequest> active) {
    if (active.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.airport_shuttle_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin emergencias activas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Revisa la pestaña "NUEVAS" para aceptar solicitudes disponibles.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      itemBuilder: (context, index) {
        final item = active[index];
        return _buildActiveCard(item);
      },
    );
  }

  Widget _buildActiveCard(EmergencyRequest item) {
    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case EmergencyStatus.dispatched:
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.directions_car_rounded;
      case EmergencyStatus.onScene:
        statusColor = const Color(0xFFF97316);
        statusIcon = Icons.location_on_rounded;
      case EmergencyStatus.patientOnboard:
        statusColor = const Color(0xFF8B5CF6);
        statusIcon = Icons.airline_seat_flat_angled_rounded;
      case EmergencyStatus.enRoute:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.speed_rounded;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.airport_shuttle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: statusColor,
              child: Row(
                children: [
                  Icon(statusIcon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    item.status.label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.local_hospital_rounded, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.facility?.name ?? 'Clínica de destino',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              item.originAddress ?? 'Coordenadas del paciente',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openEmergency(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('VER EN MAPA', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin nuevas solicitudes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuando un paciente solicite ayuda, aparecerá aquí para que puedas aceptar el servicio.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Interval(
              index * 0.1,
              1.0,
              curve: Curves.easeOutBack,
            ),
          )),
          child: _buildPendingCard(_pendingRequests[index]),
        );
      },
    );
  }

  Widget _buildPendingCard(EmergencyRequest item) {
    final painLevel = item.painLevel ?? 5;
    final isUrgent = painLevel >= 7;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUrgent
                  ? [
                      const Color(0xFF7F1D1D),
                      Color.lerp(const Color(0xFF991B1B), const Color(0xFFDC2626), _pulseController.value)!,
                    ]
                  : [
                      const Color(0xFF1E293B),
                      const Color(0xFF334155),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isUrgent ? AppColors.emergency : const Color(0xFF334155))
                    .withValues(alpha: 0.4 + 0.2 * _pulseController.value),
                blurRadius: 20 + 5 * _pulseController.value,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Alert Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUrgent ? const Color(0xFFFCA5A5) : Colors.white70,
                        boxShadow: [
                          BoxShadow(
                            color: isUrgent
                                ? Colors.red.withValues(alpha: 0.6 + 0.4 * _pulseController.value)
                                : Colors.white.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isUrgent ? '⚠️ EMERGENCIA CRÍTICA' : '🚑 NUEVA SOLICITUD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _timeAgo(item.requestedAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pain indicator
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nivel de dolor',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(10, (i) {
                                return Expanded(
                                  child: Container(
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: i < painLevel
                                          ? (i >= 7
                                              ? const Color(0xFFFCA5A5)
                                              : i >= 4
                                                  ? const Color(0xFFFBBF24)
                                                  : const Color(0xFF4ADE80))
                                          : Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$painLevel/10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info rows
                  _infoRow(Icons.location_on_rounded, 'Origen', item.originAddress ?? 'Coordenadas del paciente'),
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.local_hospital_rounded,
                    'Destino',
                    item.facility?.name ?? 'Por asignar',
                  ),
                  if (item.symptoms?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _infoRow(Icons.sick_rounded, 'Síntomas', item.symptoms!),
                  ],
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.payments_rounded,
                    'Pago',
                    '${_paymentLabel(item.paymentMethod)} ${item.quotedCost != null ? "  •  \$${item.quotedCost!.toStringAsFixed(2)}" : ""}',
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Dismiss without accepting (skip)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Solicitud omitida'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('OMITIR', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _showAcceptConfirmation(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.emergency,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'ACEPTAR VIAJE',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _paymentLabel(String? method) {
    switch (method) {
      case 'PAGO_MOVIL':
        return '📱 Pago Móvil';
      case 'CASH':
        return '💵 Efectivo';
      case 'CARD':
        return '💳 Tarjeta';
      case 'INSURANCE':
        return '🛡️ Seguro';
      default:
        return method ?? 'Efectivo';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}min';
    return 'hace ${diff.inHours}h';
  }

  void _showAcceptConfirmation(EmergencyRequest item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.airport_shuttle_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Aceptar este servicio?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Serás asignado para ir a buscar al paciente y transportarlo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _summaryRow('Origen', item.originAddress ?? 'Coordenadas'),
                  const SizedBox(height: 8),
                  _summaryRow('Destino', item.facility?.name ?? 'Por asignar'),
                  const SizedBox(height: 8),
                  _summaryRow('Nivel de dolor', '${item.painLevel ?? 5}/10'),
                  if (item.quotedCost != null) ...[
                    const SizedBox(height: 8),
                    _summaryRow('Pago estimado', '\$${item.quotedCost!.toStringAsFixed(2)}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetCtx);
                      setState(() => _loading = true);
                      try {
                        final updated = await _emergency.acceptEmergency(item.id);
                        await _load();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white),
                                SizedBox(width: 8),
                                Text('¡Servicio aceptado!'),
                              ],
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        if (_isDriver) await _startGps(updated);
                        _openEmergency(updated);
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppColors.emergency,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'ACEPTAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Detalle con mapa de la ubicación solicitada y datos clínicos básicos.
class AmbulanceEmergencyDetailScreen extends StatefulWidget {
  const AmbulanceEmergencyDetailScreen({super.key, this.emergencyId = ''});

  final String emergencyId;

  @override
  State<AmbulanceEmergencyDetailScreen> createState() =>
      _AmbulanceEmergencyDetailScreenState();
}

class _AmbulanceEmergencyDetailScreenState
    extends State<AmbulanceEmergencyDetailScreen> {
  late final EmergencyTrackingController _controller;
  DriverLocationPublisher? _publisher;
  bool _updatingStatus = false;

  bool get _isDriver => AppSession.activeRole == Role.driver;

  @override
  void initState() {
    super.initState();
    _controller = sl<EmergencyTrackingController>();
    _controller.addListener(_onChanged);
    if (widget.emergencyId.isNotEmpty) {
      unawaited(_startTracking());
    }
  }

  Future<void> _startTracking() async {
    await _controller.start(widget.emergencyId);
    if (!mounted || !_isDriver) return;
    final em = _controller.emergency;
    if (em != null && !em.status.isTerminal) {
      _publisher ??= sl<DriverLocationPublisher>();
      await _publisher!.start(em);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    unawaited(_publisher?.stop());
    super.dispose();
  }

  Future<void> _updateStatus(String id, EmergencyStatus target) async {
    setState(() => _updatingStatus = true);
    try {
      final repo = sl<EmergencyRepository>();
      await repo.updateStatus(id, target);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado: ${target.label}'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (target == EmergencyStatus.completed) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading && _controller.emergency == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_controller.error != null && _controller.emergency == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => AppNavigation.safeBack(context),
          ),
        ),
        body: Center(child: Text(_controller.error!)),
      );
    }

    final emergency = _controller.emergency!;

    String? btnText;
    Color btnColor = AppColors.primary;
    IconData btnIcon = Icons.check_rounded;
    EmergencyStatus? targetStatus;

    if (emergency.status == EmergencyStatus.dispatched) {
      btnText = 'LLEGUÉ AL PACIENTE';
      btnColor = const Color(0xFF3B82F6);
      btnIcon = Icons.location_on_rounded;
      targetStatus = EmergencyStatus.onScene;
    } else if (emergency.status == EmergencyStatus.onScene) {
      btnText = 'PACIENTE A BORDO';
      btnColor = const Color(0xFFF97316);
      btnIcon = Icons.airline_seat_flat_angled_rounded;
      targetStatus = EmergencyStatus.patientOnboard;
    } else if (emergency.status == EmergencyStatus.patientOnboard ||
        emergency.status == EmergencyStatus.enRoute) {
      btnText = 'LLEGUÉ A LA CLÍNICA';
      btnColor = AppColors.primary;
      btnIcon = Icons.local_hospital_rounded;
      targetStatus = EmergencyStatus.completed;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                LiveAmbulanceTrackingMap(
                  request: emergency,
                  trail: _controller.locationTrail,
                  routePoints: _controller.routePoints,
                  distanceRemainingKm: _controller.distanceRemainingKm,
                  ambulanceBearing: _controller.ambulanceBearing,
                  followAmbulance: _controller.followAmbulance,
                  isDriverView: true,
                  onFollowChanged: _controller.setFollowAmbulance,
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => AppNavigation.safeBack(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      emergency.status.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom panel
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20, 16, 20, MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrackingStatusTimeline(
                        status: emergency.status,
                        compact: true,
                      ),
                      const SizedBox(height: 16),
                      DriverNavigationPanel(
                        emergency: emergency,
                        distanceKm: _controller.distanceRemainingKm,
                      ),
                      const SizedBox(height: 16),
                      // Destino / clínica
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.emergencyLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.local_hospital_rounded, color: AppColors.emergency, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emergency.facility?.name ?? 'Clínica de destino',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  emergency.originAddress ?? 'Origen del paciente',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (emergency.symptoms?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sick_rounded, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  emergency.symptoms!,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (btnText != null && targetStatus != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _updatingStatus
                                ? null
                                : () => _updateStatus(emergency.id, targetStatus!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _updatingStatus
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(btnIcon, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        btnText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
