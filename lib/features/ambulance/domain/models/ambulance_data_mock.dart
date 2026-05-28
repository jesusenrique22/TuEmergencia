import 'ambulance_models.dart';

class AmbulanceDataMock {
  static final List<AmbulanceCompany> companies = [
    AmbulanceCompany(
      id: 'amb-001',
      name: 'Rescate Médico 24/7',
      logoUrl:
          'https://images.unsplash.com/photo-1587854692152-cbe660dbbb88?auto=format&fit=crop&q=80&w=100',
      baseRate: 45.00,
    ),
    AmbulanceCompany(
      id: 'amb-002',
      name: 'Vital Response',
      logoUrl:
          'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&q=80&w=100',
      baseRate: 60.00,
    ),
  ];

  static final List<AmbulanceRequest> activeRequests = [
    AmbulanceRequest(
      id: 'req-9901',
      patientId: 'pat-123',
      origin: const Location(
        latitude: 10.4806,
        longitude: -66.9036,
        address: 'Plaza Venezuela',
      ),
      destinationClinicId: 'clinic-001',
      quotedCost: 52.50,
      companyId: 'amb-001',
      initialSymptoms: 'Dificultad respiratoria y opresión torácica.',
      status: AmbulanceStatus.dispatched,
    ),
  ];

  static final List<TransitMedicalLog> historyLogs = [
    TransitMedicalLog(
      id: 'log-101',
      requestId: 'req-9901',
      symptoms: ['Dificultad respiratoria', 'Dolor en el pecho'],
      vitals: VitalSigns(
        bloodPressure: '135/85',
        heartRate: 88,
        saturation: 94,
        temperature: 37.2,
      ),
      clinicalNotes:
          'Paciente estable pero requiere oxígeno suplementario durante el trayecto.',
    ),
  ];
}
