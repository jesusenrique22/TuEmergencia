import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/geo/geo_math.dart';
import '../../../../core/geo/geo_point.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_poi_style.dart';
import '../../../../core/maps/widgets/app_map_view.dart';
import '../../../../core/maps/widgets/map_poi_marker.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../catalog/domain/models/catalog_models.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../widgets/map_poi_filter_bar.dart';

class MedicalNetworkMapScreen extends StatefulWidget {
  const MedicalNetworkMapScreen({super.key});

  @override
  State<MedicalNetworkMapScreen> createState() => _MedicalNetworkMapScreenState();
}

class _MedicalNetworkMapScreenState extends State<MedicalNetworkMapScreen> {
  final MapController _mapController = MapController();
  final _catalog = sl<CatalogRepository>();

  bool _loading = true;
  String? _error;
  List<MapPoi> _pois = [];
  MapPoi? _selected;
  final Set<MapPoiType> _filters = {
    MapPoiType.clinic,
    MapPoiType.laboratory,
    MapPoiType.ambulance,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pois = await _catalog.listMapPois();
      if (!mounted) return;
      setState(() {
        _pois = pois;
        _loading = false;
      });
      _fitVisiblePois(pois);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _fitVisiblePois(List<MapPoi> pois) {
    if (pois.isEmpty) return;
    if (pois.length == 1) {
      _mapController.move(pois.first.location.latLng, MapConfig.defaultZoom);
      return;
    }
    var minLat = pois.first.location.latitude;
    var maxLat = minLat;
    var minLng = pois.first.location.longitude;
    var maxLng = minLng;
    for (final p in pois) {
      minLat = minLat < p.location.latitude ? minLat : p.location.latitude;
      maxLat = maxLat > p.location.latitude ? maxLat : p.location.latitude;
      minLng = minLng < p.location.longitude ? minLng : p.location.longitude;
      maxLng = maxLng > p.location.longitude ? maxLng : p.location.longitude;
    }
    final center = GeoMath.midpoint(
      GeoPoint(latitude: minLat, longitude: minLng),
      GeoPoint(latitude: maxLat, longitude: maxLng),
    );
    _mapController.move(center.latLng, MapConfig.defaultZoom);
  }

  List<MapPoi> get _visiblePois =>
      _pois.where((p) => _filters.contains(p.type)).toList();

  void _toggleFilter(MapPoiType type) {
    setState(() {
      if (_filters.contains(type)) {
        if (_filters.length > 1) _filters.remove(type);
      } else {
        _filters.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mapa de la red médica'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => AppNavigation.safeBack(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
                  ],
                ),
              ),
            )
          else
            AppMapView(
              controller: _mapController,
              initialCenter: MapConfig.defaultCenter,
              initialZoom: MapConfig.defaultZoom,
              layers: [
                MarkerLayer(
                  markers: _visiblePois.map((poi) {
                    final style = MapPoiStyle.forType(poi.type.apiValue);
                    return MapPoiMarker(
                      point: poi.location.latLng,
                      style: style,
                      pulsing: poi.type == MapPoiType.ambulance,
                      onTap: () => setState(() => _selected = poi),
                    ).toMarker();
                  }).toList(),
                ),
              ],
            ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: MapPoiFilterBar(
              selected: _filters,
              onToggle: _toggleFilter,
            ),
          ),
          Positioned(
            bottom: _selected != null ? 180 : 16,
            left: 16,
            right: 16,
            child: _MapLegend(filters: _filters),
          ),
          if (_selected != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildPoiSheet(_selected!),
            ),
        ],
      ),
    );
  }

  Widget _buildPoiSheet(MapPoi poi) {
    final style = MapPoiStyle.forType(poi.type.apiValue);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: style.color.withValues(alpha: 0.12),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(style.label, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selected = null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(poi.address, style: const TextStyle(color: AppColors.textSecondary)),
          if (poi.subtitle != null && poi.type == MapPoiType.ambulance) ...[
            const SizedBox(height: 6),
            Text('Conductor: ${poi.subtitle}'),
          ],
          if (poi.status != null && poi.type == MapPoiType.ambulance) ...[
            const SizedBox(height: 8),
            Chip(
              label: Text(_statusLabel(poi.status!)),
              backgroundColor: AppColors.primaryLight,
            ),
          ],
          if (poi.hasEmergencyRoom) ...[
            const SizedBox(height: 8),
            const Chip(
              label: Text('Urgencias 24/7'),
              backgroundColor: Color(0xFFFEE2E2),
              labelStyle: TextStyle(color: AppColors.emergency),
            ),
          ],
          if (poi.type == MapPoiType.clinic && poi.hasEmergencyRoom) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.ambulanceCheckout),
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('Solicitar ambulancia'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return 'Disponible';
      case 'DISPATCHED':
        return 'En servicio';
      case 'TRANSPORTING':
        return 'Trasladando paciente';
      default:
        return status;
    }
  }
}

class _MapLegend extends StatelessWidget {
  final Set<MapPoiType> filters;

  const _MapLegend({required this.filters});

  @override
  Widget build(BuildContext context) {
    final items = MapPoiType.values.where(filters.contains).map((type) {
      final style = MapPoiStyle.forType(type.apiValue);
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 16, color: style.color),
            const SizedBox(width: 4),
            Text(style.label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(children: items.toList()),
    );
  }
}
