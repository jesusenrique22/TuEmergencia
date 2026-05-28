import 'package:flutter/material.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/radiology_models.dart';
import '../../domain/models/radiology_data_mock.dart';
import 'radiology_detail_screen.dart';

class RadiologyMarketplaceScreen extends StatelessWidget {
  const RadiologyMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Radiología e Imágenes'),
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
              color: AppColors.info,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppStatusPill(
                    label: 'Imagenología',
                    color: Colors.white,
                    icon: Icons.image_search_rounded,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Radiología e imágenes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Agenda rayos X, ecos, resonancias y estudios especializados con centros aliados.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppSectionHeader(
              title: 'Centros de imagenología',
              subtitle:
                  '${RadiologyDataMock.centers.length} centros disponibles para reservar',
            ),
            const SizedBox(height: 16),
            ...RadiologyDataMock.centers.map(
              (center) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildCenterCard(context, center),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterCard(BuildContext context, RadiologyCenter center) {
    return AppMarketplaceTile(
      title: center.name,
      subtitle: center.hasMRI
          ? 'Estudios avanzados con resonancia magnética y diagnóstico digital.'
          : 'Rayos X, ecos y estudios de imagen ambulatorios.',
      imageUrl: center.logoUrl,
      icon: Icons.image_search_rounded,
      color: AppColors.info,
      chips: [
        AppStatusPill(
          label: center.hasMRI ? 'MRI disponible' : 'Rayos X / Ecos',
          color: center.hasMRI ? AppColors.accent : AppColors.info,
          icon: center.hasMRI
              ? Icons.monitor_heart_rounded
              : Icons.medical_information_rounded,
        ),
      ],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RadiologyDetailScreen(center: center),
        ),
      ),
    );
  }
}
