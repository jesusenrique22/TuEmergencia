import '../../../core/network/api_client.dart';

final _client = ApiClient();

class ConsultationTemplateItem {
  final String id;
  final String label;
  final String description;
  final String? findingsHint;
  final String? diagnosisHint;
  final String? medicationsHint;
  final String? instructionsHint;
  final bool defaultNoMedication;
  final bool isCustom;

  const ConsultationTemplateItem({
    required this.id,
    required this.label,
    required this.description,
    this.findingsHint,
    this.diagnosisHint,
    this.medicationsHint,
    this.instructionsHint,
    this.defaultNoMedication = false,
    this.isCustom = false,
  });

  factory ConsultationTemplateItem.fromJson(Map<String, dynamic> j) {
    return ConsultationTemplateItem(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      label: j['label'] as String? ?? '',
      description: j['description'] as String? ?? '',
      findingsHint: j['findingsHint'] as String?,
      diagnosisHint: j['diagnosisHint'] as String?,
      medicationsHint: j['medicationsHint'] as String?,
      instructionsHint: j['instructionsHint'] as String?,
      defaultNoMedication: j['defaultNoMedication'] == true,
      isCustom: j['isCustom'] == true,
    );
  }

  Map<String, dynamic> toCreateBody() => {
        'label': label,
        'description': description,
        if (findingsHint != null && findingsHint!.isNotEmpty)
          'findingsHint': findingsHint,
        if (diagnosisHint != null && diagnosisHint!.isNotEmpty)
          'diagnosisHint': diagnosisHint,
        if (medicationsHint != null && medicationsHint!.isNotEmpty)
          'medicationsHint': medicationsHint,
        if (instructionsHint != null && instructionsHint!.isNotEmpty)
          'instructionsHint': instructionsHint,
        'defaultNoMedication': defaultNoMedication,
      };
}

class ConsultationTemplateApiService {
  Future<List<ConsultationTemplateItem>> listMyTemplates() async {
    final data =
        await _client.get('/api/doctors/consultation-templates', auth: true);
    final list = data as List<dynamic>;
    return list
        .map((e) =>
            ConsultationTemplateItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConsultationTemplateItem> createTemplate(
    ConsultationTemplateItem template,
  ) async {
    final data = await _client.post(
      '/api/doctors/consultation-templates',
      template.toCreateBody(),
      auth: true,
    );
    return ConsultationTemplateItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteTemplate(String id) async {
    await _client.delete('/api/doctors/consultation-templates/$id', auth: true);
  }
}
