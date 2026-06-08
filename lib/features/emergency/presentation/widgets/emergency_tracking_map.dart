import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/geo/geo_math.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_poi_style.dart';
import '../../../../core/maps/widgets/app_map_view.dart';
import '../../domain/models/emergency_models.dart';

/// Mapa de tracking reutilizable (paciente + ambulancia).
class EmergencyTrackingMap extends StatelessWidget {
  final MapController controller;
  final EmergencyRequest request;
  final VoidCallback? onMapReady;

  const EmergencyTrackingMap({
    super.key,
    required this.controller,
    required this.request,
    this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    final patient = request.origin;
    final ambulance = request.ambulanceLocation ?? patient;
    final center = GeoMath.midpoint(patient, ambulance);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.move(center.latLng, MapConfig.trackingZoom);
      onMapReady?.call();
    });

    final patientStyle = MapPoiStyle.forType('PATIENT');
    final ambulanceStyle = MapPoiStyle.forType('AMBULANCE');

    return AppMapView(
      controller: controller,
      initialCenter: patient,
      initialZoom: MapConfig.trackingZoom,
      layers: [
        MarkerLayer(
          markers: [
            MapIconMarker(
              point: patient.latLng,
              icon: patientStyle.icon,
              color: patientStyle.color,
            ).toMarker(),
            MapIconMarker(
              point: ambulance.latLng,
              icon: ambulanceStyle.icon,
              color: ambulanceStyle.color,
              size: 40,
            ).toMarker(width: 50, height: 50),
          ],
        ),
      ],
    );
  }
}
