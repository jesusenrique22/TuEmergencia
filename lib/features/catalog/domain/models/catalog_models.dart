import '../../../../core/geo/geo_point.dart';
import '../../../../core/utils/json_helpers.dart';

class MedicalFacility {
  final String id;
  final String name;
  final String address;
  final String? city;
  final String? phone;
  final GeoPoint? location;
  final bool hasEmergencyRoom;

  const MedicalFacility({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.phone,
    this.location,
    this.hasEmergencyRoom = false,
  });

  factory MedicalFacility.fromJson(Map<String, dynamic> json) {
    final lat = JsonHelpers.doubleFromJson(json['latitude']);
    final lng = JsonHelpers.doubleFromJson(json['longitude']);
    return MedicalFacility(
      id: JsonHelpers.idFromJson(json),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      location: lat != null && lng != null
          ? GeoPoint(latitude: lat, longitude: lng)
          : null,
      hasEmergencyRoom: json['hasEmergencyRoom'] as bool? ?? false,
    );
  }
}

enum MapPoiType { clinic, laboratory, pharmacy, ambulance }

extension MapPoiTypeX on MapPoiType {
  String get apiValue {
    switch (this) {
      case MapPoiType.clinic:
        return 'CLINIC';
      case MapPoiType.laboratory:
        return 'LABORATORY';
      case MapPoiType.pharmacy:
        return 'PHARMACY';
      case MapPoiType.ambulance:
        return 'AMBULANCE';
    }
  }

  static MapPoiType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'LABORATORY':
        return MapPoiType.laboratory;
      case 'PHARMACY':
        return MapPoiType.pharmacy;
      case 'AMBULANCE':
        return MapPoiType.ambulance;
      default:
        return MapPoiType.clinic;
    }
  }
}

class MapPoi {
  final String id;
  final String name;
  final String address;
  final MapPoiType type;
  final GeoPoint location;
  final String? phone;
  final bool hasEmergencyRoom;
  final String? subtitle;
  final String? status;

  const MapPoi({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.location,
    this.phone,
    this.hasEmergencyRoom = false,
    this.subtitle,
    this.status,
  });

  factory MapPoi.fromJson(Map<String, dynamic> json, MapPoiType type) {
    final lat = JsonHelpers.doubleFromJson(json['latitude']) ?? 0;
    final lng = JsonHelpers.doubleFromJson(json['longitude']) ?? 0;
    final poiTypeRaw = json['poiType'] as String?;
    final resolvedType =
        poiTypeRaw != null ? MapPoiTypeX.fromApi(poiTypeRaw) : type;

    return MapPoi(
      id: JsonHelpers.idFromJson(json),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? json['facilityName'] as String? ?? '',
      type: resolvedType,
      location: GeoPoint(latitude: lat, longitude: lng),
      phone: json['phone'] as String? ?? json['driverPhone'] as String?,
      hasEmergencyRoom: json['hasEmergencyRoom'] as bool? ?? false,
      subtitle: json['driverName'] as String? ??
          json['callSign'] as String? ??
          json['plateNumber'] as String?,
      status: json['status'] as String?,
    );
  }
}
