import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/geo/geo_math.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/emergency_tracking_controller.dart';
import '../../domain/models/emergency_models.dart';
import '../widgets/ambulance_delivery_tracking_ui.dart';
import '../widgets/live_ambulance_tracking_map.dart';

class AmbulanceTracking extends StatefulWidget {
  final String emergencyId;
  const AmbulanceTracking({super.key, this.emergencyId = ''});

  @override
  State<AmbulanceTracking> createState() => _AmbulanceTrackingState();
}

class _AmbulanceTrackingState extends State<AmbulanceTracking> {
  late final EmergencyTrackingController _controller;
  DriverLocationPublisher? _patientPublisher;

  @override
  void initState() {
    super.initState();
    _controller = sl<EmergencyTrackingController>();
    _controller.addListener(_onChanged);
    unawaited(AppRealtime.connectIfNeeded());
    unawaited(_start());
  }

  Future<void> _start() async {
    await _controller.start(widget.emergencyId);
    final em = _controller.emergency;
    if (!mounted || em == null || em.status.isTerminal) return;
    _patientPublisher ??= sl<DriverLocationPublisher>();
    await _patientPublisher!.start(em);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    unawaited(_patientPublisher?.stop());
    super.dispose();
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cancelar solicitud?'),
        content: const Text(
          'Se cancelará la solicitud de ambulancia. ¿Estás seguro?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.cancel();
      if (!mounted) return;
      AppNavigation.safeBack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading && _controller.emergency == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_controller.error != null && _controller.emergency == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_controller.error!)),
      );
    }

    final emergency = _controller.emergency!;
    final isSearching = emergency.status == EmergencyStatus.requested;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          LiveAmbulanceTrackingMap(
            request: emergency,
            trail: _controller.locationTrail,
            routePoints: _controller.routePoints,
            distanceRemainingKm: _controller.distanceRemainingKm,
            ambulanceBearing: _controller.ambulanceBearing,
            followAmbulance: _controller.followAmbulance,
            onFollowChanged: _controller.setFollowAmbulance,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _TopBarButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => AppNavigation.safeBack(context),
            ),
          ),
          if (isSearching)
            SearchingAmbulanceOverlay(
              emergency: emergency,
              cancelling: _controller.cancelling,
              onCancel: _cancel,
            )
          else
            _PatientTrackingSheet(
              controller: _controller,
              emergency: emergency,
              onCancel: _cancel,
            ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      color: Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _PatientTrackingSheet extends StatelessWidget {
  const _PatientTrackingSheet({
    required this.controller,
    required this.emergency,
    required this.onCancel,
  });

  final EmergencyTrackingController controller;
  final EmergencyRequest emergency;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.22,
      maxChildSize: 0.72,
      snap: true,
      snapSizes: const [0.22, 0.34, 0.72],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emergency.status.label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (emergency.etaMinutes != null)
                          Text(
                            'Llegada estimada: ${GeoMath.formatEta(emergency.etaMinutes)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (controller.distanceRemainingKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        GeoMath.formatDistance(controller.distanceRemainingKm!),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TrackingStatusTimeline(status: emergency.status, compact: true),
              const SizedBox(height: 16),
              TrackingDriverCard(
                emergency: emergency,
                onCall: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Llamada WebRTC próximamente')),
                  );
                },
              ),
              if (emergency.facility != null) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: AppColors.emergency),
                  ),
                  title: const Text('Destino', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  subtitle: Text(
                    emergency.facility!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: controller.cancelling ? null : onCancel,
                icon: controller.cancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancelar solicitud'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emergency,
                  side: const BorderSide(color: AppColors.emergency),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
