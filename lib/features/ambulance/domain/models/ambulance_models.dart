enum AmbulanceStatus { quoting, dispatched, patientOnboard, completed }

class Location {
  final double latitude;
  final double longitude;
  final String address;

  const Location({
    required this.latitude,
    required this.longitude,
    this.address = '',
  });

  Map<String, double> toMap() => {'lat': latitude, 'lng': longitude};
}

class AmbulanceCompany {
  final String id;
  final String name;
  final String logoUrl;
  final double baseRate; // Tarifa mínima por salida

  AmbulanceCompany({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.baseRate,
  });
}

class AmbulanceRequest {
  final String id;
  final String patientId;
  final Location origin;
  final String destinationClinicId; // Ahora apunta a una clínica de la red
  final double quotedCost;
  final String companyId;
  final String? initialSymptoms;
  final int? painLevel; // Escala 1-10
  final String? backgroundHistory; // Hipertensión, Diabetes, etc.
  AmbulanceStatus status;
  final DateTime requestedAt;

  AmbulanceRequest({
    required this.id,
    required this.patientId,
    required this.origin,
    required this.destinationClinicId,
    required this.quotedCost,
    required this.companyId,
    this.initialSymptoms,
    this.painLevel,
    this.backgroundHistory,
    this.status = AmbulanceStatus.quoting,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();
}

class VitalSigns {
  final String bloodPressure; // Ej: 120/80
  final int heartRate; // Ej: 75 bpm
  final int saturation; // Ej: 98%
  final double temperature; // Ej: 37.5

  VitalSigns({
    required this.bloodPressure,
    required this.heartRate,
    required this.saturation,
    required this.temperature,
  });
}

class TransitMedicalLog {
  final String id;
  final String requestId;
  final List<String> symptoms;
  final VitalSigns vitals;
  final String clinicalNotes;
  final DateTime loggedAt;

  TransitMedicalLog({
    required this.id,
    required this.requestId,
    required this.symptoms,
    required this.vitals,
    required this.clinicalNotes,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();
}
