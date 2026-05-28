enum ImagingResultStatus { pending, delivered }

class RadiologyCenter {
  final String id;
  final String name;
  final String logoUrl;
  final bool hasMRI;

  RadiologyCenter({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.hasMRI,
  });
}

class ImagingService {
  final String id;
  final String centerId;
  final String name;
  final double price;
  final String preparation;

  ImagingService({
    required this.id,
    required this.centerId,
    required this.name,
    required this.price,
    required this.preparation,
  });
}

class ImagingResult {
  final String id;
  final String patientId;
  final String serviceId;
  final String documentUrl;
  final DateTime issueDate;
  final ImagingResultStatus status;

  ImagingResult({
    required this.id,
    required this.patientId,
    required this.serviceId,
    required this.documentUrl,
    required this.issueDate,
    this.status = ImagingResultStatus.pending,
  });
}
