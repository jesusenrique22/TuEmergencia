class PrescriptionExplanation {
  final bool isPrescription;
  final String? issue;
  final String? issueMessage;
  final String? patientExplanation;
  final List<ExplainedMedication> medications;

  PrescriptionExplanation({
    required this.isPrescription,
    this.issue,
    this.issueMessage,
    this.patientExplanation,
    required this.medications,
  });

  factory PrescriptionExplanation.fromJson(Map<String, dynamic> json) {
    return PrescriptionExplanation(
      isPrescription: json['isPrescription'] ?? false,
      issue: json['issue'],
      issueMessage: json['issueMessage'],
      patientExplanation: json['patientExplanation'],
      medications: (json['medications'] as List? ?? [])
          .map((m) => ExplainedMedication.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExplainedMedication {
  final String name;
  final String purpose;
  final String dosage;
  final List<String> sideEffects;
  final String precautions;

  ExplainedMedication({
    required this.name,
    required this.purpose,
    required this.dosage,
    required this.sideEffects,
    required this.precautions,
  });

  factory ExplainedMedication.fromJson(Map<String, dynamic> json) {
    return ExplainedMedication(
      name: json['name'] ?? '',
      purpose: json['purpose'] ?? '',
      dosage: json['dosage'] ?? '',
      sideEffects: List<String>.from(json['sideEffects'] ?? []),
      precautions: json['precautions'] ?? '',
    );
  }
}
