import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../map_poi_style.dart';

/// Marcador visual con icono sobre círculo de color — reutilizable en todo el mapa.
class MapPoiMarker {
  final LatLng point;
  final MapPoiStyle style;
  final VoidCallback? onTap;
  final bool pulsing;

  const MapPoiMarker({
    required this.point,
    required this.style,
    this.onTap,
    this.pulsing = false,
  });

  Marker toMarker({double size = 46}) {
    return Marker(
      point: point,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (pulsing)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.color.withValues(alpha: 0.18),
                ),
              ),
            Container(
              width: size * 0.78,
              height: size * 0.78,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: style.color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: style.color.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                style.icon,
                color: style.color,
                size: size * 0.42,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
