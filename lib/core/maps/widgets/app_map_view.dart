import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../geo/geo_point.dart';
import '../map_config.dart';

/// Mapa reutilizable basado en flutter_map (Leaflet). Sin Google/Mapbox de pago.
class AppMapView extends StatelessWidget {
  final MapController? controller;
  final GeoPoint initialCenter;
  final double initialZoom;
  final List<Widget> layers;
  final List<Widget>? overlays;

  const AppMapView({
    super.key,
    this.controller,
    this.initialCenter = MapConfig.defaultCenter,
    this.initialZoom = MapConfig.defaultZoom,
    this.layers = const [],
    this.overlays,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: initialCenter.latLng,
            initialZoom: initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.osmTileUrl,
              userAgentPackageName: MapConfig.userAgentPackageName,
            ),
            ...layers,
          ],
        ),
        ...?overlays,
      ],
    );
  }
}

/// Marcador con icono Material — reutilizable en tracking y red médica.
class MapIconMarker {
  final LatLng point;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const MapIconMarker({
    required this.point,
    required this.icon,
    required this.color,
    this.size = 36,
    this.onTap,
  });

  Marker toMarker({double width = 44, double height = 44}) {
    return Marker(
      point: point,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
