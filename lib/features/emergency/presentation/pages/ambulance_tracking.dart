import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_avatar.dart';

class AmbulanceTracking extends StatefulWidget {
  final String emergencyId;
  const AmbulanceTracking({super.key, this.emergencyId = 'mock_id'});

  @override
  State<AmbulanceTracking> createState() => _AmbulanceTrackingState();
}

class _AmbulanceTrackingState extends State<AmbulanceTracking> {
  final MapController _mapController = MapController();

  static const LatLng _patientLocation = LatLng(10.4806, -66.9036);
  LatLng ambulancePos = const LatLng(10.4820, -66.9050);
  String status = 'En ruta';
  int eta = 5;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _patientLocation,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.smartmedic',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _patientLocation,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                Marker(
                  point: ambulancePos,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.medical_services,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 40,
          left: 20,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => AppNavigation.safeBack(context),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildBottomSheet(context, status, eta),
        ),
      ],
    );
  }

  Widget _buildBottomSheet(BuildContext context, String status, int eta) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Llegada en $eta minutos',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SafeAvatar(
                radius: 28,
                imageUrl: 'https://i.pravatar.cc/150?u=carlos',
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carlos Ruiz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Expanded(
                          child: Text(
                            ' 4.9 • Unidad VITA-04',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.primary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Conectando llamada con la unidad VITA-04',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
              ),
              onPressed: () => AppNavigation.safeBack(context),
              child: const Text('Cancelar Solicitud'),
            ),
          ),
        ],
      ),
    );
  }
}
