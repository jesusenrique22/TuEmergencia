import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/geo/geo_math.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_poi_style.dart';
import '../../../../core/maps/widgets/app_map_view.dart';
import '../../../emergency/domain/models/emergency_models.dart';

/// Mapa para personal de ambulancia: marca el punto donde se solicitó la emergencia.
class AmbulanceEmergencyMap extends StatelessWidget {
  const AmbulanceEmergencyMap({super.key, required this.request});

  final EmergencyRequest request;

  @override
  Widget build(BuildContext context) {
    final origin = request.origin;
    final ambulance = request.ambulanceLocation;
    final center = ambulance != null
        ? GeoMath.midpoint(origin, ambulance)
        : origin;

    final originStyle = MapPoiStyle.forType('PATIENT');
    final ambulanceStyle = MapPoiStyle.forType('AMBULANCE');

    final markers = <Marker>[
      MapIconMarker(
        point: origin.latLng,
        icon: originStyle.icon,
        color: originStyle.color,
        size: 40,
      ).toMarker(width: 50, height: 50),
    ];

    if (ambulance != null) {
      markers.add(
        MapIconMarker(
          point: ambulance.latLng,
          icon: ambulanceStyle.icon,
          color: ambulanceStyle.color,
          size: 36,
        ).toMarker(),
      );
    }

    return AppMapView(
      initialCenter: center,
      initialZoom: MapConfig.trackingZoom,
      layers: [MarkerLayer(markers: markers)],
      overlays: [
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(originStyle.icon, color: originStyle.color, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ubicación de la solicitud',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (ambulance != null) ...[
                    Icon(ambulanceStyle.icon, color: ambulanceStyle.color, size: 20),
                    const SizedBox(width: 4),
                    const Text('Unidad', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
