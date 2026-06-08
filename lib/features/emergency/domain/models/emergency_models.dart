import '../../../../core/geo/geo_point.dart';
import '../../../../core/utils/json_helpers.dart';

enum EmergencyStatus {
  requested,
  dispatched,
  onScene,
  patientOnboard,
  enRoute,
  arrived,
  completed,
  cancelled;

  static EmergencyStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'DISPATCHED':
        return EmergencyStatus.dispatched;
      case 'ON_SCENE':
        return EmergencyStatus.onScene;
      case 'PATIENT_ONBOARD':
        return EmergencyStatus.patientOnboard;
      case 'EN_ROUTE':
        return EmergencyStatus.enRoute;
      case 'ARRIVED':
        return EmergencyStatus.arrived;
      case 'COMPLETED':
        return EmergencyStatus.completed;
      case 'CANCELLED':
        return EmergencyStatus.cancelled;
      default:
        return EmergencyStatus.requested;
    }
  }

  String get apiValue => name == 'onScene'
      ? 'ON_SCENE'
      : name == 'patientOnboard'
          ? 'PATIENT_ONBOARD'
          : name == 'enRoute'
              ? 'EN_ROUTE'
              : name.toUpperCase();

  String get label {
    switch (this) {
      case EmergencyStatus.dispatched:
        return 'Ambulancia en camino';
      case EmergencyStatus.onScene:
        return 'Ambulancia en el lugar';
      case EmergencyStatus.patientOnboard:
        return 'Paciente a bordo';
      case EmergencyStatus.enRoute:
        return 'Traslado a clínica';
      case EmergencyStatus.arrived:
        return 'Llegó a urgencias';
      case EmergencyStatus.completed:
        return 'Atención completada';
      case EmergencyStatus.cancelled:
        return 'Solicitud cancelada';
      case EmergencyStatus.requested:
        return 'Solicitud recibida';
    }
  }

  bool get isTerminal =>
      this == EmergencyStatus.completed || this == EmergencyStatus.cancelled;
}

class EmergencyPerson {
  final String id;
  final String name;
  final String? phone;
  final String? profilePic;

  const EmergencyPerson({
    required this.id,
    required this.name,
    this.phone,
    this.profilePic,
  });

  factory EmergencyPerson.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EmergencyPerson(id: '', name: '');
    return EmergencyPerson(
      id: JsonHelpers.idFromJson(json),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      profilePic: json['profilePic'] as String?,
    );
  }
}

class EmergencyAmbulance {
  final String id;
  final String plateNumber;
  final String? callSign;
  final EmergencyPerson? driver;

  const EmergencyAmbulance({
    required this.id,
    required this.plateNumber,
    this.callSign,
    this.driver,
  });

  factory EmergencyAmbulance.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const EmergencyAmbulance(id: '', plateNumber: '');
    }
    return EmergencyAmbulance(
      id: JsonHelpers.idFromJson(json),
      plateNumber: json['plateNumber'] as String? ?? '',
      callSign: json['callSign'] as String?,
      driver: EmergencyPerson.fromJson(
        json['driver'] as Map<String, dynamic>?,
      ),
    );
  }

  String get displayName => callSign ?? plateNumber;
}

class EmergencyFacilitySummary {
  final String id;
  final String name;
  final String address;
  final GeoPoint? location;
  final bool hasEmergencyRoom;

  const EmergencyFacilitySummary({
    required this.id,
    required this.name,
    required this.address,
    this.location,
    this.hasEmergencyRoom = false,
  });

  factory EmergencyFacilitySummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const EmergencyFacilitySummary(id: '', name: '', address: '');
    }
    final lat = JsonHelpers.doubleFromJson(json['latitude']);
    final lng = JsonHelpers.doubleFromJson(json['longitude']);
    return EmergencyFacilitySummary(
      id: JsonHelpers.idFromJson(json),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      location: lat != null && lng != null
          ? GeoPoint(latitude: lat, longitude: lng)
          : null,
      hasEmergencyRoom: json['hasEmergencyRoom'] as bool? ?? false,
    );
  }
}

