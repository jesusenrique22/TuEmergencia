import '../../domain/models/catalog_models.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._remote);

  final CatalogRemoteDataSource _remote;

  @override
  Future<List<MedicalFacility>> listActiveFacilities() async {
    final rows = await _remote.fetchFacilities();
    return rows.map(MedicalFacility.fromJson).toList();
  }

  @override
  Future<List<MapPoi>> listMapPois() async {
    final map = await _remote.fetchMapPoisRaw();
    final items = <MapPoi>[];

    void addList(String key, MapPoiType type) {
      final list = map[key];
      if (list is! List) return;
      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        final poi = MapPoi.fromJson(raw, type);
        if (poi.location.isValid) items.add(poi);
      }
    }

    addList('facilities', MapPoiType.clinic);
    addList('laboratories', MapPoiType.laboratory);
    addList('pharmacies', MapPoiType.pharmacy);
    addList('ambulances', MapPoiType.ambulance);
    return items;
  }

  @override
  Future<List<MedicalFacility>> listEmergencyFacilities() async {
    final all = await listActiveFacilities();
    return all.where((f) => f.hasEmergencyRoom).toList();
  }
}
