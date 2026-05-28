import 'package:flutter/material.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/laboratory_models.dart';
import '../../domain/models/lab_data_mock.dart';
import 'lab_detail_screen.dart';

class LabMarketplaceScreen extends StatelessWidget {
  const LabMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laboratorios Clínicos'),
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
              color: AppColors.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppStatusPill(
                    label: 'Diagnóstico clínico',
                    color: Colors.white,
                    icon: Icons.science_rounded,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Laboratorios aliados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Reserva exámenes, compara servicios y encuentra opciones a domicilio o en sede.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppSectionHeader(
              title: 'Centros disponibles',
              subtitle:
                  '${LabDataMock.laboratories.length} laboratorios conectados a VITA OS',
            ),
            const SizedBox(height: 16),
            ...LabDataMock.laboratories.map(
              (lab) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildLabCard(context, lab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabCard(BuildContext context, Laboratory lab) {
    return AppMarketplaceTile(
      title: lab.name,
      subtitle: lab.offersHomeService
          ? 'Toma de muestras a domicilio y atención en sede.'
          : 'Atención en sede con resultados digitales.',
      imageUrl: lab.logoUrl,
      icon: Icons.science_rounded,
      color: AppColors.accent,
      chips: [
        AppStatusPill(
          label: lab.offersHomeService ? 'Domicilio' : 'En sede',
          color: lab.offersHomeService ? AppColors.secondary : AppColors.info,
          icon: lab.offersHomeService
              ? Icons.home_work_rounded
              : Icons.location_city_rounded,
        ),
      ],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LabDetailScreen(laboratory: lab),
        ),
      ),
    );
  }
}
