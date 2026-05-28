import 'package:flutter/material.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';

class AmbulanceDriverDashboard extends StatefulWidget {
  const AmbulanceDriverDashboard({super.key});

  @override
  State<AmbulanceDriverDashboard> createState() =>
      _AmbulanceDriverDashboardState();
}

class _AmbulanceDriverDashboardState extends State<AmbulanceDriverDashboard> {
  // Coordenadas simuladas
  static const Map<String, double> _driverLocation = {
    'lat': 10.4820,
    'lng': -66.9050,
  };
  static const Map<String, double> _pendingEmergency = {
    'lat': 10.4806,
    'lng': -66.9036,
  };

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel de Conductor'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          NotificationBadge(),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_hospital,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Ubicación Actual: ${_driverLocation['lat']}, ${_driverLocation['lng']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Emergencia en: ${_pendingEmergency['lat']}, ${_pendingEmergency['lng']}',
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.paramedicDashboard),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(250, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'INICIAR ATENCIÓN / TRIAGE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
