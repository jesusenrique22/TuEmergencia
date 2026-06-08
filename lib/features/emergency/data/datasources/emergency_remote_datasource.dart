import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_helpers.dart';

class EmergencyRemoteDataSource {
  EmergencyRemoteDataSource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    return JsonHelpers.asMap(
      await _client.post('/api/emergencies', body, auth: true),
    );
  }

  Future<Map<String, dynamic>> getById(String id) async {
    return JsonHelpers.asMap(
      await _client.get('/api/emergencies/$id', auth: true),
    );
  }

  Future<Map<String, dynamic>> cancel(String id) async {
    return JsonHelpers.asMap(
      await _client.post('/api/emergencies/$id/cancel', {}, auth: true),
    );
  }

  Future<List<Map<String, dynamic>>> listMine() async {
    final data = await _client.get('/api/emergencies/mine', auth: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> patchLocation(
    String id, {
    required double latitude,
    required double longitude,
    int? etaMinutes,
  }) async {
    await _client.patch(
      '/api/emergencies/$id/location',
      {
        'latitude': latitude,
        'longitude': longitude,
        'etaMinutes': ?etaMinutes,
      },
      auth: true,
    );
  }
}
