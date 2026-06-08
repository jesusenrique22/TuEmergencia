import '../../../core/network/api_client.dart';

class AmbulanceCrewApiService {
  AmbulanceCrewApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AmbulanceCrewProfileData> getProfile() async {
    final data = await _client.get('/api/ambulance-crew/me', auth: true);
    return AmbulanceCrewProfileData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<AmbulanceCrewProfileData> updateProfile({
    String? name,
    String? phone,
    String? profilePic,
    String? licenseNumber,
    String? certification,
    String? bio,
  }) async {
    final data = await _client.patch(
      '/api/ambulance-crew/me',
      {
        if (name != null) 'name': name.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (profilePic != null) 'profilePic': profilePic.trim(),
        if (licenseNumber != null) 'licenseNumber': licenseNumber.trim(),
        if (certification != null) 'certification': certification.trim(),
        if (bio != null) 'bio': bio.trim(),
      },
      auth: true,
    );
    return AmbulanceCrewProfileData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch(
      '/api/ambulance-crew/me/password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      auth: true,
    );
  }
}

class AmbulanceCrewProfileData {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profilePic;
  final String? licenseNumber;
  final String? certification;
  final String? bio;
  final AmbulanceCrewUnitSummary? assignedUnit;

  AmbulanceCrewProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profilePic,
    this.licenseNumber,
    this.certification,
    this.bio,
    this.assignedUnit,
  });

  factory AmbulanceCrewProfileData.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map? ?? {});
    final profile = Map<String, dynamic>.from(json['profile'] as Map? ?? {});
    final unitRaw = json['assignedUnit'];
    return AmbulanceCrewProfileData(
      id: (user['_id'] ?? user['id']).toString(),
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      role: user['role'] as String? ?? '',
      phone: user['phone'] as String?,
      profilePic: user['profilePic'] as String?,
      licenseNumber: profile['licenseNumber'] as String?,
      certification: profile['certification'] as String?,
      bio: profile['bio'] as String?,
      assignedUnit: unitRaw is Map
          ? AmbulanceCrewUnitSummary.fromJson(Map<String, dynamic>.from(unitRaw))
          : null,
    );
  }
}

class AmbulanceCrewUnitSummary {
  final String id;
  final String plateNumber;
  final String? callSign;
  final String status;
  final String crewRole;
  final String? facilityName;
  final String? driverName;
  final String? paramedicName;
  final String? nurseName;

  AmbulanceCrewUnitSummary({
    required this.id,
    required this.plateNumber,
    this.callSign,
    required this.status,
    required this.crewRole,
    this.facilityName,
    this.driverName,
    this.paramedicName,
    this.nurseName,
  });

  factory AmbulanceCrewUnitSummary.fromJson(Map<String, dynamic> json) {
    final facility = json['facility'] as Map<String, dynamic>?;
    return AmbulanceCrewUnitSummary(
      id: (json['_id'] ?? json['id']).toString(),
      plateNumber: json['plateNumber'] as String? ?? '',
      callSign: json['callSign'] as String?,
      status: json['status'] as String? ?? 'AVAILABLE',
      crewRole: json['crewRole'] as String? ?? '',
      facilityName: facility?['name'] as String?,
      driverName: json['driverName'] as String?,
      paramedicName: json['paramedicName'] as String?,
      nurseName: json['nurseName'] as String?,
    );
  }

  String get displayName => callSign ?? plateNumber;
}
