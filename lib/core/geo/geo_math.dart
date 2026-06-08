import 'dart:math' as math;

import 'geo_point.dart';

/// Cálculos geográficos puros (sin dependencias de UI ni API).
class GeoMath {
  GeoMath._();

  static const earthRadiusKm = 6371.0;

  static double distanceKm(GeoPoint a, GeoPoint b) {
    return haversineKm(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    double toRad(double d) => d * math.pi / 180;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static GeoPoint midpoint(GeoPoint a, GeoPoint b) {
    return GeoPoint(
      latitude: (a.latitude + b.latitude) / 2,
      longitude: (a.longitude + b.longitude) / 2,
    );
  }

  static int estimateEtaMinutes(double distanceKm, {double avgSpeedKmh = 30}) {
    return math.max(3, (distanceKm / avgSpeedKmh * 60).round());
  }
}
