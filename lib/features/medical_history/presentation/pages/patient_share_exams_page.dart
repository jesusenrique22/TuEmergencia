import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../widgets/medical_documents_section.dart';

/// Pantalla dedicada para que el paciente suba laboratorio, radiografías, etc.
/// y el médico los vea en el historial clínico.
class PatientShareExamsPage extends StatefulWidget {
  const PatientShareExamsPage({super.key});

  @override
  State<PatientShareExamsPage> createState() => _PatientShareExamsPageState();
}

class _PatientShareExamsPageState extends State<PatientShareExamsPage> {
  int _listGeneration = 0;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: const Text('Compartir exámenes'),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _listGeneration++);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeroPanel(
                color: AppColors.primaryDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppStatusPill(
                      label: 'Para tu médico',
                      color: Colors.white,
                      icon: Icons.medical_services_rounded,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Sube tus resultados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Laboratorio, radiografías, resonancias, recetas u otros PDF. '
                      'Los médicos con los que tengas citas podrán verlos en tu historial antes de la consulta.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              MedicalDocumentsSection(key: ValueKey(_listGeneration)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Formatos: PDF, JPG o PNG (máx. 12 MB). '
                        'También puedes ver tus visitas y antecedentes en Historial clínico.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
