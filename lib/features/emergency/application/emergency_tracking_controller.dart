import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/geo/geo_math.dart';
import '../../../core/geo/geo_point.dart';
import '../../../core/geo/route_service.dart';
import '../../../core/location/device_location_service.dart';
import '../../../core/services/app_realtime.dart';
import '../domain/emergency_navigation.dart';
import '../domain/models/emergency_models.dart';
import '../domain/repositories/emergency_repository.dart';

/// Orquesta tracking en vivo: REST + WebSocket + ruta + trazabilidad GPS.
class EmergencyTrackingController extends ChangeNotifier {
  EmergencyTrackingController({
    required EmergencyRepository repository,
    required EmergencyRealtimeClient realtime,
    RouteService? routeService,
  })  : _repository = repository,
        _realtime = realtime,
        _routeService = routeService ?? RouteService();

  final EmergencyRepository _repository;
  final EmergencyRealtimeClient _realtime;
  final RouteService _routeService;

  EmergencyRequest? emergency;
  String? error;
  bool loading = false;
  bool cancelling = false;
  bool routeLoading = false;

  /// Puntos GPS recorridos por la ambulancia (trazabilidad).
  final List<GeoPoint> locationTrail = [];
  List<GeoPoint> routePoints = [];
  double? distanceRemainingKm;
  double ambulanceBearing = 0;
  bool followAmbulance = true;

  StreamSubscription<EmergencyRequest>? _updateSub;
  StreamSubscription<EmergencyLocationUpdate>? _locationSub;
  Timer? _fallbackPoll;
  String? _routeKey;

  GeoPoint? get navigationDestination =>
      emergency == null ? null : EmergencyNavigation.destination(emergency!);

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
      _seedTrailFromEmergency();
      await AppRealtime.connectIfNeeded();
      await _realtime.subscribe(emergencyId);

      await _updateSub?.cancel();
      await _locationSub?.cancel();

      _updateSub = _realtime.watchUpdates(emergencyId).listen(_applyUpdate);
      _locationSub = _realtime.watchLocation(emergencyId).listen(_applyLocation);

      _fallbackPoll?.cancel();
      _fallbackPoll = Timer.periodic(const Duration(seconds: 12), (_) => _refreshSilent());

      unawaited(_refreshRoute(force: true));

      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  void setFollowAmbulance(bool value) {
    if (followAmbulance == value) return;
    followAmbulance = value;
    notifyListeners();
  }

  void _seedTrailFromEmergency() {
    final loc = emergency?.ambulanceLocation;
    if (loc != null && loc.isValid) {
      locationTrail
        ..clear()
        ..add(loc);
    }
  }

  Future<void> _refreshSilent() async {
    if (emergency == null) return;
    try {
      final prevStatus = emergency!.status;
      emergency = await _repository.getById(emergency!.id);
      if (prevStatus != emergency!.status) {
        unawaited(_refreshRoute(force: true));
      }
      _syncDistanceFromCurrent();
      notifyListeners();
    } catch (_) {}
  }

  void _applyUpdate(EmergencyRequest updated) {
    final prevStatus = emergency?.status;
    emergency = updated;
    if (prevStatus != updated.status) {
      unawaited(_refreshRoute(force: true));
    }
    if (updated.ambulanceLocation != null) {
      _appendTrailPoint(updated.ambulanceLocation!);
    }
    _syncDistanceFromCurrent();
    notifyListeners();
  }

  void _applyLocation(EmergencyLocationUpdate update) {
    if (emergency == null) return;
    if (update.isPatient) {
      emergency = emergency!.copyWith(
        origin: update.location,
        etaMinutes: update.etaMinutes ?? emergency!.etaMinutes,
      );
      final rawDist = update.distanceRemainingKm ??
          _distanceToDestination(emergency!.ambulanceLocation ?? update.location);
      distanceRemainingKm =
          rawDist != null && rawDist <= 120 ? rawDist : null;
      notifyListeners();
      return;
    }
    _appendTrailPoint(update.location);
    emergency = emergency!.copyWith(
      ambulanceLocation: update.location,
      etaMinutes: update.etaMinutes ?? emergency!.etaMinutes,
    );
    final rawDist =
        update.distanceRemainingKm ?? _distanceToDestination(update.location);
    distanceRemainingKm =
        rawDist != null && rawDist <= 120 ? rawDist : null;
    notifyListeners();
  }

