import '../../../core/network/api_client.dart';

final _client = ApiClient();

class OverviewStats {
  final int patients;
  final int doctors;
  final int clinicAdmins;
  final int pharmacyAdmins;
  final int appointments;
  final int facilities;
  final int pharmacies;
  final int pharmacyOrders;
  final int productsListed;

  OverviewStats({
    required this.patients,
    required this.doctors,
    required this.clinicAdmins,
    required this.pharmacyAdmins,
    required this.appointments,
    required this.facilities,
    required this.pharmacies,
    required this.pharmacyOrders,
    required this.productsListed,
  });

  factory OverviewStats.fromJson(Map<String, dynamic> j) => OverviewStats(
        patients: (j['patients'] as num?)?.toInt() ?? 0,
        doctors: (j['doctors'] as num?)?.toInt() ?? 0,
        clinicAdmins: (j['clinicAdmins'] as num?)?.toInt() ?? 0,
        pharmacyAdmins: (j['pharmacyAdmins'] as num?)?.toInt() ?? 0,
        appointments: (j['appointments'] as num?)?.toInt() ?? 0,
        facilities: (j['facilities'] as num?)?.toInt() ?? 0,
        pharmacies: (j['pharmacies'] as num?)?.toInt() ?? 0,
        pharmacyOrders: (j['pharmacyOrders'] as num?)?.toInt() ?? 0,
        productsListed: (j['productsListed'] as num?)?.toInt() ?? 0,
      );
}

class FacilityStatItem {
  final String id;
  final String name;
  final String? city;
  final bool serviceEnabled;
  final int appointmentsCount;
  final int patientsViaApp;

  FacilityStatItem({
    required this.id,
    required this.name,
    this.city,
    required this.serviceEnabled,
    required this.appointmentsCount,
    required this.patientsViaApp,
  });

  factory FacilityStatItem.fromJson(Map<String, dynamic> j) {
    final f = j['facility'] as Map<String, dynamic>? ?? {};
    return FacilityStatItem(
      id: f['id']?.toString() ?? f['_id']?.toString() ?? '',
      name: f['name'] as String? ?? '',
      city: f['city'] as String?,
      serviceEnabled: f['serviceEnabled'] as bool? ?? true,
      appointmentsCount: (j['appointmentsCount'] as num?)?.toInt() ?? 0,
      patientsViaApp: (j['patientsViaApp'] as num?)?.toInt() ?? 0,
    );
  }
}

class PharmacyStatItem {
  final String id;
  final String name;
  final bool serviceEnabled;
  final int ordersCount;
  final int productsCount;
  final double revenueTotal;

  PharmacyStatItem({
    required this.id,
    required this.name,
    required this.serviceEnabled,
    required this.ordersCount,
    required this.productsCount,
    required this.revenueTotal,
  });

  factory PharmacyStatItem.fromJson(Map<String, dynamic> j) {
    final p = j['pharmacy'] as Map<String, dynamic>? ?? {};
    return PharmacyStatItem(
      id: p['id']?.toString() ?? p['_id']?.toString() ?? '',
      name: p['name'] as String? ?? '',
      serviceEnabled: p['serviceEnabled'] as bool? ?? true,
      ordersCount: (j['ordersCount'] as num?)?.toInt() ?? 0,
      productsCount: (j['productsCount'] as num?)?.toInt() ?? 0,
      revenueTotal: (j['revenueTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class StaffCreateResult {
  final String email;
  final String name;
  final String temporaryPassword;

  StaffCreateResult({
    required this.email,
    required this.name,
    required this.temporaryPassword,
  });

  factory StaffCreateResult.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    return StaffCreateResult(
      email: user['email'] as String? ?? '',
      name: user['name'] as String? ?? '',
      temporaryPassword: j['temporaryPassword'] as String? ?? '',
    );
  }
}

class SuperAdminApiService {
  Future<OverviewStats> getOverview() async {
    final data = await _client.get('/api/super-admin/stats/overview');
    return OverviewStats.fromJson(data as Map<String, dynamic>);
  }

  Future<List<FacilityStatItem>> getFacilityStats() async {
    final data = await _client.get('/api/super-admin/stats/facilities');
    return (data as List)
        .map((e) => FacilityStatItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PharmacyStatItem>> getPharmacyStats() async {
    final data = await _client.get('/api/super-admin/stats/pharmacies');
    return (data as List)
        .map((e) => PharmacyStatItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setFacilityService(String id, bool enabled) async {
    await _client.patch('/api/super-admin/facilities/$id/service', {
      'serviceEnabled': enabled,
    });
  }

  Future<void> setPharmacyService(String id, bool enabled) async {
    await _client.patch('/api/super-admin/pharmacies/$id/service', {
      'serviceEnabled': enabled,
    });
  }

  Future<StaffCreateResult> createClinicAdmin({
    required String name,
    required String email,
    required String phone,
    required String facilityId,
  }) async {
    final data = await _client.post(
      '/api/super-admin/admins/clinic',
      {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'facilityId': facilityId,
      },
      auth: true,
    );
    return StaffCreateResult.fromJson(data);
  }

  Future<StaffCreateResult> createPharmacyAdmin({
    required String name,
    required String email,
    required String phone,
    required String pharmacyId,
  }) async {
    final data = await _client.post(
      '/api/super-admin/admins/pharmacy',
      {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'pharmacyId': pharmacyId,
      },
      auth: true,
    );
    return StaffCreateResult.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> listFacilities() async {
    final data = await _client.get('/api/super-admin/facilities');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createFacility({
    required String name,
    required String address,
    String type = 'CLINIC',
    String? city,
    String? phone,
  }) async {
    final data = await _client.post(
      '/api/super-admin/facilities',
      {
        'name': name.trim(),
        'address': address.trim(),
        'type': type,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
      auth: true,
    );
    return data;
  }

  Future<List<Map<String, dynamic>>> listPharmacies() async {
    final data = await _client.get('/api/super-admin/pharmacies');
    return (data as List).cast<Map<String, dynamic>>();
  }
}
