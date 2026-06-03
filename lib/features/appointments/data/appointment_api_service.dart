import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/utils/appointment_datetime.dart';
import '../domain/models/appointment.dart';
import '../domain/models/consultation_report.dart';

final _client = ApiClient();

class AppointmentApiService {
  Future<List<Appointment>> getMyAppointments() async {
    final data = await _client.get('/api/patients/appointments', auth: true);
    final list = data as List<dynamic>;
    return list
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Appointment>> getDoctorAppointments({String? date}) async {
    final query = date != null ? '?date=$date' : '';
    final data = await _client.get('/api/doctors/appointments$query', auth: true);
    final list = data as List<dynamic>;
    return list
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> createAppointment({
    required String doctorId,
    required DateTime dateTime,
    required String type,
    String? facilityId,
    String? specialtyId,
    String? reason,
    int? durationMinutes,
  }) async {
    final body = <String, dynamic>{
      'doctorId': doctorId,
      'dateTime': appointmentDateTimeToApi(dateTime),
      'type': type,
      'facilityId': ?facilityId,
      'specialtyId': ?specialtyId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      'durationMinutes': ?durationMinutes,
    };
    final data =
        await _client.post('/api/appointments', body, auth: true);
    return Appointment.fromJson(data);
  }

  Future<Appointment> rateAppointment(
    String id, {
    required int rating,
    String? comment,
  }) async {
    final data = await _client.post(
      '/api/appointments/$id/rate',
      {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      auth: true,
    );
    return Appointment.fromJson(data);
  }

  Future<Appointment> cancelAppointment(String id) async {
    final data = await _client.patch('/api/appointments/$id/cancel', {}, auth: true);
    return Appointment.fromJson(data);
  }

  Future<Appointment> updateStatus(
    String id,
    String status, {
    String? notes,
    String? clinicalNotes,
    ConsultationReport? report,
    List<({List<int> bytes, String mimeType, String fileName})>? attachments,
  }) async {
    final body = <String, dynamic>{
      'status': status,
      'notes': ?notes,
      'clinicalNotes': ?clinicalNotes,
    };
    if (report != null) {
      final reportBody = report.toApiBody();
      if (attachments != null && attachments.isNotEmpty) {
        reportBody['attachments'] = attachments
            .map(
              (a) => {
                'dataBase64': base64Encode(a.bytes),
                'mimeType': a.mimeType,
                'fileName': a.fileName,
              },
            )
            .toList();
      }
      body['report'] = reportBody;
    }
    final data = await _client.patch('/api/doctors/appointments/$id', body);
    return Appointment.fromJson(data);
  }

  Future<Appointment> acknowledgeReport(String appointmentId) async {
    final data = await _client.post(
      '/api/appointments/$appointmentId/acknowledge-report',
      {},
      auth: true,
    );
    return Appointment.fromJson(data);
  }
}

class CatalogApiService {
  Future<List<SpecialtyCatalogItem>> listSpecialties() async {
    final data = await _client.get('/api/catalog/specialties', auth: false);
    final list = data as List<dynamic>;
    return list
        .map((e) => SpecialtyCatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DoctorCatalogItem>> listDoctors({String? specialtyId}) async {
    final query = specialtyId != null ? '?specialtyId=$specialtyId' : '';
    final data = await _client.get('/api/catalog/doctors$query', auth: false);
    final list = data as List<dynamic>;
    return list
        .map((e) => DoctorCatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({List<AppointmentTimeSlot> slots, int durationMinutes})>
      getAvailability({
    required String doctorId,
    required String date,
    required String type,
    String? specialtyId,
    String? facilityId,
  }) async {
    final params = StringBuffer('?date=$date&type=$type');
    if (specialtyId != null) params.write('&specialtyId=$specialtyId');
    if (facilityId != null) params.write('&facilityId=$facilityId');

    final data = await _client.get(
      '/api/catalog/doctors/$doctorId/availability$params',
      auth: false,
    );
    final map = data as Map<String, dynamic>;
    final slots = map['slots'] as List<dynamic>;
    final duration = (map['durationMinutes'] as num?)?.toInt() ?? 30;
    return (
      slots: slots
          .map((e) => AppointmentTimeSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      durationMinutes: duration,
    );
  }
}