  void _appendTrailPoint(GeoPoint point) {
    if (!point.isValid) return;
    if (locationTrail.isEmpty) {
      locationTrail.add(point);
      return;
    }
    final last = locationTrail.last;
    final movedKm = GeoMath.distanceKm(last, point);
    if (movedKm < 0.004) return;
    ambulanceBearing = GeoMath.bearingDegrees(last, point);
    locationTrail.add(point);
    if (locationTrail.length > 600) {
      locationTrail.removeRange(0, locationTrail.length - 600);
    }
    distanceRemainingKm = _distanceToDestination(point);
  }

  double? _distanceToDestination(GeoPoint from) {
    final dest = navigationDestination;
    if (dest == null) return null;
    return GeoMath.distanceKm(from, dest);
  }

  void _syncDistanceFromCurrent() {
    final loc = emergency?.ambulanceLocation;
    if (loc == null) return;
    distanceRemainingKm = _distanceToDestination(loc);
  }

  Future<void> _refreshRoute({bool force = false}) async {
    final em = emergency;
    if (em == null) return;

    final dest = EmergencyNavigation.destination(em);
    final from = em.ambulanceLocation ?? dest;
    final key = '${em.status.name}:${from.latitude},${from.longitude}->${dest.latitude},${dest.longitude}';
    if (!force && key == _routeKey) return;
    _routeKey = key;

    routeLoading = true;
    notifyListeners();

    final result = await _routeService.fetchDrivingRoute(from, dest);
    routePoints = result.points;
    if (result.distanceKm != null) {
      distanceRemainingKm = result.distanceKm;
    }
    if (result.etaMinutes != null && em.etaMinutes == null) {
      emergency = em.copyWith(etaMinutes: result.etaMinutes);
    }
    routeLoading = false;
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

/// Publica GPS del conductor al backend en tiempo real (alta frecuencia).
class DriverLocationPublisher {
  DriverLocationPublisher({
    required EmergencyRepository repository,
    required DeviceLocationService locationService,
    RouteService? routeService,
  })  : _repository = repository,
        _locationService = locationService,
        _routeService = routeService ?? RouteService();

  final EmergencyRepository _repository;
  final DeviceLocationService _locationService;
  final RouteService _routeService;

  StreamSubscription<GeoPoint>? _sub;
  Timer? _heartbeat;
  EmergencyRequest? _assignment;
  GeoPoint? _lastSent;

  Future<void> start(EmergencyRequest assignment) async {
    await stop();
    _assignment = assignment;

    _heartbeat = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final point = await _locationService.getCurrentPosition();
        await _publish(point, force: true);
      } catch (_) {}
    });

    _sub = _locationService
        .watchPosition(distanceFilterMeters: 8)
        .listen((point) async {
      await _publish(point);
    });
  }

  Future<void> _publish(GeoPoint point, {bool force = false}) async {
    final assignment = _assignment;
    if (assignment == null || !point.isValid) return;

    if (!force && _lastSent != null) {
      if (GeoMath.distanceKm(_lastSent!, point) < 0.008) return;
    }
    _lastSent = point;

    final dest = EmergencyNavigation.destination(assignment);
    var etaMinutes = GeoMath.estimateEtaMinutes(GeoMath.distanceKm(point, dest));

    try {
      final route = await _routeService.fetchDrivingRoute(point, dest);
      if (route.etaMinutes != null) etaMinutes = route.etaMinutes!;
    } catch (_) {}

    try {
      debugPrint(
        '[GPS] publicando ${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)} emergencia=${assignment.id}',
      );
      await _repository.updateDriverLocation(
        emergencyId: assignment.id,
        location: point,
        etaMinutes: etaMinutes,
      );
    } catch (e) {
      debugPrint('[GPS] error publicando: $e');
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _heartbeat?.cancel();
    _sub = null;
    _heartbeat = null;
    _assignment = null;
    _lastSent = null;
  }
}
