class ConsultationReport {
  final String id;
  final String appointmentId;
  final String findings;
  final String diagnosis;
  final String medications;
  final String instructions;
  final bool noMedication;
  final List<String> attachmentUrls;
  final String? templateId;
  final bool patientAcknowledged;
  final DateTime? patientAcknowledgedAt;
  final DateTime createdAt;

  const ConsultationReport({
    required this.id,
    required this.appointmentId,
    required this.findings,
    required this.diagnosis,
    required this.medications,
    required this.instructions,
    this.noMedication = false,
    this.attachmentUrls = const [],
    this.templateId,
    this.patientAcknowledged = false,
    this.patientAcknowledgedAt,
    required this.createdAt,
  });

  factory ConsultationReport.fromJson(Map<String, dynamic> j) {
    final urls = j['attachmentUrls'] as List<dynamic>? ?? [];
    return ConsultationReport(
      id: j['_id'] as String? ?? j['id'] as String? ?? '',
      appointmentId: j['appointmentId'] as String? ?? '',
      findings: j['findings'] as String? ?? '',
      diagnosis: j['diagnosis'] as String? ?? '',
      medications: j['medications'] as String? ?? '',
      instructions: j['instructions'] as String? ?? '',
      noMedication: j['noMedication'] == true,
      attachmentUrls: urls.map((e) => e.toString()).toList(),
      templateId: j['templateId'] as String?,
      patientAcknowledged: j['patientAcknowledged'] == true,
      patientAcknowledgedAt: j['patientAcknowledgedAt'] != null
          ? DateTime.tryParse(j['patientAcknowledgedAt'] as String)
          : null,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toApiBody() => {
        'findings': findings,
        'diagnosis': diagnosis,
        'medications': medications,
        'instructions': instructions,
        'noMedication': noMedication,
        if (templateId != null) 'templateId': templateId,
      };
}
