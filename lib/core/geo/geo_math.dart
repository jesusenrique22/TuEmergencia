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

  static int estimateEtaMinutes(double distanceKm, {double? avgSpeedKmh}) {
    final speed = avgSpeedKmh ?? (distanceKm <= 20 ? 45.0 : 35.0);
    return math.max(3, (distanceKm / speed * 60).round());
  }

  /// Rumbo en grados (0 = norte, 90 = este) entre dos puntos.
  static double bearingDegrees(GeoPoint from, GeoPoint to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  static String formatEta(int? minutes) {
    if (minutes == null || minutes <= 0) return '—';
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }
}
