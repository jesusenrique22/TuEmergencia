enum AppointmentStatus { pending, confirmed, completed, cancelled }

enum AppointmentType { online, presential }

AppointmentStatus _parseStatus(String? s) {
  switch (s?.toUpperCase()) {
    case 'CONFIRMED':
      return AppointmentStatus.confirmed;
    case 'COMPLETED':
      return AppointmentStatus.completed;
    case 'CANCELLED':
      return AppointmentStatus.cancelled;
    default:
      return AppointmentStatus.pending;
  }
}

AppointmentType _parseType(String? s) =>
    s?.toUpperCase() == 'ONLINE' ? AppointmentType.online : AppointmentType.presential;

class _PopulatedUser {
  final String id;
  final String name;
  final String email;
  final String? profilePic;
  final String? phone;

  const _PopulatedUser({
    required this.id,
    required this.name,
    required this.email,
    this.profilePic,
    this.phone,
  });

  factory _PopulatedUser.fromJson(Map<String, dynamic> j) => _PopulatedUser(
        id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        profilePic: j['profilePic'] as String?,
        phone: j['phone'] as String?,
      );
}

class _PopulatedFacility {
  final String id;
  final String name;
  final String? address;

  const _PopulatedFacility({required this.id, required this.name, this.address});

  factory _PopulatedFacility.fromJson(Map<String, dynamic> j) => _PopulatedFacility(
        id: j['_id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        address: j['address'] as String?,
      );
}

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientAvatar;
  final String doctorId;
  final String doctorName;
  final String? doctorAvatar;
  final String? doctorPhone;
  final String specialty;
  final DateTime dateTime;
  final DateTime? endTime;
  final int durationMinutes;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? reason;
  final String? notes;
  final double price;
  final String? facilityName;
  final String? facilityAddress;
  final int? patientRating;
  final String? patientReview;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientAvatar,
    required this.doctorId,
    required this.doctorName,
    this.doctorAvatar,
    this.doctorPhone,
    required this.specialty,
    required this.dateTime,
    this.endTime,
    this.durationMinutes = 30,
    required this.status,
    required this.type,
    this.reason,
    this.notes,
    required this.price,
    this.facilityName,
    this.facilityAddress,
    this.patientRating,
    this.patientReview,
  });

  bool get canRate =>
      status == AppointmentStatus.completed && patientRating == null;

  bool get hasRating => patientRating != null && patientRating! >= 1;

  factory Appointment.fromJson(Map<String, dynamic> j) {
    final doctor = j['doctorId'] is Map<String, dynamic>
        ? _PopulatedUser.fromJson(j['doctorId'] as Map<String, dynamic>)
        : _PopulatedUser(id: j['doctorId'] as String? ?? '', name: '', email: '');

    final patient = j['patientId'] is Map<String, dynamic>
        ? _PopulatedUser.fromJson(j['patientId'] as Map<String, dynamic>)
        : _PopulatedUser(id: j['patientId'] as String? ?? '', name: '', email: '');

    _PopulatedFacility? facility;
    if (j['facilityId'] is Map<String, dynamic>) {
      facility = _PopulatedFacility.fromJson(j['facilityId'] as Map<String, dynamic>);
    }

    final specialtyRaw = j['specialtyId'];
    final specialtyName = specialtyRaw is Map<String, dynamic>
        ? specialtyRaw['name'] as String? ?? ''
        : '';

    return Appointment(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      patientId: patient.id,
      patientName: patient.name,
      patientAvatar: patient.profilePic,
      doctorId: doctor.id,
      doctorName: doctor.name,
      doctorAvatar: doctor.profilePic,
      doctorPhone: doctor.phone,
      specialty: specialtyName,
      dateTime: DateTime.parse(j['dateTime'] as String),
      endTime: j['endTime'] != null ? DateTime.parse(j['endTime'] as String) : null,
      durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 30,
      status: _parseStatus(j['status'] as String?),
      type: _parseType(j['type'] as String?),
      reason: j['reason'] as String?,
      notes: j['notes'] as String?,
      price: (j['price'] as num?)?.toDouble() ?? 0,
      facilityName: facility?.name,
      facilityAddress: facility?.address,
      patientRating: (j['patientRating'] as num?)?.toInt(),
      patientReview: j['patientReview'] as String?,
    );
  }
}

class SpecialtyCatalogItem {
  final String id;
  final String name;