class EmergencyRequest {
  final String id;
  final String patientId;
  final String facilityId;
  final EmergencyFacilitySummary? facility;
  final EmergencyAmbulance? ambulance;
  final GeoPoint origin;
  final String? originAddress;
  final String? symptoms;
  final int? painLevel;
  final String? medicalHistory;
  final EmergencyStatus status;
  final double? quotedCost;
  final int? etaMinutes;
  final GeoPoint? ambulanceLocation;
  final DateTime requestedAt;

  const EmergencyRequest({
    required this.id,
    required this.patientId,
    required this.facilityId,
    this.facility,
    this.ambulance,
    required this.origin,
    this.originAddress,
    this.symptoms,
    this.painLevel,
    this.medicalHistory,
    required this.status,
    this.quotedCost,
    this.etaMinutes,
    this.ambulanceLocation,
    required this.requestedAt,
  });

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      id: JsonHelpers.idFromJson(json),
      patientId: json['patientId'] as String? ?? '',
      facilityId: json['facilityId'] as String? ?? '',
      facility: EmergencyFacilitySummary.fromJson(
        json['facility'] as Map<String, dynamic>?,
      ),
      ambulance: EmergencyAmbulance.fromJson(
        json['ambulance'] as Map<String, dynamic>?,
      ),
      origin: GeoPoint(
        latitude: JsonHelpers.doubleFromJson(json['originLat']) ?? 0,
        longitude: JsonHelpers.doubleFromJson(json['originLng']) ?? 0,
      ),
      originAddress: json['originAddress'] as String?,
      symptoms: json['symptoms'] as String?,
      painLevel: json['painLevel'] as int?,
      medicalHistory: json['medicalHistory'] as String?,
      status: EmergencyStatus.fromApi(json['status'] as String? ?? 'REQUESTED'),
      quotedCost: JsonHelpers.doubleFromJson(json['quotedCost']),
      etaMinutes: json['etaMinutes'] as int?,
      ambulanceLocation: _optionalPoint(json['ambulanceLat'], json['ambulanceLng']),
      requestedAt: JsonHelpers.dateFromJson(json['requestedAt']),
    );
  }

  static GeoPoint? _optionalPoint(dynamic lat, dynamic lng) {
    final la = JsonHelpers.doubleFromJson(lat);
    final lo = JsonHelpers.doubleFromJson(lng);
    if (la == null || lo == null) return null;
    return GeoPoint(latitude: la, longitude: lo);
  }

  EmergencyRequest copyWith({
    EmergencyStatus? status,
    GeoPoint? ambulanceLocation,
    int? etaMinutes,
  }) {
    return EmergencyRequest(
      id: id,
      patientId: patientId,
      facilityId: facilityId,
      facility: facility,
      ambulance: ambulance,
      origin: origin,
      originAddress: originAddress,
      symptoms: symptoms,
      painLevel: painLevel,
      medicalHistory: medicalHistory,
      status: status ?? this.status,
      quotedCost: quotedCost,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      ambulanceLocation: ambulanceLocation ?? this.ambulanceLocation,
      requestedAt: requestedAt,
    );
  }
}

class EmergencyLocationUpdate {
  final String emergencyRequestId;
  final GeoPoint location;
  final int? etaMinutes;

  const EmergencyLocationUpdate({
    required this.emergencyRequestId,
    required this.location,
    this.etaMinutes,
  });

  factory EmergencyLocationUpdate.fromPayload(Map<String, dynamic> json) {
    return EmergencyLocationUpdate(
      emergencyRequestId: json['emergencyRequestId']?.toString() ?? '',
      location: GeoPoint(
        latitude: JsonHelpers.doubleFromJson(json['latitude']) ?? 0,
        longitude: JsonHelpers.doubleFromJson(json['longitude']) ?? 0,
      ),
      etaMinutes: json['etaMinutes'] as int?,
    );
  }
}

class CreateEmergencyParams {
  final String facilityId;
  final GeoPoint origin;
  final String? originAddress;
  final String? symptoms;
  final int? painLevel;
  final String? medicalHistory;

  const CreateEmergencyParams({
    required this.facilityId,
    required this.origin,
    this.originAddress,
    this.symptoms,
    this.painLevel,
    this.medicalHistory,
  });
}
