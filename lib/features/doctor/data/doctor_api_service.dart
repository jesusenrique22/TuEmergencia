import '../../../core/network/api_client.dart';

final _client = ApiClient();

class DoctorProfileContext {
  final String name;
  final String subtitle;
  final String avatarUrl;
  final double rating;
  final int ratingCount;

  const DoctorProfileContext({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.rating,
    required this.ratingCount,
  });
}

class DoctorFacilityItem {
  final String id;
  final String name;

  const DoctorFacilityItem({required this.id, required this.name});

  factory DoctorFacilityItem.fromJson(Map<String, dynamic> json) {
    return DoctorFacilityItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
    );
  }
}

class DoctorWorkScheduleItem {
  final String id;
  final String dayLabel;
  final String facilityName;
  final String startTime;
  final String endTime;

  const DoctorWorkScheduleItem({
    required this.id,
    required this.dayLabel,
    required this.facilityName,
    required this.startTime,
    required this.endTime,
  });

  static const _dayLabels = {
    'MONDAY': 'Lunes',
    'TUESDAY': 'Martes',
    'WEDNESDAY': 'Miércoles',
    'THURSDAY': 'Jueves',
    'FRIDAY': 'Viernes',
    'SATURDAY': 'Sábado',
    'SUNDAY': 'Domingo',
  };

  factory DoctorWorkScheduleItem.fromJson(Map<String, dynamic> json) {
    final facility = json['facilityId'];
    String facilityName = '';
    if (facility is Map<String, dynamic>) {
      facilityName = facility['name'] as String? ?? '';
    }
    final day = json['dayOfWeek'] as String? ?? '';
    return DoctorWorkScheduleItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      dayLabel: _dayLabels[day] ?? day,
      facilityName: facilityName,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );
  }
}

class DoctorApiService {
  static String dayOfWeekFromSpanish(String spanishDay) {
    switch (spanishDay) {
      case 'Lunes':
        return 'MONDAY';
      case 'Martes':
        return 'TUESDAY';
      case 'Miércoles':
        return 'WEDNESDAY';
      case 'Jueves':
        return 'THURSDAY';
      case 'Viernes':
        return 'FRIDAY';
      case 'Sábado':
        return 'SATURDAY';
      case 'Domingo':
        return 'SUNDAY';
      default:
        return 'MONDAY';
    }
  }

  Future<DoctorProfileContext> getProfileContext() async {
    final data = await _client.get('/api/doctors/profile');
    final map = data as Map<String, dynamic>;
    final user = map['user'] as Map<String, dynamic>? ?? {};
    final profile = map['profile'] as Map<String, dynamic>? ?? {};

    final specialties = (profile['specialtyIds'] as List<dynamic>? ?? [])
        .map((e) => e is Map ? e['name'] as String? ?? '' : '')
        .where((s) => s.isNotEmpty)
        .toList();
    final facilities = (profile['facilityIds'] as List<dynamic>? ?? [])
        .map((e) => e is Map ? e['name'] as String? ?? '' : '')
        .where((s) => s.isNotEmpty)
        .toList();

    final specialtyPart =
        specialties.isNotEmpty ? specialties.join(' · ') : 'Médico';
    final facilityPart =
        facilities.isNotEmpty ? facilities.first : 'VITA OS';

    return DoctorProfileContext(
      name: user['name'] as String? ?? 'Médico',
      subtitle: '$specialtyPart • $facilityPart',
      avatarUrl: user['profilePic'] as String? ?? '',
      rating: (profile['rating'] as num?)?.toDouble() ?? 5.0,
      ratingCount: (profile['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<DoctorFacilityItem>> getMyFacilities() async {
    final data = await _client.get('/api/doctors/profile');
    final map = data as Map<String, dynamic>;
    final profile = map['profile'] as Map<String, dynamic>? ?? {};
    final list = profile['facilityIds'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(DoctorFacilityItem.fromJson)
        .toList();
  }

  Future<List<DoctorWorkScheduleItem>> getSchedules() async {
    final data = await _client.get('/api/doctors/schedules');
    final list = data as List<dynamic>;
    return list
        .map((e) => DoctorWorkScheduleItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createSchedule({
    required String facilityId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    await _client.post('/api/doctors/schedules', {
      'facilityId': facilityId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
    });
  }

  Future<void> deleteSchedule(String id) async {
    await _client.delete('/api/doctors/schedules/$id');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch('/api/doctors/profile/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<String> acceptClinicInvitation(String invitationId) async {
    final data = await _client.post(
      '/api/doctors/clinic-invitations/$invitationId/accept',
      {},
    );
    return data['message'] as String? ?? 'Invitación aceptada';
  }

  Future<String> rejectClinicInvitation(String invitationId) async {
    final data = await _client.post(
      '/api/doctors/clinic-invitations/$invitationId/reject',
      {},
    );
    return data['message'] as String? ?? 'Invitación rechazada';
  }
}
