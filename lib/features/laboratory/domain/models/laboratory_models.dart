enum LabResultStatus { pending, delivered }

class Laboratory {
  final String id;
  final String name;
  final String logoUrl;
  final bool offersHomeService;

  Laboratory({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.offersHomeService,
  });
}

class LabService {
  final String id;
  final String laboratoryId;
  final String name;
  final double price;
  final String requirements; // Ej: 'Ayunas de 8 horas'

  LabService({
    required this.id,
    required this.laboratoryId,
    required this.name,
    required this.price,
    required this.requirements,
  });
}

class LabResult {
  final String id;
  final String patientId;
  final String labServiceId;
  final String documentUrl; // Enlace al PDF
  final DateTime issueDate;
  final LabResultStatus status;

  LabResult({
    required this.id,
    required this.patientId,
    required this.labServiceId,
    required this.documentUrl,
    required this.issueDate,
    this.status = LabResultStatus.pending,
  });
}
