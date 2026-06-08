import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../auth/domain/models/role.dart';
import '../../../../core/auth/app_session.dart';
import '../../../emergency/application/emergency_tracking_controller.dart';
import '../../../emergency/domain/models/emergency_models.dart';
import '../../../emergency/domain/repositories/emergency_repository.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../widgets/ambulance_emergency_map.dart';

/// Panel compartido por conductor, paramédico y enfermero de ambulancia.
class AmbulanceCrewDashboard extends StatefulWidget {
  const AmbulanceCrewDashboard({super.key});

  @override
  State<AmbulanceCrewDashboard> createState() => _AmbulanceCrewDashboardState();
}

class _AmbulanceCrewDashboardState extends State<AmbulanceCrewDashboard> {
  final _emergency = sl<EmergencyRepository>();
  DriverLocationPublisher? _publisher;

  bool _loading = true;
  List<EmergencyRequest> _assignments = [];
  String? _error;

  bool get _isDriver => AppSession.activeRole == Role.driver;

  String get _panelTitle {
    return switch (AppSession.activeRole) {
      Role.paramedic => 'Panel paramédico',
      Role.ambulanceNurse => 'Panel enfermería móvil',
      _ => 'Panel de conductor',
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _publisher?.stop();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _emergency.listMine();
      if (!mounted) return;
      setState(() {
        _assignments = items;
        _loading = false;
      });
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
      const SnackBar(content: Text('GPS en tiempo real activo')),
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

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_panelTitle),
        actions: [
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.ambulanceCrewProfile),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          const NotificationBadge(),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : active.isEmpty
                  ? const Center(child: Text('Sin emergencias asignadas'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: active.length,
                      itemBuilder: (context, index) {
                        final item = active[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.emergency.withValues(alpha: 0.12),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.emergency,
                              ),
                            ),
                            title: Text(item.status.label),
                            subtitle: Text(
                              '${item.facility?.name ?? 'Clínica'}\n'
                              'Origen: ${item.originAddress ?? item.origin}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _openEmergency(item),
                          ),
                        );
                      },
                    ),
      floatingActionButton: _isDriver && active.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _startGps(active.first),
              icon: const Icon(Icons.gps_fixed),
              label: const Text('GPS en vivo'),
            )
          : null,
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

  @override
  void initState() {
    super.initState();
    _controller = sl<EmergencyTrackingController>();
    _controller.addListener(_onChanged);
    if (widget.emergencyId.isNotEmpty) {
      _controller.start(widget.emergencyId);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
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

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Emergencia activa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => AppNavigation.safeBack(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AmbulanceEmergencyMap(request: emergency),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emergency.status.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Destino: ${emergency.facility?.name ?? 'Clínica'}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  'Punto de solicitud: ${emergency.originAddress ?? emergency.origin}',
                  style: const TextStyle(color: Colors.black87),
                ),
                if (emergency.symptoms?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Síntomas: ${emergency.symptoms}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                if (emergency.medicalHistory?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text('Antecedentes: ${emergency.medicalHistory}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
