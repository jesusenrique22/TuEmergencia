import 'package:flutter/material.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/clinic_models.dart';
import '../../domain/models/clinic_data_mock.dart';

class ClinicNetworkScreen extends StatelessWidget {
  const ClinicNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Red de Clínicas Aliadas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => AppNavigation.safeBack(context),
        ),
      ),
      body: AppPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeroPanel(
              color: AppColors.primaryDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppStatusPill(
                    label: 'Red médica',
                    color: Colors.white,
                    icon: Icons.business_rounded,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Clínicas aliadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Encuentra centros con urgencias, seguros aceptados y capacidad de atención.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppSectionHeader(
              title: 'Hospitales y centros',
              subtitle:
                  '${ClinicDataMock.clinics.length} centros coordinados para admisión',
            ),
            const SizedBox(height: 16),
            ...ClinicDataMock.clinics.map(
              (clinic) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildClinicCard(context, clinic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicCard(BuildContext context, AlliedClinic clinic) {
    return AppMarketplaceTile(
      title: clinic.name,
      subtitle: clinic.location.address,
      imageUrl: clinic.logoUrl,
      icon: Icons.business_rounded,
      color: AppColors.primaryDark,
      actionLabel: 'Coordinar',
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
        AppStatusPill(
          label: '${clinic.acceptedInsurances.length} seguros',
          color: AppColors.secondary,
          icon: Icons.verified_user_rounded,
        ),
      ],
    );
  }
}
