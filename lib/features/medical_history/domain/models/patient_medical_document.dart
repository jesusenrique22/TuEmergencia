enum MedicalDocumentCategory {
  lab,
  radiology,
  prescription,
  other;

  String get apiValue => switch (this) {
        MedicalDocumentCategory.lab => 'LAB',
        MedicalDocumentCategory.radiology => 'RADIOLOGY',
        MedicalDocumentCategory.prescription => 'PRESCRIPTION',
        MedicalDocumentCategory.other => 'OTHER',
      };

  String get label => switch (this) {
        MedicalDocumentCategory.lab => 'Laboratorio',
        MedicalDocumentCategory.radiology => 'Radiografía / imagen',
        MedicalDocumentCategory.prescription => 'Receta / informe',
        MedicalDocumentCategory.other => 'Otro',
      };

  static MedicalDocumentCategory fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'LAB':
        return MedicalDocumentCategory.lab;
      case 'RADIOLOGY':
        return MedicalDocumentCategory.radiology;
      case 'PRESCRIPTION':
        return MedicalDocumentCategory.prescription;
      default:
        return MedicalDocumentCategory.other;
    }
  }
}

class PatientMedicalDocument {
  final String id;
  final MedicalDocumentCategory category;
  final String title;
  final String? notes;
  final String fileName;
  final String mimeType;
  final String fileUrl;
  final int fileSize;
  final DateTime createdAt;

  const PatientMedicalDocument({
    required this.id,
    required this.category,
    required this.title,
    this.notes,
    required this.fileName,
    required this.mimeType,
    required this.fileUrl,
    required this.fileSize,
    required this.createdAt,
  });

  bool get isImage =>
      mimeType.startsWith('image/') ||
      fileName.toLowerCase().endsWith('.png') ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.webp') ||
      fileName.toLowerCase().endsWith('.gif');

  bool get isPdf =>
      mimeType == 'application/pdf' ||
      fileName.toLowerCase().endsWith('.pdf');

  factory PatientMedicalDocument.fromJson(Map<String, dynamic> j) {
    return PatientMedicalDocument(
      id: j['_id'] as String? ?? j['id'] as String? ?? '',
      category: MedicalDocumentCategory.fromApi(j['category'] as String?),
      title: j['title'] as String? ?? '',
      notes: j['notes'] as String?,
      fileName: j['fileName'] as String? ?? '',
      mimeType: j['mimeType'] as String? ?? 'application/octet-stream',
      fileUrl: j['fileUrl'] as String? ?? '',
      fileSize: (j['fileSize'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
