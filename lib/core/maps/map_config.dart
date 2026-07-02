import '../geo/geo_point.dart';

/// Configuración central del mapa (flutter_map ≈ Leaflet, tiles gratuitos OSM).
///
/// No requiere API key ni facturación. Para producción a gran escala considera
/// un tile server propio; para desarrollo/MVP OpenStreetMap es suficiente.
class MapConfig {
  MapConfig._();

  /// Tiles OpenStreetMap — uso gratuito con política de uso razonable.
  static const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Alternativa gratuita (sin key): Carto Positron CDN.
  static const cartoLightTileUrl =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

  static const userAgentPackageName = 'com.tuemergencia.app';

  /// Centro por defecto (Caracas) cuando no hay GPS ni POIs.
  static const defaultCenter = GeoPoint(latitude: 10.4806, longitude: -66.9036);

  static const defaultZoom = 12.0;
  static const trackingZoom = 14.0;
}
