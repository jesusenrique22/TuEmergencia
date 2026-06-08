import '../models/catalog_models.dart';

abstract class CatalogRepository {
  Future<List<MedicalFacility>> listActiveFacilities();
  Future<List<MapPoi>> listMapPois();
  Future<List<MedicalFacility>> listEmergencyFacilities();
}
