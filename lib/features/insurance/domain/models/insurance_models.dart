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
  final HealthInsurance? insurance;

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
    this.insurance,
  });

  factory MedicalInvoice.fromJson(Map<String, dynamic> json) {
    return MedicalInvoice(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      patientId: json['patientId'] as String,
      insuranceId: json['insuranceId'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      coveredAmount: (json['coveredAmount'] as num).toDouble(),
      copayAmount: (json['copayAmount'] as num).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['status'] as String).toLowerCase(),
        orElse: () => InvoiceStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      insurance: json['insurance'] != null
          ? HealthInsurance.fromJson(json['insurance'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'patientId': patientId,
        'insuranceId': insuranceId,
        'subtotal': subtotal,
        'coveredAmount': coveredAmount,
        'copayAmount': copayAmount,
        'status': status.name.toUpperCase(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class HealthInsurance {
  final String id;
  final String name;
  final String logoUrl;
  final String? clinicId; // Nullable: Si es nulo, es de uso global. Si tiene ID, es exclusivo de esa clínica.
  final List<InsuranceCoverage>? coverages;

  HealthInsurance({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.clinicId,
    this.coverages,
  });

  bool get isGlobal => clinicId == null;

  factory HealthInsurance.fromJson(Map<String, dynamic> json) {
    return HealthInsurance(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String,
      clinicId: json['clinicId'] as String?,
      coverages: json['coverages'] != null
          ? (json['coverages'] as List)
              .map((c) => InsuranceCoverage.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logoUrl': logoUrl,
        'clinicId': clinicId,
        'coverages': coverages?.map((c) => c.toJson()).toList(),
      };
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

  factory InsuranceCoverage.fromJson(Map<String, dynamic> json) {
    return InsuranceCoverage(
      id: json['id'] as String,
      insuranceId: json['insuranceId'] as String,
      maxLimit: (json['maxLimit'] as num).toDouble(),
      pharmacyPercentage: (json['pharmacyPercentage'] as num).toDouble(),
      ambulancePercentage: (json['ambulancePercentage'] as num).toDouble(),
      laboratoryPercentage: (json['laboratoryPercentage'] as num).toDouble(),
      erConsultationPercentage: (json['erConsultationPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'insuranceId': insuranceId,
        'maxLimit': maxLimit,
        'pharmacyPercentage': pharmacyPercentage,
        'ambulancePercentage': ambulancePercentage,
        'laboratoryPercentage': laboratoryPercentage,
        'erConsultationPercentage': erConsultationPercentage,
      };
}

class PatientPolicy {
  final String id;
  final String patientId;
  final String insuranceId;
  final String policyNumber;
  final PolicyStatus status;
  final HealthInsurance? insurance;

  PatientPolicy({
    required this.id,
    required this.patientId,
    required this.insuranceId,
    required this.policyNumber,
    required this.status,
    this.insurance,
  });

  factory PatientPolicy.fromJson(Map<String, dynamic> json) {
    return PatientPolicy(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      insuranceId: json['insuranceId'] as String,
      policyNumber: json['policyNumber'] as String,
      status: PolicyStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['status'] as String).toLowerCase(),
        orElse: () => PolicyStatus.active,
      ),
      insurance: json['insurance'] != null
          ? HealthInsurance.fromJson(json['insurance'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'insuranceId': insuranceId,
        'policyNumber': policyNumber,
        'status': status.name.toUpperCase(),
      };
}
