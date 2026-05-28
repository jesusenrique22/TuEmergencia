import '../../../core/network/api_client.dart';

class PatientApiService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get('/api/patients/profile');
    if (response is Map<String, dynamic>) return response;
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    await _client.put('/api/patients/profile', profile);
  }
}
