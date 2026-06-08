import '../../../../core/geo/geo_point.dart';
import '../models/emergency_models.dart';

abstract class EmergencyRepository {
  Future<EmergencyRequest> create(CreateEmergencyParams params);
  Future<EmergencyRequest> getById(String id);
  Future<EmergencyRequest> cancel(String id);
  Future<List<EmergencyRequest>> listMine();
  Future<void> updateDriverLocation({
    required String emergencyId,
    required GeoPoint location,
    int? etaMinutes,
  });
}

abstract class EmergencyRealtimeClient {
  Stream<EmergencyRequest> watchUpdates(String emergencyId);
  Stream<EmergencyLocationUpdate> watchLocation(String emergencyId);
  Future<void> subscribe(String emergencyId);
  Future<void> unsubscribe(String emergencyId);
}
