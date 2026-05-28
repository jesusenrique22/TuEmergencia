import '../../../core/network/api_client.dart';
import '../../patient_profile/domain/models/weight_control_record.dart';

final _client = ApiClient();

class MedicalHistoryEntry {
  final String id;
  final DateTime date;
  final String doctorName;
  final String title;
  final String description;
  final String? diagnosis;
  final String? treatment;

  const MedicalHistoryEntry({
    required this.id,
    required this.date,
    required this.doctorName,
    required this.title,
    required this.description,
    this.diagnosis,
    this.treatment,
  });

  factory MedicalHistoryEntry.fromJson(Map<String, dynamic> j) {
    final doctor = j['doctorId'];
    final doctorName = doctor is Map<String, dynamic>
        ? doctor['name'] as String? ?? 'Médico'
        : 'Médico';
    return MedicalHistoryEntry(
      id: j['_id'] as String? ?? '',
      date: DateTime.parse(j['date'] as String),
      doctorName: doctorName,
      title: j['title'] as String? ?? '',
      description: j['description'] as String? ?? '',
      diagnosis: j['diagnosis'] as String?,
      treatment: j['treatment'] as String?,
    );
  }
}

class PatientMedicalRecord {
  final String? bloodType;
  final String? allergies;
  final String? chronicConditions;
  final String? currentMedications;
  final String? surgeries;
  final List<MedicalHistoryEntry> entries;

  const PatientMedicalRecord({
    this.bloodType,
    this.allergies,
    this.chronicConditions,
    this.currentMedications,
    this.surgeries,
    required this.entries,
  });

  factory PatientMedicalRecord.fromJson(Map<String, dynamic> j) {
    final rawEntries = j['entries'] as List<dynamic>? ?? [];
    return PatientMedicalRecord(
      bloodType: j['bloodType'] as String?,
      allergies: j['allergies'] as String?,
      chronicConditions: j['chronicConditions'] as String?,
      currentMedications: j['currentMedications'] as String?,
      surgeries: j['surgeries'] as String?,
      entries: rawEntries
          .map((e) => MedicalHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }
}

class DoctorPatientItem {
  final String userId;
  final String name;
  final String? profilePic;
  final String? bloodType;
  final String? chronicConditions;

  const DoctorPatientItem({
    required this.userId,
    required this.name,
    this.profilePic,
    this.bloodType,
    this.chronicConditions,
  });

  factory DoctorPatientItem.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    final profile = j['profile'] as Map<String, dynamic>?;
    return DoctorPatientItem(
      userId: user['_id']?.toString() ?? '',
      name: user['name'] as String? ?? '',
      profilePic: user['profilePic'] as String?,
      bloodType: profile?['bloodType'] as String?,
      chronicConditions: profile?['chronicConditions'] as String?,
    );
  }
}

class MedicalHistoryApiService {
  Future<PatientMedicalRecord> getMyHistory() async {
    final data = await _client.get('/api/patients/medical-history');
    return PatientMedicalRecord.fromJson(data as Map<String, dynamic>);
  }

  Future<List<DoctorPatientItem>> getMyPatients() async {
    final data = await _client.get('/api/doctors/patients');
    final list = data as List<dynamic>;
    return list
        .map((e) => DoctorPatientItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<
      ({
        PatientMedicalRecord record,
        String? patientName,
        String? avatar,
        List<WeightControlRecord> weightControls,
      })> getPatientHistory(String patientId) async {
    final data = await _client.get(
      '/api/doctors/patients/$patientId/medical-history',
    );
    final map = data as Map<String, dynamic>;
    final historyMap = map['history'] as Map<String, dynamic>? ?? {'entries': []};
    final profileMap = map['profile'] as Map<String, dynamic>?;
    final controlsRaw = profileMap?['weightControls'] as List<dynamic>? ?? [];
    return (
      record: PatientMedicalRecord.fromJson(historyMap),
      patientName: profileMap?['fullName'] as String?,
      avatar: null,
      weightControls: controlsRaw
          .whereType<Map>()
          .map((e) => WeightControlRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Future<void> updatePatientWeightControls({
    required String patientId,
    required List<WeightControlRecord> controls,
  }) async {
    await _client.put(
      '/api/doctors/patients/$patientId/weight-controls',
      {'weightControls': controls.map((c) => c.toJson()).toList()},
      auth: true,
    );
  }

  Future<void> addEntry({
    required String patientId,
    required String title,
    required String description,
    String? diagnosis,
    String? treatment,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      if (diagnosis != null && diagnosis.isNotEmpty) 'diagnosis': diagnosis,
      if (treatment != null && treatment.isNotEmpty) 'treatment': treatment,
    };
    await _client.post(
      '/api/doctors/patients/$patientId/medical-history/entries',
      body,
      auth: true,
    );
  }
}
