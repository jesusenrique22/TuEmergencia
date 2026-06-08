import '../../../core/network/api_client.dart';
import 'admin_api_service.dart';

final _client = ApiClient();

class ClinicDoctorListItem {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? profilePic;
  final List<String> specialties;
  final List<String> facilityNames;
  final bool canInvite;
  final String? inviteBlockedReason;

  const ClinicDoctorListItem({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.profilePic,
    required this.specialties,
    required this.facilityNames,
    this.canInvite = true,
    this.inviteBlockedReason,
  });

  static String _idFrom(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return value['_id']?.toString() ?? value['id']?.toString() ?? '';
    }
    return value.toString();
  }

  factory ClinicDoctorListItem.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw const FormatException('Doctor sin datos de usuario');
    }
    final profile = j['profile'] as Map<String, dynamic>?;

    List<String> names(dynamic list) {
      if (list == null) return [];
      return (list as List).map((e) {
        if (e is Map<String, dynamic>) return e['name'] as String? ?? '';
        return '';
      }).toList();
    }

    return ClinicDoctorListItem(
      userId: _idFrom(user['_id'] ?? user['id']),
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      phone: user['phone'] as String?,
      profilePic: user['profilePic'] as String?,
      specialties: profile != null ? names(profile['specialtyIds']) : const [],
      facilityNames: profile != null ? names(profile['facilityIds']) : const [],
      canInvite: j['canInvite'] as bool? ?? true,
      inviteBlockedReason: j['inviteBlockedReason'] as String?,
    );
  }
}

class ClinicPendingInvitation {
  final String id;
  final String doctorName;
  final String doctorEmail;

  const ClinicPendingInvitation({
    required this.id,
    required this.doctorName,
    required this.doctorEmail,
  });

  factory ClinicPendingInvitation.fromJson(Map<String, dynamic> j) {
    final doctor = j['doctor'] as Map<String, dynamic>? ?? {};
    return ClinicPendingInvitation(
      id: j['id'] as String? ?? j['_id'] as String? ?? '',
      doctorName: doctor['name'] as String? ?? '',
      doctorEmail: doctor['email'] as String? ?? '',
    );
  }
}

class ClinicDashboardData {
  final String facilityName;
  final String facilityId;
  final int doctorsCount;
  final int appointmentsToday;
  final int pendingInvitationsCount;
  final List<ClinicDoctorListItem> doctors;
  final List<ClinicPendingInvitation> pendingInvitations;

  const ClinicDashboardData({
    required this.facilityName,
    required this.facilityId,
    required this.doctorsCount,
    required this.appointmentsToday,
    required this.pendingInvitationsCount,
    required this.doctors,
    required this.pendingInvitations,
  });

