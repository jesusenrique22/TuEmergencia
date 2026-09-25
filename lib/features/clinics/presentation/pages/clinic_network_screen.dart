import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/experience/experience_marketplace_shell.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../../catalog/domain/models/catalog_models.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';

class ClinicNetworkScreen extends StatefulWidget {
  const ClinicNetworkScreen({super.key});

  @override
  State<ClinicNetworkScreen> createState() => _ClinicNetworkScreenState();
}

class _ClinicNetworkScreenState extends State<ClinicNetworkScreen> {
  final _catalog = sl<CatalogRepository>();
  List<MedicalFacility> _clinics = [];
  bool _loading = true;
  String? _error;

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
      final clinics = await _catalog.listActiveFacilities();
      if (!mounted) return;
      setState(() {
        _clinics = clinics;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExperienceMarketplaceShell(
      title: 'Clínicas aliadas',
      subtitle: 'Urgencias en Maracaibo, seguros y admisión coordinada.',
      badge: _loading ? '…' : '${_clinics.length} centros',
      icon: Icons.local_hospital_rounded,
      gradient: AppColors.clinicGradient,
      promos: PromoMockData.clinicPromos,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.medicalNetworkMap),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.map_rounded),
        label: const Text('Ver mapa'),
      ),
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(_error!, style: const TextStyle(color: AppColors.emergency)),
                TextButton(onPressed: _load, child: const Text('Reintentar')),
              ],
            ),
          )
        else if (_clinics.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay clínicas activas en Maracaibo. Actualiza la app o contacta soporte.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ..._clinics.map((clinic) => _buildClinicCard(context, clinic)),
      ],
    );
  }

  Widget _buildClinicCard(BuildContext context, MedicalFacility clinic) {
    return AppMarketplaceTile(
      title: clinic.name,
      subtitle: clinic.address.isNotEmpty
          ? clinic.address
          : (clinic.city ?? 'Maracaibo'),
      icon: Icons.business_rounded,
      color: AppColors.primary,
      actionLabel: 'Ver mapa',
      chips: [
        AppStatusPill(
          label: clinic.hasEmergencyRoom
              ? 'Emergencia 24/7'
              : 'Atención regular',
          color: clinic.hasEmergencyRoom ? AppColors.emergency : AppColors.info,
          icon: clinic.hasEmergencyRoom
              ? Icons.emergency_rounded
              : Icons.local_hospital_rounded,
        ),
      ],
      onTap: () => Navigator.pushNamed(context, AppRoutes.medicalNetworkMap),
    );
  }
}