  const SpecialtyCatalogItem({required this.id, required this.name});

  factory SpecialtyCatalogItem.fromJson(Map<String, dynamic> j) =>
      SpecialtyCatalogItem(
        id: j['_id'] as String? ?? '',
        name: j['name'] as String? ?? '',
      );
}

class SpecialtyDurationRule {
  final String specialtyId;
  final int durationMinutes;

  const SpecialtyDurationRule({
    required this.specialtyId,
    required this.durationMinutes,
  });

  factory SpecialtyDurationRule.fromJson(Map<String, dynamic> j) =>
      SpecialtyDurationRule(
        specialtyId: j['specialtyId'] is Map
            ? (j['specialtyId'] as Map)['_id'] as String? ?? ''
            : j['specialtyId'] as String? ?? '',
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 30,
      );
}

class DoctorCatalogItem {
  final String userId;
  final String name;
  final String? profilePic;
  final String? phone;
  final String bio;
  final List<String> specialtyIds;
  final List<String> specialties;
  final List<String> facilityIds;
  final List<String> facilityNames;
  final double rating;
  final int ratingCount;
  final double priceOnline;
  final double pricePresential;
  final int defaultConsultationMinutes;
  final List<SpecialtyDurationRule> specialtyDurations;

  const DoctorCatalogItem({
    required this.userId,
    required this.name,
    this.profilePic,
    this.phone,
    required this.bio,
    required this.specialtyIds,
    required this.specialties,
    required this.facilityIds,
    required this.facilityNames,
    required this.rating,
    this.ratingCount = 0,
    required this.priceOnline,
    required this.pricePresential,
    this.defaultConsultationMinutes = 30,
    this.specialtyDurations = const [],
  });

  int consultationMinutesFor(String? specialtyId) {
    if (specialtyId != null) {
      for (final rule in specialtyDurations) {
        if (rule.specialtyId == specialtyId) return rule.durationMinutes;
      }
    }
    return defaultConsultationMinutes;
  }

  factory DoctorCatalogItem.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    final profile = j['profile'] as Map<String, dynamic>? ?? {};

    List<String> parseNames(dynamic list) {
      if (list == null) return [];
      return (list as List).map((e) {
        if (e is Map<String, dynamic>) return e['name'] as String? ?? '';
        return e.toString();
      }).toList();
    }

    List<String> parseIds(dynamic list) {
      if (list == null) return [];
      return (list as List).map((e) {
        if (e is Map<String, dynamic>) return e['_id']?.toString() ?? '';
        return e.toString();
      }).toList();
    }

    return DoctorCatalogItem(
      userId: user['_id']?.toString() ?? '',
      name: user['name'] as String? ?? '',
      profilePic: user['profilePic'] as String?,
      phone: user['phone'] as String?,
      bio: profile['bio'] as String? ?? '',
      specialtyIds: parseIds(profile['specialtyIds']),
      specialties: parseNames(profile['specialtyIds']),
      facilityIds: parseIds(profile['facilityIds']),
      facilityNames: parseNames(profile['facilityIds']),
      rating: (profile['rating'] as num?)?.toDouble() ?? 5.0,
      ratingCount: (profile['ratingCount'] as num?)?.toInt() ?? 0,
      priceOnline: (profile['consultationPriceOnline'] as num?)?.toDouble() ?? 25.0,
      pricePresential: (profile['consultationPricePresential'] as num?)?.toDouble() ?? 45.0,
      defaultConsultationMinutes:
          (profile['defaultConsultationMinutes'] as num?)?.toInt() ?? 30,
      specialtyDurations: (profile['specialtyConsultationDurations'] as List?)
              ?.map(
                (e) => SpecialtyDurationRule.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }
}

class AppointmentTimeSlot {
  final String startTime;
  final String endTime;
  final DateTime dateTime;
  final bool available;
  final String? facilityId;
  final String? facilityName;

  const AppointmentTimeSlot({
    required this.startTime,
    required this.endTime,
    required this.dateTime,
    required this.available,
    this.facilityId,
    this.facilityName,
  });

  factory AppointmentTimeSlot.fromJson(Map<String, dynamic> j) => AppointmentTimeSlot(
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
        dateTime: DateTime.parse(j['dateTime'] as String),
        available: j['available'] as bool? ?? false,
        facilityId: j['facilityId'] as String?,
        facilityName: j['facilityName'] as String?,
      );
}
