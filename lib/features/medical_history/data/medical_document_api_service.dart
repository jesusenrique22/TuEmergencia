import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../domain/models/patient_medical_document.dart';

final _client = ApiClient();

class MedicalDocumentApiService {
  Future<List<PatientMedicalDocument>> listMyDocuments() async {
    final data = await _client.get('/api/patients/medical-documents');
    return _parseList(data);
  }

  Future<List<PatientMedicalDocument>> listPatientDocuments(
    String patientId,
  ) async {
    final data = await _client.get(
      '/api/doctors/patients/$patientId/medical-documents',
    );
    return _parseList(data);
  }

  Future<PatientMedicalDocument> upload({
    required MedicalDocumentCategory category,
    required String title,
    String? notes,
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final body = {
      'category': category.apiValue,
      'title': title,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'fileName': fileName,
      'mimeType': mimeType,
      'dataBase64': base64Encode(bytes),
    };
    final data = await _client.post(
      '/api/patients/medical-documents',
      body,
      auth: true,
    );
    return PatientMedicalDocument.fromJson(data);
  }

  Future<void> deleteMyDocument(String id) async {
    await _client.delete('/api/patients/medical-documents/$id');
  }

  List<PatientMedicalDocument> _parseList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => PatientMedicalDocument.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
