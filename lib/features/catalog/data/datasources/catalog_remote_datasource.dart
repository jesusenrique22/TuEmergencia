import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_helpers.dart';

class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> fetchFacilities() async {
    final data = await _client.get('/api/catalog/facilities', auth: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchMapPoisRaw() async {
    return JsonHelpers.asMap(
      await _client.get('/api/catalog/map-pois', auth: false),
    );
  }
}
