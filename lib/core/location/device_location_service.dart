import 'package:geolocator/geolocator.dart';

import '../geo/geo_point.dart';
import '../maps/map_config.dart';

/// Abstracción del GPS del dispositivo — testeable y reutilizable.
abstract class DeviceLocationService {
  Future<GeoPoint> getCurrentPosition();
  Stream<GeoPoint> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 25,
  });
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  @override
  Future<GeoPoint> getCurrentPosition() async {
    await _ensurePermission();
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
    } catch (_) {
      return MapConfig.defaultCenter;
    }
  }

  @override
  Stream<GeoPoint> watchPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 25,
  }) async* {
    await _ensurePermission();
    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((p) => GeoPoint(latitude: p.latitude, longitude: p.longitude));
  }

  Future<void> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado');
    }
  }
}
