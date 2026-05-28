enum PolicyStatus { active, inactive, suspended }

enum InvoiceStatus { draft, pending, paid, denied }

class MedicalInvoice {
  final String id;
  final String requestId;
  final String patientId;
  final String insuranceId;
  final double subtotal;
  final double coveredAmount;
  final double copayAmount;
  final InvoiceStatus status;
  final DateTime createdAt;

  MedicalInvoice({
    required this.id,
    required this.requestId,
    required this.patientId,
    required this.insuranceId,
    required this.subtotal,
    required this.coveredAmount,
    required this.copayAmount,
    required this.status,
    required this.createdAt,
  });
}

class HealthInsurance {
  final String id;
  final String name;
  final String logoUrl;
  final String?
  clinicId; // Nullable: Si es nulo, es de uso global. Si tiene ID, es exclusivo de esa clínica.

  HealthInsurance({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.clinicId,
  });

  bool get isGlobal => clinicId == null;
}

class InsuranceCoverage {
  final String id;
  final String insuranceId;
  final double maxLimit; // Monto máximo de cobertura anual o por evento

  // Porcentajes de cobertura (0.0 a 1.0)
  final double pharmacyPercentage;
  final double ambulancePercentage;
  final double laboratoryPercentage;
  final double erConsultationPercentage;

  InsuranceCoverage({
    required this.id,
    required this.insuranceId,
    required this.maxLimit,
    required this.pharmacyPercentage,
    required this.ambulancePercentage,
    required this.laboratoryPercentage,
    required this.erConsultationPercentage,
  });
}

class PatientPolicy {
  final String id;
  final String patientId;
  final String insuranceId;
  final String policyNumber;
  final PolicyStatus status;

  PatientPolicy({
    required this.id,
    required this.patientId,
    required this.insuranceId,
    required this.policyNumber,
    required this.status,
  });
}
