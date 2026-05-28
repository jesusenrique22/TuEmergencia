import 'laboratory_models.dart';

class LabDataMock {
  static final List<Laboratory> laboratories = [
    Laboratory(
      id: 'lab-001',
      name: 'BioLab Central',
      logoUrl:
          'https://images.unsplash.com/photo-1579152276508-2d29944ef71d?auto=format&fit=crop&q=80&w=100',
      offersHomeService: true,
    ),
  ];

  static final List<LabService> services = [
    // Servicios de BioLab
    LabService(
      id: 'ser-101',
      laboratoryId: 'lab-001',
      name: 'Perfil 20 (Rutina)',
      price: 25.00,
      requirements: 'Ayunas de 8 a 12 horas. No ingerir alcohol 24h antes.',
    ),
    LabService(
      id: 'ser-102',
      laboratoryId: 'lab-001',
      name: 'Prueba de Glucosa',
      price: 12.50,
      requirements: 'Ayunas estrictas de 8 horas.',
    ),
    LabService(
      id: 'ser-103',
      laboratoryId: 'lab-001',
      name: 'Perfil Lipídico',
      price: 18.00,
      requirements: 'Ayunas de 12 horas recomendadas.',
    ),
  ];

  static final List<LabResult> results = [
    LabResult(
      id: 'res-5001',
      patientId: 'pat-123',
      labServiceId: 'ser-101',
      documentUrl: 'https://www.example.com/results/perfil20.pdf',
      issueDate: DateTime.now().subtract(const Duration(days: 2)),
      status: LabResultStatus.delivered,
    ),
  ];
}
