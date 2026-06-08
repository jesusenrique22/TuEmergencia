import '../../../chat/data/chat_socket_service.dart';
import '../../../../core/services/app_realtime.dart';
import '../../domain/models/emergency_models.dart';
import '../../domain/repositories/emergency_repository.dart';

/// Adaptador Socket.IO — desacoplado del dominio de emergencias.
class SocketEmergencyRealtimeClient implements EmergencyRealtimeClient {
  SocketEmergencyRealtimeClient([ChatSocketService? socket])
      : _socket = socket ?? AppRealtime.chatSocket;

  final ChatSocketService _socket;

  @override
  Stream<EmergencyRequest> watchUpdates(String emergencyId) {
    return _socket.onEmergencyUpdated
        .where((payload) => _matchesId(payload, emergencyId))
        .map(_parseEmergency);
  }

  @override
  Stream<EmergencyLocationUpdate> watchLocation(String emergencyId) {
    return _socket.onEmergencyLocation
        .where((payload) => payload['emergencyRequestId']?.toString() == emergencyId)
        .map(EmergencyLocationUpdate.fromPayload);
  }

  @override
  Future<void> subscribe(String emergencyId) async {
    await AppRealtime.connectIfNeeded();
    _socket.joinEmergency(emergencyId);
  }

  @override
  Future<void> unsubscribe(String emergencyId) {
    _socket.leaveEmergency(emergencyId);
    return Future.value();
  }

  bool _matchesId(Map<String, dynamic> payload, String emergencyId) {
    final emergency = payload['emergency'];
    if (emergency is Map) {
      final id = emergency['id'] ?? emergency['_id'];
      return id?.toString() == emergencyId;
    }
    return false;
  }

  EmergencyRequest _parseEmergency(Map<String, dynamic> payload) {
    final emergency = payload['emergency'];
    if (emergency is Map<String, dynamic>) {
      return EmergencyRequest.fromJson(emergency);
    }
    return EmergencyRequest.fromJson(payload);
  }
}
