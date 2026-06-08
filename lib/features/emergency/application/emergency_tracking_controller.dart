import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/geo/geo_point.dart';
import '../../../core/location/device_location_service.dart';
import '../../../core/services/app_realtime.dart';
import '../domain/models/emergency_models.dart';
import '../domain/repositories/emergency_repository.dart';

/// Orquesta tracking en vivo: carga inicial REST + actualizaciones WebSocket.
class EmergencyTrackingController extends ChangeNotifier {
  EmergencyTrackingController({
    required EmergencyRepository repository,
    required EmergencyRealtimeClient realtime,
  })  : _repository = repository,
        _realtime = realtime;

  final EmergencyRepository _repository;
  final EmergencyRealtimeClient _realtime;

  EmergencyRequest? emergency;
  String? error;
  bool loading = false;
  bool cancelling = false;

  StreamSubscription<EmergencyRequest>? _updateSub;
  StreamSubscription<EmergencyLocationUpdate>? _locationSub;
  Timer? _fallbackPoll;

  Future<void> start(String emergencyId) async {
    if (emergencyId.isEmpty) {
      error = 'Sin ID de emergencia';
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      emergency = await _repository.getById(emergencyId);
      await AppRealtime.connectIfNeeded();
      await _realtime.subscribe(emergencyId);

      await _updateSub?.cancel();
      await _locationSub?.cancel();

      _updateSub = _realtime.watchUpdates(emergencyId).listen(_applyUpdate);
      _locationSub = _realtime.watchLocation(emergencyId).listen(_applyLocation);

      _fallbackPoll?.cancel();
      _fallbackPoll = Timer.periodic(const Duration(seconds: 30), (_) => _refreshSilent());

      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _refreshSilent() async {
    if (emergency == null) return;
    try {
      emergency = await _repository.getById(emergency!.id);
      notifyListeners();
    } catch (_) {}
  }

  void _applyUpdate(EmergencyRequest updated) {
    emergency = updated;
    notifyListeners();
  }

  void _applyLocation(EmergencyLocationUpdate update) {
    if (emergency == null) return;
    emergency = emergency!.copyWith(
      ambulanceLocation: update.location,
      etaMinutes: update.etaMinutes ?? emergency!.etaMinutes,
    );
    notifyListeners();
  }

  Future<void> cancel() async {
    if (emergency == null) return;
    cancelling = true;
    notifyListeners();
    try {
      emergency = await _repository.cancel(emergency!.id);
    } finally {
      cancelling = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final id = emergency?.id;
    if (id != null) {
      _realtime.unsubscribe(id);
    }
    _updateSub?.cancel();
    _locationSub?.cancel();
    _fallbackPoll?.cancel();
    super.dispose();
  }
}

/// Publica GPS del conductor al backend en tiempo real.
class DriverLocationPublisher {
  DriverLocationPublisher({
    required EmergencyRepository repository,
    required DeviceLocationService locationService,
  })  : _repository = repository,
        _locationService = locationService;

  final EmergencyRepository _repository;
  final DeviceLocationService _locationService;

  StreamSubscription<GeoPoint>? _sub;

  Future<void> start(EmergencyRequest assignment) async {
    await stop();
    _sub = _locationService
        .watchPosition(distanceFilterMeters: 20)
        .listen((point) async {
      try {
        await _repository.updateDriverLocation(
          emergencyId: assignment.id,
          location: point,
        );
      } catch (_) {}
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
