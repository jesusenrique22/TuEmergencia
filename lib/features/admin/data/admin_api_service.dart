import '../../../core/network/api_client.dart';

final _client = ApiClient();

class FacilityCatalogItem {
  final String id;
  final String name;
  final String? city;

  const FacilityCatalogItem({
    required this.id,
    required this.name,
    this.city,
  });

  factory FacilityCatalogItem.fromJson(Map<String, dynamic> j) {
    return FacilityCatalogItem(
      id: j['_id']?.toString() ?? '',
      name: j['name'] as String? ?? '',
      city: j['city'] as String?,
    );
  }
}

class SpecialtyCatalogItem {
  final String id;
  final String name;

  const SpecialtyCatalogItem({required this.id, required this.name});

  factory SpecialtyCatalogItem.fromJson(Map<String, dynamic> j) {
    return SpecialtyCatalogItem(
      id: j['_id']?.toString() ?? '',
      name: j['name'] as String? ?? '',
    );
  }
}

class CreateDoctorResult {
  final String userId;
  final String name;
  final String email;
  final String temporaryPassword;

  const CreateDoctorResult({
    required this.userId,
    required this.name,
    required this.email,
    required this.temporaryPassword,
  });

  factory CreateDoctorResult.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    return CreateDoctorResult(
      userId: user['id']?.toString() ?? user['_id']?.toString() ?? '',
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      temporaryPassword: j['temporaryPassword'] as String? ?? '',
    );
  }
}

class AdminApiService {
  Future<List<FacilityCatalogItem>> listFacilities() async {
    final data = await _client.get('/api/catalog/facilities', auth: false);
    final list = data as List<dynamic>;
    return list
        .map((e) => FacilityCatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SpecialtyCatalogItem>> listSpecialties() async {
    final data = await _client.get('/api/catalog/specialties', auth: false);
    final list = data as List<dynamic>;
    return list
        .map((e) => SpecialtyCatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

}
