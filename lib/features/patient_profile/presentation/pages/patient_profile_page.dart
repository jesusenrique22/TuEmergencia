import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/profile_ui.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
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
    final email = profile?.email ?? user?.email ?? '';
    final completed = profile?.medicalHistoryCompleted ?? false;
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      title: const Text('Mi perfil'),
      body: ProfileScreenLayout(
        loading: _loading,
        onRefresh: _refresh,
        maxWidth: 720,
        children: [
          ProfileGradientHeader(
            name: name,
            subtitle: email,
            badgeLabel: completed
                ? 'Historia clínica completa'
                : 'Historia pendiente',
            badgeIcon: completed
                ? Icons.check_circle_rounded
                : Icons.pending_actions_rounded,
            badgeColor: completed
                ? const Color(0xFF6EE7B7)
                : const Color(0xFFFCD34D),
            leading: SafeAvatar(
              radius: 32,
              imageUrl: user?.avatarUrl ?? '',
              placeholderIcon: Icons.person_rounded,
            ),
                      stats: [
                        ProfileStatChip(
                          icon: Icons.bloodtype_rounded,
                          label: 'Sangre',
                          value: profile?.bloodType ?? 'Sin registrar',
                        ),
                        ProfileStatChip(
                          icon: Icons.shield_rounded,
                          label: 'Seguro',
                          value: profile?.insuranceProvider ?? 'Sin registrar',
                        ),
                        ProfileStatChip(
                          icon: Icons.monitor_heart_rounded,
                          label: 'Estado',
                          value: 'Activo',
                        ),
            ],
          ),
          const SizedBox(height: 20),
          if (!completed)
            ProfileAlertBanner(
              message:
                  'Completa tu historia clínica para que los médicos '
                  'conozcan tus antecedentes antes de la consulta.',
              icon: Icons.medical_information_outlined,
              color: Colors.amber.shade800,
              onTap: _openClinicalHistory,
            ),
          if (!completed) const SizedBox(height: 16),
          ProfileGradientButton(
            label: completed
                ? 'Editar historia clínica'
                : 'Completar historia clínica',
            icon: Icons.edit_note_rounded,
            onPressed: _openClinicalHistory,
          ),
          const SizedBox(height: 12),
          ProfileGradientButton(
            label: 'Compartir exámenes con mi médico',
            icon: Icons.upload_file_rounded,
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.patientShareExams,
            ),
          ),
          const SizedBox(height: 20),
          if (profile != null) ...[
            if (profile.weightControls.isNotEmpty) ...[
              ProfileSectionCard(
                title: 'Control de peso',
                icon: Icons.monitor_weight_rounded,
                children: [
                  PatientWeightControlReadOnly(
                    controls: profile.weightControls,
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            ..._summarySections(profile),
          ],
          const SizedBox(height: 16),
          ProfileLogoutButton(
            onPressed: () {
              AppSession.clear();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _summarySections(PatientProfile p) {
    return [
      ProfileSectionCard(
        title: 'Datos personales',
        icon: Icons.badge_outlined,
        children: [
          ProfileInfoRow(label: 'Documento', value: p.documentId),
          ProfileInfoRow(label: 'Nacimiento', value: p.birthDate),
          ProfileInfoRow(label: 'Estado civil', value: p.maritalStatus),
          ProfileInfoRow(label: 'Ocupación', value: p.occupation),
          ProfileInfoRow(label: 'Dirección', value: p.address),
        ],
      ),
      const SizedBox(height: 14),
      ProfileSectionCard(
        title: 'Contacto',
        icon: Icons.contact_phone_outlined,
        children: [
          ProfileInfoRow(label: 'Teléfono', value: p.phone),
          ProfileInfoRow(label: 'Emergencia', value: p.emergencyContactName),
          ProfileInfoRow(label: 'Tel. emergencia', value: p.emergencyContactPhone),
        ],
      ),
      const SizedBox(height: 14),
      ProfileSectionCard(
        title: 'Antecedentes',
        icon: Icons.health_and_safety_outlined,
        children: [
          ProfileInfoRow(
            label: 'Hipertensión',
            value: p.hasHypertension ? 'Sí' : 'No',
          ),
          ProfileInfoRow(label: 'Diabetes', value: p.hasDiabetes ? 'Sí' : 'No'),
          ProfileInfoRow(
            label: 'Asma',
            value: p.hasBronchialAsthma ? 'Sí' : 'No',
          ),
          ProfileInfoRow(label: 'Fumador', value: p.isSmoker ? 'Sí' : 'No'),
          ProfileInfoRow(label: 'Alergias', value: p.allergies),
          ProfileInfoRow(label: 'Cirugías', value: p.surgeries),
        ],
      ),
      const SizedBox(height: 14),
      ProfileSectionCard(
        title: 'Datos clínicos',
        icon: Icons.medical_services_outlined,
        children: [
          ProfileInfoRow(label: 'Tipo de sangre', value: p.bloodType),
          ProfileInfoRow(
            label: 'Peso',
            value: p.weightKg.isNotEmpty ? '${p.weightKg} kg' : '',
          ),
          ProfileInfoRow(
            label: 'Talla',
            value: p.heightCm.isNotEmpty ? '${p.heightCm} cm' : '',
          ),
          ProfileInfoRow(label: 'Seguro', value: p.insuranceProvider),
        ],
      ),
    ];
  }
}
