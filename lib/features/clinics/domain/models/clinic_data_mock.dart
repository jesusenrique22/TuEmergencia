import 'clinic_models.dart';
import '../../../ambulance/domain/models/ambulance_models.dart';

class ClinicDataMock {
  static final List<AlliedClinic> clinics = [
    AlliedClinic(
      id: 'clinic-001',
      name: 'Hospital Universitario de Maracaibo',
      logoUrl:
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&q=80&w=100',
      location: Location(
        latitude: 10.6732671,
        longitude: -71.6284841,
        address: 'Avenida Cecilio Acosta, Juana de Ávila, Maracaibo',
      ),
      acceptedInsurances: ['Mercantil', 'Banesco', 'Mapfre', 'VITA Core'],
      hasEmergencyRoom: true,
    ),
    AlliedClinic(
      id: 'clinic-002',
      name: 'Hospital General del Sur',
      logoUrl:
          'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&q=80&w=100',
      location: Location(
        latitude: 10.5987593,
        longitude: -71.6254064,
        address: 'Distribuidor El Pesebre, Cristo de Aranza, Maracaibo',
      ),
      acceptedInsurances: ['Banesco', 'Mapfre', 'Seguros Mercantil'],
      hasEmergencyRoom: true,
    ),
    AlliedClinic(
      id: 'clinic-003',
      name: 'Policlínica Amado',
      logoUrl:
          'https://images.unsplash.com/photo-1538108176447-280586497dee?auto=format&fit=crop&q=80&w=100',
      location: Location(
        latitude: 10.6673525,
        longitude: -71.6074775,
        address: 'Calle 76, Olegario Villalobos, Maracaibo',
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
