import '../../../../core/geo/geo_point.dart';
import '../../domain/models/emergency_models.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../datasources/emergency_remote_datasource.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  EmergencyRepositoryImpl(this._remote);

  final EmergencyRemoteDataSource _remote;

  @override
  Future<EmergencyRequest> create(CreateEmergencyParams params) async {
    final json = await _remote.create({
      'facilityId': params.facilityId,
      'originLat': params.origin.latitude,
      'originLng': params.origin.longitude,
      if (params.originAddress?.isNotEmpty == true)
        'originAddress': params.originAddress,
      if (params.symptoms?.isNotEmpty == true) 'symptoms': params.symptoms,
      if (params.painLevel != null) 'painLevel': params.painLevel,
      if (params.medicalHistory?.isNotEmpty == true)
        'medicalHistory': params.medicalHistory,
    });
    return EmergencyRequest.fromJson(json);
  }

  @override
  Future<EmergencyRequest> getById(String id) async {
    return EmergencyRequest.fromJson(await _remote.getById(id));
  }

  @override
  Future<EmergencyRequest> cancel(String id) async {
    return EmergencyRequest.fromJson(await _remote.cancel(id));
  }

  @override
  Future<List<EmergencyRequest>> listMine() async {
    final rows = await _remote.listMine();
    return rows.map(EmergencyRequest.fromJson).toList();
  }

  @override
  Future<void> updateDriverLocation({
    required String emergencyId,
    required GeoPoint location,
    int? etaMinutes,
  }) async {
    await _remote.patchLocation(
      emergencyId,
      latitude: location.latitude,
      longitude: location.longitude,
      etaMinutes: etaMinutes,
    );
  }
}
