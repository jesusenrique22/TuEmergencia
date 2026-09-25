import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/geo/geo_math.dart';
import '../../../../core/geo/geo_point.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/emergency_navigation.dart';
import '../../domain/models/emergency_models.dart';

/// UI estilo delivery: timeline de estados, sheet del conductor y navegación externa.
class AmbulanceDeliveryTrackingUi {
  AmbulanceDeliveryTrackingUi._();
}

/// Stepper horizontal como Yummy/Ridery/Push.
class TrackingStatusTimeline extends StatelessWidget {
  const TrackingStatusTimeline({
    super.key,
    required this.status,
    this.compact = false,
  });

  final EmergencyStatus status;
  final bool compact;

  static const _steps = [
    (EmergencyStatus.dispatched, 'En camino', Icons.local_shipping_rounded),
    (EmergencyStatus.onScene, 'En el lugar', Icons.location_on_rounded),
    (EmergencyStatus.patientOnboard, 'A bordo', Icons.airline_seat_flat_rounded),
    (EmergencyStatus.enRoute, 'A clínica', Icons.local_hospital_rounded),
    (EmergencyStatus.completed, 'Entregado', Icons.check_circle_rounded),
  ];

  int _activeIndex() {
    if (status == EmergencyStatus.requested) return -1;
    if (status == EmergencyStatus.cancelled) return -1;
    for (var i = _steps.length - 1; i >= 0; i--) {
      if (_statusRank(status) >= _statusRank(_steps[i].$1)) return i;
    }
    return 0;
  }

  int _statusRank(EmergencyStatus s) {
    return switch (s) {
      EmergencyStatus.requested => 0,
      EmergencyStatus.dispatched => 1,
      EmergencyStatus.onScene => 2,
      EmergencyStatus.patientOnboard => 3,
      EmergencyStatus.enRoute => 4,
      EmergencyStatus.arrived => 5,
      EmergencyStatus.completed => 6,
      EmergencyStatus.cancelled => -1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex();
    return SizedBox(
      height: compact ? 72 : 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _steps.length,
        separatorBuilder: (_, __) => SizedBox(
          width: compact ? 8 : 12,
          child: Center(
            child: Container(
              width: compact ? 16 : 24,
              height: 2,
              color: AppColors.border,
            ),
          ),
        ),
        itemBuilder: (context, index) {
          final step = _steps[index];
          final done = index <= active;
          final current = index == active;
          return _StepChip(
            label: step.$2,
            icon: step.$3,
            done: done,
            current: current,
            compact: compact,
          );
        },
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.icon,
    required this.done,
    required this.current,
    required this.compact,
  });

  final String label;
  final IconData icon;
  final bool done;
  final bool current;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = current
        ? AppColors.primary
        : done
            ? AppColors.primary.withValues(alpha: 0.7)
            : AppColors.textTertiary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
          decoration: BoxDecoration(
            color: current
                ? AppColors.primary
                : done
                    ? AppColors.primaryLight
                    : AppColors.surfaceSoft,
            shape: BoxShape.circle,
            border: current
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            
          ),
          child: Icon(
            icon,
            size: compact ? 18 : 22,
            color: current ? Colors.white : color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 9 : 10,
            fontWeight: current ? FontWeight.bold : FontWeight.w600,
            color: current ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class TrackingDriverCard extends StatelessWidget {
  const TrackingDriverCard({
    super.key,
    required this.emergency,
    this.onCall,
  });

  final EmergencyRequest emergency;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final driver = emergency.ambulance?.driver;
    if (driver == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            backgroundImage:
                driver.profilePic != null ? NetworkImage(driver.profilePic!) : null,
            child: driver.profilePic == null
                ? Text(
                    driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  emergency.ambulance?.displayName ?? 'Unidad asignada',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: onCall,
            icon: const Icon(Icons.call_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class DriverNavigationPanel extends StatelessWidget {
  const DriverNavigationPanel({
    super.key,
    required this.emergency,
    required this.distanceKm,
    this.onOpenMaps,
  });

  final EmergencyRequest emergency;
  final double? distanceKm;
  final VoidCallback? onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final dest = EmergencyNavigation.destination(emergency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.navigation_rounded,
                color: Color(0xFF2563EB),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EmergencyNavigation.destinationHint(emergency),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    EmergencyNavigation.destinationLabel(emergency),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (distanceKm != null)
              Text(
                GeoMath.formatDistance(distanceKm!),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF2563EB),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenMaps ?? () => openExternalNavigation(dest),
            icon: const Icon(Icons.map_rounded),
            label: const Text('ABRIR EN GOOGLE MAPS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> openExternalNavigation(GeoPoint destination) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class SearchingAmbulanceOverlay extends StatelessWidget {
  const SearchingAmbulanceOverlay({
    super.key,
    required this.emergency,
    required this.onCancel,
    this.cancelling = false,
  });

  final EmergencyRequest emergency;
  final VoidCallback? onCancel;
  final bool cancelling;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.emergency,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Buscando ambulancia disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Conectando con conductores cerca de ti…',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (emergency.facility != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_hospital_rounded, color: AppColors.primary),
                title: Text(
                  emergency.facility!.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  emergency.quotedCost != null
                      ? 'Costo est. \$${emergency.quotedCost!.toStringAsFixed(2)}'
                      : 'Calculando costo…',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: cancelling ? null : onCancel,
              icon: cancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancelar solicitud'),
              style: TextButton.styleFrom(foregroundColor: AppColors.emergency),
            ),
          ],
        ),
      ),
    );
  }
}
