import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../data/patient_profile_repository.dart';
import '../../domain/models/patient_profile.dart';
import '../widgets/medical_history_prompt_dialog.dart';
import '../../../medical_history/presentation/widgets/patient_weight_control_panel.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (AppSession.isLoggedIn) {
      await PatientProfileRepository.refreshFromApi();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openClinicalHistory() async {
    await Navigator.pushNamed(context, AppRoutes.clinicalHistory);
    await _refresh();
  }

  Future<void> _promptIfIncomplete() async {
    final profile = PatientProfileRepository.activeProfile;
    if (profile == null || profile.medicalHistoryCompleted) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['promptHistory'] == true) {
      final fill = await showMedicalHistoryPrompt(context);
      if (!mounted) return;
      if (fill == true) await _openClinicalHistory();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptIfIncomplete());
  }

  @override
  Widget build(BuildContext context) {
    final profile = PatientProfileRepository.activeProfile;
    final user = AppSession.currentUser;
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (user?.name ?? 'Paciente');
    final completed = profile?.medicalHistoryCompleted ?? false;

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => AppNavigation.safeBack(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppPage(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeroPanel(
                    color: AppColors.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppStatusPill(
                          label: completed
                              ? 'Historia completa'
                              : 'Historia pendiente',
                          color: completed ? Colors.greenAccent : Colors.amber,
                          icon: completed
                              ? Icons.check_circle
                              : Icons.pending_actions,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile?.email ?? user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!completed)
                    AppPanel(
                      color: Colors.amber.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Completa tu historia clínica para que los médicos '
                              'conozcan tus antecedentes antes de la consulta.',
                              style: TextStyle(color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!completed) const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openClinicalHistory,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(
                      completed
                          ? 'Editar historia clínica'
                          : 'Completar historia clínica',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (profile != null) ...[
                    PatientWeightControlReadOnly(
                      controls: profile.weightControls,
                    ),
                    const SizedBox(height: 16),
                    ..._summarySections(profile),
                  ],
                ],
              ),
            ),
    );
  }

  List<Widget> _summarySections(PatientProfile p) {
    return [
      _summaryCard('Datos personales', [
        _line('Documento', p.documentId),
        _line('Nacimiento', p.birthDate),
        _line('Estado civil', p.maritalStatus),
        _line('Ocupación', p.occupation),
        _line('Dirección', p.address),
      ]),
      const SizedBox(height: 12),
      _summaryCard('Contacto', [
        _line('Teléfono', p.phone),
        _line('Emergencia', p.emergencyContactName),
        _line('Tel. emergencia', p.emergencyContactPhone),
      ]),
      const SizedBox(height: 12),
      _summaryCard('Antecedentes', [
        _line('Hipertensión', p.hasHypertension ? 'Sí' : 'No'),
        _line('Diabetes', p.hasDiabetes ? 'Sí' : 'No'),
        _line('Asma', p.hasBronchialAsthma ? 'Sí' : 'No'),
        _line('Fumador', p.isSmoker ? 'Sí' : 'No'),
        _line('Alergias', p.allergies),
        _line('Cirugías', p.surgeries),
      ]),
      const SizedBox(height: 12),
      _summaryCard('Datos clínicos', [
        _line('Tipo de sangre', p.bloodType),
        _line('Peso', p.weightKg.isNotEmpty ? '${p.weightKg} kg' : ''),
        _line('Talla', p.heightCm.isNotEmpty ? '${p.heightCm} cm' : ''),
        _line('Seguro', p.insuranceProvider),
      ]),
    ];
  }

  Widget _summaryCard(String title, List<Widget> lines) {
    final visible = lines.where((w) => w is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: 12),
          ...visible,
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
