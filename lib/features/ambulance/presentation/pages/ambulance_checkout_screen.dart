import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/geo/geo_math.dart';
import '../../../../core/geo/geo_point.dart';
import '../../../../core/location/device_location_service.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../catalog/domain/models/catalog_models.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../../../insurance/domain/services/insurance_calculator.dart';
import '../../../insurance/domain/models/insurance_models.dart';
import '../../../insurance/domain/services/insurance_api_service.dart';
import '../../../emergency/domain/models/emergency_models.dart';
import '../../../emergency/domain/repositories/emergency_repository.dart';

class AmbulanceCheckoutScreen extends StatefulWidget {
  const AmbulanceCheckoutScreen({super.key});

  @override
  State<AmbulanceCheckoutScreen> createState() =>
      _AmbulanceCheckoutScreenState();
}

class _AmbulanceCheckoutScreenState extends State<AmbulanceCheckoutScreen>
    with TickerProviderStateMixin {
  final _catalog = sl<CatalogRepository>();
  final _emergency = sl<EmergencyRepository>();
  final _location = sl<DeviceLocationService>();

  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();

  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  List<MedicalFacility> _facilities = [];
  MedicalFacility? _selectedClinic;
  double _painLevel = 5;
  bool _loadingFacilities = true;
  bool _loadingLocation = true;
  bool _isRequesting = false;
  String? _locationError;
  GeoPoint? _origin;
  String _selectedPaymentMethod = 'PAGO_MOVIL';
  PatientPolicy? _activePolicy;

  static const _baseFare = 25.0;
  static const _perKmRate = 2.5;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _loadFacilities();
    _resolveLocation();
    _loadActivePolicy();
  }

  void _loadActivePolicy() async {
    try {
      final policy = await InsuranceApiService.instance.getMyPolicy();
      if (mounted) {
        setState(() {
          _activePolicy = policy;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
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
    if (clinic == null || _origin == null) return 5.0;
    final dist = GeoMath.distanceKm(_origin!, clinic);
    if (dist > 100.0) return 8.4;
    return dist;
  }

  double _calculateFare() {
    if (_selectedClinic == null) return 0;
    return _baseFare + (_estimatedDistance * _perKmRate);
  }

  Future<void> _requestAmbulance() async {
    if (_selectedClinic == null) {
      _showError('Selecciona una clínica de destino');
      return;
    }
    if (_origin == null) {
      _showError('Esperando tu ubicación...');
      return;
    }

    setState(() => _isRequesting = true);
    try {
      final subtotal = _calculateFare();
      final breakdown = InsuranceCalculator.calculateCopay(
        subtotal: subtotal,
        category: 'ambulance',
        policy: _activePolicy,
      );

      final result = await _emergency.create(
        CreateEmergencyParams(
          facilityId: _selectedClinic!.id,
          origin: _origin!,
          originAddress: _origin.toString(),
          symptoms: _symptomsController.text.trim(),
          painLevel: _painLevel.round(),
          medicalHistory: _historyController.text.trim(),
          paymentMethod: _selectedPaymentMethod,
        ),
      );

      if (_activePolicy != null) {
        try {
          await InsuranceApiService.instance.createInvoice(
            requestId: result.id,
            insuranceId: _activePolicy!.insuranceId,
            subtotal: subtotal,
            coveredAmount: breakdown['coveredAmount'] ?? 0.0,
            copayAmount: breakdown['totalToPay'] ?? subtotal,
            status: 'PENDING',
          );
        } catch (invoiceErr) {
          debugPrint('Error creating insurance invoice: $invoiceErr');
        }
      }

      if (!mounted) return;
      setState(() => _isRequesting = false);
      _showSuccessDialog(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.emergency,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog(EmergencyRequest emergency) {
    final clinic = emergency.facility?.name ?? _selectedClinic?.name ?? 'clínica';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Solicitud enviada!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Buscando ambulancia disponible para llevarte a $clinic. Recibirás actualizaciones en tiempo real.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(this.context).pushReplacementNamed(
                      AppRoutes.tracking,
                      arguments: {'emergencyId': emergency.id},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'VER EN TIEMPO REAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _painColor {
    if (_painLevel <= 3) return Colors.green;
    if (_painLevel <= 6) return Colors.orange;
    return AppColors.emergency;
  }

  String get _painEmoji {
    if (_painLevel <= 2) return '😊';
    if (_painLevel <= 4) return '😐';
    if (_painLevel <= 6) return '😣';
    if (_painLevel <= 8) return '😖';
    return '😭';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildHeroAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildLocationSection(),
                    const SizedBox(height: 20),
                    _buildClinicSection(),
                    const SizedBox(height: 20),
                    _buildSymptomsSection(),
                    const SizedBox(height: 20),
                    _buildPainSection(),
                    const SizedBox(height: 20),
                    _buildHistorySection(),
                    const SizedBox(height: 20),
                    _buildPricingSection(),
                    const SizedBox(height: 20),
                    _buildPaymentSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildHeroAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.emergency,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        ),
        onPressed: () => AppNavigation.safeBack(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.medicalNetworkMap),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Animated pulse circles
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _PulsePainter(_pulseController.value),
                );
              },
            ),
            // Content
            Positioned(
              bottom: 20,
              left: 20,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.local_hospital_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'SOS MÉDICO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Solicitar\nAmbulancia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            // Ambulance icon
            Positioned(
              bottom: 10,
              right: 20,
              child: Text(
                '🚑',
                style: TextStyle(fontSize: 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildSectionCard(
      title: 'Tu ubicación',
      icon: Icons.my_location_rounded,
      iconColor: AppColors.info,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _locationError != null
                ? AppColors.emergency.withValues(alpha: 0.3)
                : AppColors.info.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _loadingLocation
                      ? Colors.orange
                      : _locationError != null
                          ? AppColors.emergency
                          : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (_loadingLocation ? Colors.orange : AppColors.primary)
                          .withValues(alpha: 0.4 + 0.3 * _pulseController.value),
                      blurRadius: 8 + 4 * _pulseController.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _loadingLocation
                    ? 'Obteniendo tu ubicación GPS...'
                    : (_locationError != null
                        ? 'Error: $_locationError'
                        : (_origin?.toString() ?? 'Sin ubicación detectada')),
                style: TextStyle(
                  fontSize: 13,
                  color: _locationError != null ? AppColors.emergency : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            if (!_loadingLocation)
              GestureDetector(
                onTap: _resolveLocation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: AppColors.info, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicSection() {
    return _buildSectionCard(
      title: 'Clínica de destino',
      icon: Icons.local_hospital_rounded,
      iconColor: AppColors.emergency,
      child: _loadingFacilities
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          : _facilities.isEmpty
              ? _buildNoClinicWarning()
              : Column(
                  children: [
                    // Clinic cards
                    ...List.generate(
                      math.min(_facilities.length, 4),
                      (i) {
                        final clinic = _facilities[i];
                        final isSelected = _selectedClinic?.id == clinic.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedClinic = clinic),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.emergency.withValues(alpha: 0.08)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.emergency
                                    : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.emergency.withValues(alpha: 0.15)
                                        : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.local_hospital_rounded,
                                    size: 18,
                                    color: isSelected ? AppColors.emergency : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clinic.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSelected
                                              ? AppColors.emergency
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      if (clinic.address.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          clinic.address,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.emergency,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (_facilities.length > 4) ...[
                      // Show dropdown for remaining
                      const SizedBox(height: 4),
                      DropdownButtonFormField<MedicalFacility>(
                        value: _facilities.indexOf(_selectedClinic ?? _facilities.first) >= 4
                            ? _selectedClinic
                            : null,
                        hint: const Text('Más clínicas...'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _facilities
                            .skip(4)
                            .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedClinic = v),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildNoClinicWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sin clínicas disponibles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No hay clínicas con urgencias registradas en el sistema. Contacta al administrador.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsSection() {
    return _buildSectionCard(
      title: '¿Qué sientes?',
      icon: Icons.sick_rounded,
      iconColor: AppColors.warning,
      child: TextField(
        controller: _symptomsController,
        maxLines: 3,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Describe tus síntomas: dolor, dificultad para respirar, mareos...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildPainSection() {
    return _buildSectionCard(
      title: 'Nivel de dolor',
      icon: Icons.favorite_rounded,
      iconColor: _painColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_painEmoji  ${_painLevel.round()} / 10',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _painColor,
                ),
              ),
              Text(
                _painLevel <= 3
                    ? 'Leve'
                    : _painLevel <= 6
                        ? 'Moderado'
                        : _painLevel <= 8
                            ? 'Intenso'
                            : 'Crítico',
                style: TextStyle(
                  fontSize: 13,
                  color: _painColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _painColor,
              thumbColor: _painColor,
              overlayColor: _painColor.withValues(alpha: 0.2),
              inactiveTrackColor: _painColor.withValues(alpha: 0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _painLevel,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _painLevel = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sin dolor', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              Text('Insoportable', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return _buildSectionCard(
      title: 'Antecedentes médicos',
      icon: Icons.medical_information_rounded,
      iconColor: AppColors.secondary,
      child: TextField(
        controller: _historyController,
        maxLines: 2,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Ej: Diabetes, hipertensión, alergias a medicamentos...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.secondary, width: 2),
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    if (_selectedClinic == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Selecciona una clínica para ver el precio estimado del servicio.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final subtotal = _calculateFare();
    Map<String, double>? breakdown;
    try {
      breakdown = InsuranceCalculator.calculateCopay(
        subtotal: subtotal,
        category: 'ambulance',
        policy: _activePolicy,
      );
    } catch (_) {}

    final dist = _estimatedDistance;
    final basePrice = _baseFare;
    final distancePrice = dist * _perKmRate;
    final covered = breakdown?['coveredAmount'] ?? 0.0;
    final total = breakdown?['totalToPay'] ?? subtotal;
    final percentage = ((breakdown?['percentage'] ?? 0.0) * 100).round();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estimación del servicio',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '~${dist.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          // Rows
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _darkPriceRow(
                  icon: Icons.airport_shuttle_rounded,
                  label: 'Tarifa base SOS',
                  value: '\$${basePrice.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _darkPriceRow(
                  icon: Icons.route_rounded,
                  label: 'Costo por distancia',
                  value: '\$${distancePrice.toStringAsFixed(2)}',
                ),
                if (covered > 0) ...[
                  const SizedBox(height: 12),
                  _darkPriceRow(
                    icon: Icons.health_and_safety_rounded,
                    label: 'Seguro cubre ($percentage%)',
                    value: '-\$${covered.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF4ADE80),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tu copago',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Disclaimer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              '* Precio estimado. El valor final puede variar según el recorrido real.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkPriceRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white70,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final methods = [
      {'id': 'PAGO_MOVIL', 'label': 'Pago\nMóvil', 'icon': Icons.phone_android_rounded, 'emoji': '📱'},
      {'id': 'CASH', 'label': 'Efectivo', 'icon': Icons.payments_rounded, 'emoji': '💵'},
      {'id': 'CARD', 'label': 'Tarjeta', 'icon': Icons.credit_card_rounded, 'emoji': '💳'},
      {'id': 'INSURANCE', 'label': 'Seguro', 'icon': Icons.health_and_safety_rounded, 'emoji': '🛡️'},
    ];

    return _buildSectionCard(
      title: 'Método de pago',
      icon: Icons.wallet_rounded,
      iconColor: AppColors.primary,
      child: Row(
        children: methods.map((m) {
          final isSelected = _selectedPaymentMethod == m['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = m['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m['emoji'] as String, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      m['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedClinic != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total estimado',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Builder(builder: (context) {
                  final subtotal = _calculateFare();
                  double total = subtotal;
                  try {
                    final b = InsuranceCalculator.calculateCopay(
                      subtotal: subtotal,
                      category: 'ambulance',
                      policy: _activePolicy,
                    );
                    total = b['totalToPay'] ?? subtotal;
                  } catch (_) {}
                  return Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_isRequesting || _loadingLocation || _facilities.isEmpty) ? null : _requestAmbulance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergency,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: _isRequesting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'PEDIR AMBULANCIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated pulse rings in the hero header.
class _PulsePainter extends CustomPainter {
  final double animValue;
  _PulsePainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final progress = (animValue + i * 0.33) % 1.0;
      final radius = 20.0 + progress * 80.0;
      final opacity = (1.0 - progress) * 0.15;
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.animValue != animValue;
}
