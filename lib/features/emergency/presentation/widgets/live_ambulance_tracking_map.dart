import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/geo_math.dart';
import '../../../../core/geo/geo_point.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/widgets/app_map_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/emergency_navigation.dart';
import '../../domain/models/emergency_models.dart';

/// Mapa en vivo estilo delivery (Yummy/Ridery): ruta, trazabilidad y marcadores animados.
class LiveAmbulanceTrackingMap extends StatefulWidget {
  const LiveAmbulanceTrackingMap({
    super.key,
    required this.request,
    required this.trail,
    required this.routePoints,
    this.distanceRemainingKm,
    this.ambulanceBearing = 0,
    this.followAmbulance = true,
    this.isDriverView = false,
    this.onFollowChanged,
    this.mapController,
  });

  final EmergencyRequest request;
  final List<GeoPoint> trail;
  final List<GeoPoint> routePoints;
  final double? distanceRemainingKm;
  final double ambulanceBearing;
  final bool followAmbulance;
  final bool isDriverView;
  final ValueChanged<bool>? onFollowChanged;
  final MapController? mapController;

  @override
  State<LiveAmbulanceTrackingMap> createState() =>
      _LiveAmbulanceTrackingMapState();
}

class _LiveAmbulanceTrackingMapState extends State<LiveAmbulanceTrackingMap>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final AnimationController _ambulanceMoveController;

  GeoPoint? _displayAmbulance;
  GeoPoint? _targetAmbulance;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _ambulanceMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_onAmbulanceAnimTick);

    _displayAmbulance = widget.request.ambulanceLocation;
    _targetAmbulance = _displayAmbulance;
  }

  @override
  void didUpdateWidget(LiveAmbulanceTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLoc = widget.request.ambulanceLocation;
    if (newLoc != null &&
        newLoc.isValid &&
        (_targetAmbulance == null ||
            GeoMath.distanceKm(_targetAmbulance!, newLoc) > 0.0001)) {
      _targetAmbulance = newLoc;
      _ambulanceMoveController.forward(from: 0);
    }

    if (widget.followAmbulance && newLoc != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _followCamera(newLoc));
    } else if (oldWidget.routePoints.length != widget.routePoints.length ||
        oldWidget.request.status != widget.request.status) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitAllPoints());
    }
  }

  void _onAmbulanceAnimTick() {
    final from = _displayAmbulance;
    final to = _targetAmbulance;
    if (from == null || to == null) return;
    final t = Curves.easeInOut.transform(_ambulanceMoveController.value);
    setState(() {
      _displayAmbulance = GeoPoint(
        latitude: from.latitude + (to.latitude - from.latitude) * t,
        longitude: from.longitude + (to.longitude - from.longitude) * t,
      );
    });
    if (_ambulanceMoveController.isCompleted) {
      _displayAmbulance = to;
    }
  }

  void _followCamera(GeoPoint center) {
    if (!mounted) return;
    _mapController.move(center.latLng, MapConfig.trackingZoom + 0.5);
  }

  void _fitAllPoints() {
    if (!mounted) return;
    final points = <LatLng>[];
    points.add(widget.request.origin.latLng);
    final dest = EmergencyNavigation.destination(widget.request);
    if (dest.isValid) points.add(dest.latLng);
    if (_displayAmbulance != null) points.add(_displayAmbulance!.latLng);
    for (final p in widget.trail) {
      points.add(p.latLng);
    }
    for (final p in widget.routePoints) {
      points.add(p.latLng);
    }
    if (points.length < 2) {
      _mapController.move(points.first, MapConfig.trackingZoom);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(48, 120, 48, 280),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ambulanceMoveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = EmergencyNavigation.destination(widget.request);
    final toClinic = EmergencyNavigation.routesToClinic(widget.request.status);
    final ambulance = _displayAmbulance ?? widget.request.ambulanceLocation;
    final patient = widget.request.origin;

    final markers = <Marker>[
      if (patient.isValid)
        _destinationMarker(
          point: patient,
          label: 'Paciente',
          icon: Icons.person_pin_circle_rounded,
          color: AppColors.emergency,
        ),
      if (toClinic)
        _destinationMarker(
          point: destination,
          label: 'Clínica',
          icon: Icons.local_hospital_rounded,
          color: AppColors.primary,
        ),
    ];

    if (ambulance != null && ambulance.isValid) {
      markers.add(
        Marker(
          point: ambulance.latLng,
          width: 64,
          height: 64,
          child: _AmbulanceMarker(
            bearing: widget.ambulanceBearing,
            pulse: _pulseController,
          ),
        ),
      );
    }

    final layers = <Widget>[];

    if (widget.routePoints.length >= 2) {
      layers.add(
        PolylineLayer(
          polylines: [
            Polyline(
              points: widget.routePoints.map((p) => p.latLng).toList(),
              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
              strokeWidth: 8,
              borderColor: Colors.white.withValues(alpha: 0.6),
              borderStrokeWidth: 2,
            ),
            Polyline(
              points: widget.routePoints.map((p) => p.latLng).toList(),
              color: const Color(0xFF2563EB),
              strokeWidth: 4,
            ),
          ],
        ),
      );
    }

    if (widget.trail.length >= 2) {
      layers.add(
        PolylineLayer(
          polylines: [
            Polyline(
              points: widget.trail.map((p) => p.latLng).toList(),
              color: AppColors.primary.withValues(alpha: 0.85),
              strokeWidth: 5,
              borderColor: Colors.white,
              borderStrokeWidth: 1.5,
            ),
          ],
        ),
      );
    }

    layers.add(MarkerLayer(markers: markers));

    final dist = widget.distanceRemainingKm;
    final int? eta = dist != null && dist <= 120
        ? GeoMath.estimateEtaMinutes(dist)
        : (widget.request.etaMinutes != null && widget.request.etaMinutes! < 180
            ? widget.request.etaMinutes
            : null);

    return Stack(
      children: [
        AppMapView(
          controller: _mapController,
          initialCenter: destination.isValid ? destination : widget.request.origin,
          initialZoom: MapConfig.trackingZoom,
          layers: layers,
        ),
        if (eta != null || dist != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 16,
            right: 16,
            child: _NavigationBanner(
              etaMinutes: eta,
              distanceKm: dist,
              label: EmergencyNavigation.destinationHint(widget.request),
              isDriverView: widget.isDriverView,
            ),
          ),
        Positioned(
          right: 16,
          bottom: widget.isDriverView ? 24 : 16,
          child: Column(
            children: [
              _MapFab(
                icon: widget.followAmbulance
                    ? Icons.gps_fixed_rounded
                    : Icons.gps_not_fixed_rounded,
                tooltip: widget.followAmbulance ? 'Siguiendo unidad' : 'Seguir unidad',
                selected: widget.followAmbulance,
                onTap: () {
                  final next = !widget.followAmbulance;
                  widget.onFollowChanged?.call(next);
                  if (next && ambulance != null) _followCamera(ambulance);
                },
              ),
              const SizedBox(height: 10),
              _MapFab(
                icon: Icons.zoom_out_map_rounded,
                tooltip: 'Ver ruta completa',
                onTap: _fitAllPoints,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Marker _destinationMarker({
    required GeoPoint point,
    required String label,
    required IconData icon,
    required Color color,
    double size = 44,
  }) {
    return Marker(
      point: point.latLng,
      width: size + 20,
      height: size + 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Icon(icon, color: color, size: size),
        ],
      ),
    );
  }
}

class _AmbulanceMarker extends StatelessWidget {
  const _AmbulanceMarker({
    required this.bearing,
    required this.pulse,
  });

  final double bearing;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final scale = 1 + pulse.value * 0.35;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergency.withValues(alpha: 0.18),
                ),
              ),
            ),
            Transform.rotate(
              angle: bearing * math.pi / 180,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emergency, width: 3),
                  
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.emergency,
                  size: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NavigationBanner extends StatelessWidget {
  const _NavigationBanner({
    required this.label,
    this.etaMinutes,
    this.distanceKm,
    this.isDriverView = false,
  });

  final String label;
  final int? etaMinutes;
  final double? distanceKm;
  final bool isDriverView;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDriverView
                      ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                      : AppColors.headerGradient,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDriverView ? Icons.navigation_rounded : Icons.timer_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    etaMinutes != null
                        ? 'Llegada ~ ${GeoMath.formatEta(etaMinutes)}'
                        : (distanceKm == null || distanceKm! > 120)
                            ? 'Ubicación lejos — GPS en Maracaibo'
                            : 'Calculando ETA…',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (distanceKm != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    GeoMath.formatDistance(distanceKm!),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'restantes',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      shape: CircleBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      color: selected ? AppColors.primary : Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: selected ? Colors.white : AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