  factory ClinicDashboardData.fromJson(Map<String, dynamic> j) {
    final facility = j['facility'] as Map<String, dynamic>? ?? {};
    final stats = j['stats'] as Map<String, dynamic>? ?? {};
    final rawDoctors = j['doctors'] as List<dynamic>? ?? [];
    final rawInvites = j['pendingInvitations'] as List<dynamic>? ?? [];

    return ClinicDashboardData(
      facilityName: facility['name'] as String? ?? 'Clínica',
      facilityId: facility['_id'] as String? ?? '',
      doctorsCount: (stats['doctorsCount'] as num?)?.toInt() ?? 0,
      appointmentsToday: (stats['appointmentsToday'] as num?)?.toInt() ?? 0,
      pendingInvitationsCount:
          (stats['pendingInvitationsCount'] as num?)?.toInt() ??
          rawInvites.length,
      doctors: rawDoctors
          .map((e) => ClinicDoctorListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingInvitations: rawInvites
          .map(
            (e) => ClinicPendingInvitation.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class ClinicAdminApiService {
  Future<Map<String, dynamic>> getMyContext() async {
    final data = await _client.get('/api/clinic-admin/me');
    return data as Map<String, dynamic>;
  }

  Future<ClinicDashboardData> getDashboard() async {
    final data = await _client.get('/api/clinic-admin/dashboard');
    return ClinicDashboardData.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ClinicDoctorListItem>> listFacilityDoctors() async {
    final data = await _client.get('/api/clinic-admin/doctors');
    final list = data as List<dynamic>;
    final doctors = <ClinicDoctorListItem>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      try {
        doctors.add(ClinicDoctorListItem.fromJson(Map<String, dynamic>.from(raw)));
      } catch (_) {}
    }
    return doctors;
  }

  Future<List<ClinicDoctorListItem>> listAssignableDoctors({String? search}) async {
    final query = search != null && search.trim().isNotEmpty
        ? '?search=${Uri.encodeQueryComponent(search.trim())}'
        : '';
    final data = await _client.get('/api/clinic-admin/doctors/assignable$query');
    final list = data as List<dynamic>;
    final doctors = <ClinicDoctorListItem>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      try {
        doctors.add(ClinicDoctorListItem.fromJson(Map<String, dynamic>.from(raw)));
      } catch (_) {
        // Omitir entradas corruptas del API.
      }
    }
    return doctors;
  }

  Future<String> assignDoctor(String doctorUserId) async {
    final data = await _client.post(
      '/api/clinic-admin/doctors/assign',
      {'doctorUserId': doctorUserId},
      auth: true,
    );
    return data['message'] as String? ??
        'Invitación enviada. El médico debe aceptarla.';
  }

  Future<void> unassignDoctor(
    String doctorUserId, {
    bool deleteAccount = false,
  }) async {
    final q = deleteAccount ? '?deleteAccount=true' : '';
    await _client.delete('/api/clinic-admin/doctors/$doctorUserId$q');
  }

  Future<CreateDoctorResult> createDoctor({
    required String name,
    required String email,
    required String phone,
    required String documentId,
    required String specialtyId,
  }) async {
    final data = await _client.post(
      '/api/clinic-admin/doctors',
      {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'documentId': documentId.trim(),
        'specialtyId': specialtyId,
      },
      auth: true,
    );
    return CreateDoctorResult.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch(
      '/api/clinic-admin/password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      auth: true,
    );
  }

  Future<List<AmbulanceStaffItem>> listAmbulanceStaff({String? role}) async {
    final query = role != null && role.isNotEmpty ? '?role=$role' : '';
    final data = await _client.get('/api/clinic-admin/ambulance-staff$query');
    return (data as List)
        .map((e) => AmbulanceStaffItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CreateDoctorResult> createAmbulanceStaff({
    required String role,
    required String name,
    required String email,
    String? phone,
  }) async {
    final data = await _client.post(
      '/api/clinic-admin/ambulance-staff',
      {
        'role': role,
        'name': name.trim(),
        'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
      auth: true,
    );
    return CreateDoctorResult.fromJson(data);
  }

  Future<List<AmbulanceDriverItem>> listAmbulanceDrivers() async {
    final data = await _client.get('/api/clinic-admin/ambulance-drivers');
    return (data as List)
        .map((e) => AmbulanceDriverItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CreateDoctorResult> createAmbulanceDriver({
    required String name,
    required String email,
    String? phone,
  }) async {
    final data = await _client.post(
      '/api/clinic-admin/ambulance-drivers',
      {
        'name': name.trim(),
        'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
      auth: true,
    );
    return CreateDoctorResult.fromJson(data);
  }

  Future<List<AmbulanceUnitItem>> listAmbulances() async {
    final data = await _client.get('/api/clinic-admin/ambulances');
    return (data as List)
        .map((e) => AmbulanceUnitItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AmbulanceUnitItem> createAmbulance({
    required String plateNumber,
    String? callSign,
    String? driverId,
    String? paramedicId,
    String? nurseId,
  }) async {
    final data = await _client.post(
      '/api/clinic-admin/ambulances',
      {
        'plateNumber': plateNumber.trim(),
        if (callSign != null && callSign.trim().isNotEmpty) 'callSign': callSign.trim(),
        if (driverId != null && driverId.isNotEmpty) 'driverId': driverId,
        if (paramedicId != null && paramedicId.isNotEmpty) 'paramedicId': paramedicId,
        if (nurseId != null && nurseId.isNotEmpty) 'nurseId': nurseId,
      },
      auth: true,
    );
    return AmbulanceUnitItem.fromJson(Map<String, dynamic>.from(data));
  }

  Future<AmbulanceUnitItem> updateAmbulance(
    String unitId, {
    String? callSign,
    String? driverId,
    String? paramedicId,
    String? nurseId,
    String? status,
  }) async {
    final data = await _client.patch(
      '/api/clinic-admin/ambulances/$unitId',
      {
        if (callSign != null) 'callSign': callSign.trim(),
        if (driverId != null) 'driverId': driverId.isEmpty ? null : driverId,
        if (paramedicId != null) 'paramedicId': paramedicId.isEmpty ? null : paramedicId,
        if (nurseId != null) 'nurseId': nurseId.isEmpty ? null : nurseId,
        'status': ?status,
      },
      auth: true,
    );
    return AmbulanceUnitItem.fromJson(Map<String, dynamic>.from(data));
  }
}

class AmbulanceStaffItem {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  AmbulanceStaffItem({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
  });

  factory AmbulanceStaffItem.fromJson(Map<String, dynamic> json) {
    return AmbulanceStaffItem(
      id: (json['_id'] ?? json['id']).toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'AMBULANCE_DRIVER',
    );
  }

  String get roleLabel {
    switch (role) {
      case 'PARAMEDIC':
        return 'Paramédico';
      case 'AMBULANCE_NURSE':
        return 'Enfermero/a';
      default:
        return 'Conductor';
    }
  }
}

class AmbulanceDriverItem {
  final String id;
  final String name;
  final String email;
  final String? phone;

  AmbulanceDriverItem({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory AmbulanceDriverItem.fromJson(Map<String, dynamic> json) {
    return AmbulanceDriverItem(
      id: (json['_id'] ?? json['id']).toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}

class AmbulanceUnitItem {
  final String id;
  final String plateNumber;
  final String? callSign;
  final String status;
  final String? driverId;
  final String? driverName;
  final String? paramedicId;
  final String? paramedicName;
  final String? nurseId;
  final String? nurseName;

  AmbulanceUnitItem({
    required this.id,
    required this.plateNumber,
    this.callSign,
    required this.status,
    this.driverId,
    this.driverName,
    this.paramedicId,
    this.paramedicName,
    this.nurseId,
    this.nurseName,
  });

  factory AmbulanceUnitItem.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final paramedic = json['paramedic'] as Map<String, dynamic>?;
    final nurse = json['nurse'] as Map<String, dynamic>?;
    return AmbulanceUnitItem(
      id: (json['_id'] ?? json['id']).toString(),
      plateNumber: json['plateNumber'] as String? ?? '',
      callSign: json['callSign'] as String?,
      status: json['status'] as String? ?? 'AVAILABLE',
      driverId: driver?['id']?.toString() ?? json['driverId']?.toString(),
      driverName: driver?['name'] as String?,
      paramedicId: paramedic?['id']?.toString() ?? json['paramedicId']?.toString(),
      paramedicName: paramedic?['name'] as String?,
      nurseId: nurse?['id']?.toString() ?? json['nurseId']?.toString(),
      nurseName: nurse?['name'] as String?,
    );
  }

  String get displayName => callSign ?? plateNumber;
}

