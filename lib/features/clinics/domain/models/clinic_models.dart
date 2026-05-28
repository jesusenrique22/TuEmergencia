import '../../../ambulance/domain/models/ambulance_models.dart';

enum AdmissionStatus { enCamino, ingresado }

class AlliedClinic {
  final String id;
  final String name;
  final String logoUrl;
  final Location location;
  final List<String> acceptedInsurances;
  final bool hasEmergencyRoom;

  AlliedClinic({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.location,
    required this.acceptedInsurances,
    required this.hasEmergencyRoom,
  });
}

class IncomingAdmission {
  final String id;
  final String patientId;
  final String?
  ambulanceRequestId; // Opcional si el paciente llega por sus medios
  final AdmissionStatus status;
  final DateTime estimatedArrival;

  IncomingAdmission({
    required this.id,
    required this.patientId,
    this.ambulanceRequestId,
    required this.status,
    required this.estimatedArrival,
  });
}
