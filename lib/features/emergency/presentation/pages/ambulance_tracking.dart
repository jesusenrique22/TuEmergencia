import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/emergency_tracking_controller.dart';
import '../widgets/emergency_status_sheet.dart';
import '../widgets/emergency_tracking_map.dart';

class AmbulanceTracking extends StatefulWidget {
  final String emergencyId;
  const AmbulanceTracking({super.key, this.emergencyId = ''});

  @override
  State<AmbulanceTracking> createState() => _AmbulanceTrackingState();
}

class _AmbulanceTrackingState extends State<AmbulanceTracking> {
  late final EmergencyTrackingController _controller;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _controller = sl<EmergencyTrackingController>();
    _controller.addListener(_onChanged);
    unawaited(AppRealtime.connectIfNeeded());
    unawaited(_controller.start(widget.emergencyId));
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    await _controller.cancel();
    if (!mounted) return;
    AppNavigation.safeBack(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading && _controller.emergency == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_controller.error != null && _controller.emergency == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_controller.error!)),
      );
    }

    final emergency = _controller.emergency!;
    final driver = emergency.ambulance?.driver;

    return Stack(
      children: [
        EmergencyTrackingMap(
          controller: _mapController,
          request: emergency,
        ),
        Positioned(
          top: 40,
          left: 20,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => AppNavigation.safeBack(context),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: EmergencyStatusSheet(
            statusLabel: emergency.status.label,
            etaMinutes: emergency.etaMinutes ?? 5,
            driverName: driver?.name ?? 'Conductor asignado',
            unitLabel: emergency.ambulance?.displayName ?? '—',
            profilePic: driver?.profilePic,
            cancelling: _controller.cancelling,
            onCall: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Llamada a ${emergency.ambulance?.displayName ?? 'unidad'} (WebRTC próximamente)',
                  ),
                ),
              );
            },
            onCancel: _cancel,
          ),
        ),
      ],
    );
  }
}
