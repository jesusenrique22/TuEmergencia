import 'clinic_models.dart';
import '../../../ambulance/domain/models/ambulance_models.dart';

class ClinicDataMock {
  static final List<AlliedClinic> clinics = [
    AlliedClinic(
      id: 'clinic-001',
      name: 'Clínica Méndez Gimón',
      logoUrl:
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&q=80&w=100',
      location: Location(
        latitude: 10.4850,
        longitude: -66.9100,
        address: 'Av. Andrés Bello, Caracas',
      ),
      acceptedInsurances: ['Mercantil', 'Banesco', 'Mapfre', 'VITA Core'],
      hasEmergencyRoom: true,
    ),
    AlliedClinic(
      id: 'clinic-002',
      name: 'Centro Médico Docente La Trinidad',
      logoUrl:
          'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&q=80&w=100',
      location: Location(
        latitude: 10.4350,
        longitude: -66.8500,
        address: 'La Trinidad, Caracas',
      ),
      acceptedInsurances: ['Banesco', 'Mapfre', 'Seguros Caracas'],
      hasEmergencyRoom: true,
    ),
    AlliedClinic(
      id: 'clinic-003',
      name: 'Instituto Médico La Floresta',
      logoUrl:
          'https://images.unsplash.com/photo-1538108176447-280586497dee?auto=format&fit=crop&q=80&w=100',
      location: Location(
        latitude: 10.4950,
        longitude: -66.8400,
        address: 'La Floresta, Caracas',
      ),
      acceptedInsurances: ['Mercantil', 'VITA Premium'],
      hasEmergencyRoom:
          false, // Especializada en consultas y cirugías programadas
    ),
  ];

  static final List<IncomingAdmission> pendingAdmissions = [
    IncomingAdmission(
      id: 'adm-1001',
      patientId: 'pat-123',
      ambulanceRequestId: 'req-9901',
      status: AdmissionStatus.enCamino,
      estimatedArrival: DateTime.now().add(const Duration(minutes: 15)),
    ),
  ];
}
