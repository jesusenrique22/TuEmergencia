import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/geo/geo_math.dart';
import '../../../../core/geo/geo_point.dart';
import '../../../../core/location/device_location_service.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../catalog/domain/models/catalog_models.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../../../insurance/domain/services/insurance_calculator.dart';
import '../../../emergency/domain/models/emergency_models.dart';
import '../../../emergency/domain/repositories/emergency_repository.dart';

class AmbulanceCheckoutScreen extends StatefulWidget {
  const AmbulanceCheckoutScreen({super.key});

  @override
  State<AmbulanceCheckoutScreen> createState() =>
      _AmbulanceCheckoutScreenState();
}

class _AmbulanceCheckoutScreenState extends State<AmbulanceCheckoutScreen> {
  final _catalog = sl<CatalogRepository>();
  final _emergency = sl<EmergencyRepository>();
  final _location = sl<DeviceLocationService>();

  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();

  List<MedicalFacility> _facilities = [];
  MedicalFacility? _selectedClinic;
  double _painLevel = 5;
  bool _loadingFacilities = true;
  bool _loadingLocation = true;
  bool _isRequesting = false;
  String? _locationError;
  GeoPoint? _origin;

  static const _baseFare = 25.0;
  static const _perKmRate = 2.5;

  @override
  void initState() {
    super.initState();
    _loadFacilities();
    _resolveLocation();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _loadFacilities() async {
    try {
      final clinics = await _catalog.listEmergencyFacilities();
      if (!mounted) return;
      setState(() {
        _facilities = clinics;
        _loadingFacilities = false;
        if (clinics.isNotEmpty) _selectedClinic = clinics.first;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFacilities = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar clínicas: $e')),
      );
    }
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final point = await _location.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _origin = point;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString();
        _loadingLocation = false;
      });
    }
  }

  double get _estimatedDistance {
    final clinic = _selectedClinic?.location;
    if (clinic == null || _origin == null) return 5;
    return GeoMath.distanceKm(_origin!, clinic);
  }

  double _calculateFare() {
    if (_selectedClinic == null) return 0;
    return _baseFare + (_estimatedDistance * _perKmRate);
  }

  Future<void> _requestAmbulance() async {
    if (_selectedClinic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una clínica de destino')),
      );
      return;
    }
    if (_origin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando tu ubicación...')),
      );
      return;
    }

    setState(() => _isRequesting = true);
    try {
      final result = await _emergency.create(
        CreateEmergencyParams(
          facilityId: _selectedClinic!.id,
          origin: _origin!,
          originAddress: _origin.toString(),
          symptoms: _symptomsController.text.trim(),
          painLevel: _painLevel.round(),
          medicalHistory: _historyController.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() => _isRequesting = false);
      _showSuccessDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showSuccessDialog(EmergencyRequest emergency) {
    final unit = emergency.ambulance?.displayName ?? 'ambulancia';
    final clinic = emergency.facility?.name ?? _selectedClinic?.name ?? 'clínica';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text('¡Unidad asignada!', textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'La unidad $unit va en camino con destino a $clinic.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(this.context).pushReplacementNamed(
                AppRoutes.tracking,
                arguments: {'emergencyId': emergency.id},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text(
              'VER SEGUIMIENTO',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Solicitar ambulancia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => AppNavigation.safeBack(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Mapa de la red',
            icon: const Icon(Icons.map_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.medicalNetworkMap),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _step('1', 'Tu ubicación'),
            const SizedBox(height: 12),
            _locationCard(),
            const SizedBox(height: 28),
            _step('2', 'Clínica de destino'),
            const SizedBox(height: 12),
            _clinicSelector(),
            const SizedBox(height: 28),
            _step('3', 'Motivo de la emergencia'),
            const SizedBox(height: 12),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Síntomas principales...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _painSlider(),
            const SizedBox(height: 16),
            TextField(
              controller: _historyController,
              decoration: InputDecoration(
                labelText: 'Antecedentes médicos',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _step('4', 'Resumen de cotización'),
            const SizedBox(height: 12),
            _priceSummary(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (_isRequesting || _loadingLocation) ? null : _requestAmbulance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergency,
                minimumSize: const Size(double.infinity, 60),
              ),
              child: _isRequesting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'CONFIRMAR SOLICITUD',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String n, String title) => Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(n, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _locationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(_loadingLocation ? Icons.gps_not_fixed : Icons.gps_fixed, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _loadingLocation
                  ? 'Obteniendo ubicación...'
                  : (_locationError != null
                      ? 'Error de ubicación: $_locationError'
                      : (_origin?.toString() ?? 'Sin ubicación')),
              style: TextStyle(
                color: _locationError != null ? AppColors.emergency : null,
              ),
            ),
          ),
          if (!_loadingLocation)
            IconButton(onPressed: _resolveLocation, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
    );
  }

  Widget _clinicSelector() {
    if (_loadingFacilities) return const Center(child: CircularProgressIndicator());
    if (_facilities.isEmpty) return const Text('No hay clínicas con urgencias.');
    return DropdownButtonFormField<MedicalFacility>(
      initialValue: _selectedClinic,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: _facilities
          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
          .toList(),
      onChanged: (v) => setState(() => _selectedClinic = v),
    );
  }

  Widget _painSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nivel de dolor', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _painLevel,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (v) => setState(() => _painLevel = v),
          ),
          Center(child: Text('${_painLevel.round()} / 10')),
        ],
      ),
    );
  }

  Widget _priceSummary() {
    final subtotal = _calculateFare();
    if (subtotal == 0) return const SizedBox.shrink();
    final breakdown = InsuranceCalculator.calculateCopay(subtotal: subtotal, category: 'ambulance');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('Copago estimado: \$${breakdown['totalToPay']!.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(
            'Distancia ~${_estimatedDistance.toStringAsFixed(1)} km',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
