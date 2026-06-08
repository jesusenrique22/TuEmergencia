import 'package:latlong2/latlong.dart';

/// Punto geográfico reutilizable en mapas, emergencias y catálogo.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});

  LatLng get latLng => LatLng(latitude, longitude);

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble() ??
          0,
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble() ??
          0,
    );
  }

  factory GeoPoint.optional(double? lat, double? lng) {
    return GeoPoint(latitude: lat ?? 0, longitude: lng ?? 0);
  }

  bool get isValid => latitude != 0 || longitude != 0;

  @override
  String toString() => '$latitude,$longitude';
}
