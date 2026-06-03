import '../../../core/network/api_client.dart';

final _client = ApiClient();

enum FollowUpStatus { upcoming, dueToday, overdue }

FollowUpStatus followUpStatusFrom(String? value) {
  switch (value) {
    case 'due_today':
      return FollowUpStatus.dueToday;
    case 'overdue':
      return FollowUpStatus.overdue;
    default:
      return FollowUpStatus.upcoming;
  }
}

class ConsultationFollowUpItem {
  final String reportId;
  final String appointmentId;
  final DateTime consultationDate;
  final DateTime followUpDate;
  final String? followUpNote;
  final bool patientAcknowledged;
  final String patientId;
  final String patientName;
  final String? patientAvatar;
  final String doctorId;
  final String doctorName;
  final String? doctorAvatar;
  final String specialty;
  final FollowUpStatus status;

  const ConsultationFollowUpItem({
    required this.reportId,
    required this.appointmentId,
    required this.consultationDate,
    required this.followUpDate,
    this.followUpNote,
    this.patientAcknowledged = false,
    required this.patientId,
    required this.patientName,
    this.patientAvatar,
    required this.doctorId,
    required this.doctorName,
    this.doctorAvatar,
    this.specialty = '',
    this.status = FollowUpStatus.upcoming,
  });

  factory ConsultationFollowUpItem.fromJson(Map<String, dynamic> j) {
    return ConsultationFollowUpItem(
      reportId: j['reportId']?.toString() ?? j['_id']?.toString() ?? '',
      appointmentId: j['appointmentId']?.toString() ?? '',
      consultationDate:
          DateTime.tryParse(j['consultationDate'] as String? ?? '') ??
              DateTime.now(),
      followUpDate: DateTime.tryParse(j['followUpDate'] as String? ?? '') ??
          DateTime.now(),
      followUpNote: j['followUpNote'] as String?,
      patientAcknowledged: j['patientAcknowledged'] == true,
      patientId: j['patientId']?.toString() ?? '',
      patientName: j['patientName'] as String? ?? '',
      patientAvatar: j['patientAvatar'] as String?,
      doctorId: j['doctorId']?.toString() ?? '',
      doctorName: j['doctorName'] as String? ?? '',
      doctorAvatar: j['doctorAvatar'] as String?,
      specialty: j['specialty'] as String? ?? '',
      status: followUpStatusFrom(j['status'] as String?),
    );
  }

  bool get isUrgent =>
      status == FollowUpStatus.overdue || status == FollowUpStatus.dueToday;
}

class ConsultationFollowUpApiService {
  Future<List<ConsultationFollowUpItem>> getDoctorFollowUps() async {
    final data =
        await _client.get('/api/doctors/consultation-follow-ups', auth: true);
    return _parseList(data);
  }

  Future<List<ConsultationFollowUpItem>> getPatientFollowUps() async {
    final data =
        await _client.get('/api/patients/consultation-follow-ups', auth: true);
    return _parseList(data);
  }

  List<ConsultationFollowUpItem> _parseList(dynamic data) {
    final list = data as List<dynamic>;
    return list
        .map((e) =>
            ConsultationFollowUpItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
