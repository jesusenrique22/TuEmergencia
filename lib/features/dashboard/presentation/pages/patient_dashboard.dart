import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/appointment_datetime.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/profile_ui.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../appointments/data/appointment_api_service.dart';
import '../../../appointments/data/consultation_follow_up_api_service.dart';
import '../../../appointments/domain/models/appointment.dart';
import '../../../appointments/presentation/widgets/appointment_reminder_host.dart';
import '../../../appointments/presentation/widgets/consultation_follow_up_section.dart';
import '../../../patient_profile/data/patient_profile_repository.dart';

/// Content of the Patient Dashboard page – now used inside ResponsiveScaffold.
class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final _apptService = AppointmentApiService();
  final _followUpService = ConsultationFollowUpApiService();
  Appointment? _nextAppointment;
  List<ConsultationFollowUpItem> _followUps = [];
  bool _loadingNextAppt = false;

  @override
  void initState() {
    super.initState();
    if (AppSession.isLoggedIn) {
      _refreshDashboard();
    }
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      PatientProfileRepository.refreshFromApi(),
      _loadNextAppointment(),
      _loadFollowUps(),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _loadFollowUps() async {
    try {
      final list = await _followUpService.getPatientFollowUps();
      if (!mounted) return;
      setState(() => _followUps = list);
    } catch (_) {
      if (mounted) setState(() => _followUps = []);
    }
  }

  Future<void> _loadNextAppointment() async {
    setState(() => _loadingNextAppt = true);
    try {
      final list = await _apptService.getMyAppointments();
      final now = DateTime.now();
      final upcoming = list
          .where(
            (a) =>
                a.status != AppointmentStatus.cancelled &&
                a.dateTime.isAfter(now.subtract(const Duration(minutes: 1))),
          )
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      if (!mounted) return;
      setState(() {
        _nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;
        _loadingNextAppt = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingNextAppt = false);
    }
  }

  bool get _historyComplete =>
      PatientProfileRepository.activeProfile?.medicalHistoryCompleted ?? false;

  Widget _buildHistoryReminder(BuildContext context) {
    return ProfileAlertBanner(
      message: 'Tu historia clínica está incompleta. Toca aquí para completarla.',
      icon: Icons.medical_information_outlined,
      color: Colors.amber.shade800,
      onTap: () => Navigator.pushNamed(context, AppRoutes.clinicalHistory),
    );
  }

  String _formatApptWhen(DateTime dt) => formatAppointmentDateTimeLong(dt);

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return AppPage(
      padding: EdgeInsets.all(isCompact ? 16 : 28),
      maxWidth: 1280,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          final mainContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (!_historyComplete) ...[
                const SizedBox(height: 16),
                _buildHistoryReminder(context),
              ],
              const SizedBox(height: 22),
              _buildEssentialActions(context),
              const SizedBox(height: 24),
              _buildServiceMarketplace(context),
            ],
          );

          final sideContent = Column(
            children: [
              _buildPatientSummary(context),
              const SizedBox(height: 18),
              _buildUpcomingAppointment(context),
              if (_followUps.isNotEmpty) ...[
                const SizedBox(height: 18),
                ConsultationFollowUpSection(
                  items: _followUps,
                  isDoctor: false,
                  onScheduleTap: () =>
                      Navigator.pushNamed(context, AppRoutes.schedule),
                ),
              ],
            ],
          );

          if (!isWide) {
            return Column(
              children: [mainContent, const SizedBox(height: 24), sideContent],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: mainContent),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: sideContent),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final profile = PatientProfileRepository.activeProfile;
    final user = AppSession.currentUser;
    final displayName = profile?.fullName ?? user?.name ?? 'Paciente';
    final firstName = displayName.split(' ').first;

    return ProfileGradientHeader(
      name: 'Hola, $firstName',
      subtitle:
          'Tu centro de control para atención médica, emergencias y seguimiento clínico.',
      badgeLabel: 'Paciente activo',
      badgeIcon: Icons.verified_rounded,
      badgeColor: Colors.white,
      actions: [
        const NotificationBadge(onDarkBackground: true),
        ProfileHeaderIconButton(
          tooltip: 'Cerrar sesión',
          onDarkBackground: true,
          icon: Icons.logout_rounded,
          onPressed: () {
            AppSession.clear();
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
        ),
      ],
      stats: [
        ProfileStatChip(
          icon: Icons.favorite_rounded,
          label: 'Estado',
          value: 'Estable',
        ),
        ProfileStatChip(
          icon: Icons.bloodtype_rounded,
          label: 'Sangre',
          value: profile?.bloodType ?? 'Sin registrar',
        ),
        ProfileStatChip(
          icon: Icons.shield_rounded,
          label: 'Seguro',
          value: profile?.insuranceProvider ?? 'Pendiente',
        ),
      ],
    );
  }

  Widget _buildEssentialActions(BuildContext context) {
    final actions = [
      _DashboardAction(
        icon: Icons.calendar_month_rounded,
        title: 'Agendar cita',
        subtitle: 'Consulta presencial o por video',
        route: AppRoutes.schedule,
        color: AppColors.primary,
        isPrimary: true,
      ),
      _DashboardAction(
        icon: Icons.emergency_rounded,
        title: 'Emergencia',
        subtitle: 'Solicitar ambulancia ahora',
        route: AppRoutes.ambulanceCheckout,
        color: AppColors.emergency,
        isPrimary: true,
      ),
      _DashboardAction(
        icon: Icons.event_note_rounded,
        title: 'Mis citas',
        subtitle: 'Agenda y llamadas pendientes',
        route: AppRoutes.appointments,
        color: AppColors.info,
      ),
      _DashboardAction(
        icon: Icons.upload_file_rounded,
        title: 'Compartir exámenes',
        subtitle: 'Laboratorio, rayos X y PDF para tu médico',
        route: AppRoutes.patientShareExams,
        color: AppColors.primary,
      ),
      _DashboardAction(
        icon: Icons.assignment_ind_rounded,
        title: 'Mi perfil médico',
        subtitle: 'Datos personales y clínicos',
        route: AppRoutes.patientProfile,
        color: AppColors.secondary,
      ),
      _DashboardAction(
        icon: Icons.history_edu_rounded,
        title: 'Historial clínico',
        subtitle: 'Visitas, antecedentes y recetas',
        route: AppRoutes.medicalHistory,
        color: AppColors.accent,
      ),
    ];

    final primary = actions.where((a) => a.isPrimary).toList();
    final secondary = actions.where((a) => !a.isPrimary).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Acciones esenciales',
          subtitle: 'Lo más importante para tu atención diaria.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompactLayout = constraints.maxWidth >= 560;

            if (isCompactLayout) {
              return Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < primary.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _PrimaryActionTile(
                            action: primary[i],
                            onTap: () => Navigator.pushNamed(
                              context,
                              primary[i].route,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Column(
                      children: secondary
                          .map(
                            (action) => _ServiceRow(
                              action: action,
                              onTap: () =>
                                  Navigator.pushNamed(context, action.route),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 76,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _EssentialActionCard(
                  action: action,
                  onTap: () => Navigator.pushNamed(context, action.route),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPatientSummary(BuildContext context) {
    final profile = PatientProfileRepository.activeProfile;
    final user = AppSession.currentUser;
    final fullName = profile?.fullName ?? user?.name ?? 'Paciente';

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      profile?.email ?? user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _summaryRow(Icons.monitor_heart_rounded, 'Condición', 'Estable'),
          _summaryRow(
            Icons.medication_rounded,
            'Medicamentos',
            profile?.currentMedications ?? 'Sin registrar',
          ),
          _summaryRow(
            Icons.warning_amber_rounded,
            'Alergias',
            profile?.allergies ?? 'Sin registrar',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: _dashboardButtonStyle(outlined: false),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.patientShareExams),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Subir exámenes para mi médico'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: _dashboardButtonStyle(outlined: true),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.patientProfile),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Editar perfil'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: _dashboardButtonStyle(outlined: true),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.medicalHistory),
                  icon: const Icon(Icons.history_edu_rounded, size: 18),
                  label: const Text('Historial'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceMarketplace(BuildContext context) {
    final services = [
      _DashboardAction(
        icon: Icons.science_rounded,
        title: 'Laboratorios',
        subtitle: 'Pruebas, paquetes y resultados',
        route: AppRoutes.labMarketplace,
        color: AppColors.accent,
      ),
      _DashboardAction(
        icon: Icons.assignment_turned_in_rounded,
        title: 'Resultados',
        subtitle: 'Consulta y descarga estudios',
        route: AppRoutes.labResults,
        color: AppColors.info,
      ),
      _DashboardAction(
        icon: Icons.local_pharmacy_rounded,
        title: 'Farmacia',
        subtitle: 'Compra medicamentos y receta',
        route: AppRoutes.pharmacy,
        color: AppColors.secondary,
      ),
      _DashboardAction(
        icon: Icons.shield_rounded,
        title: 'Seguro',
        subtitle: 'Pólizas y copagos',
        route: AppRoutes.insuranceWallet,
        color: AppColors.warning,
      ),
      _DashboardAction(
        icon: Icons.business_rounded,
        title: 'Clínicas',
        subtitle: 'Red aliada y cobertura',
        route: AppRoutes.clinicNetwork,
        color: AppColors.primaryDark,
      ),
      _DashboardAction(
        icon: Icons.image_search_rounded,
        title: 'Radiología',
        subtitle: 'Rayos X, ecos y resonancia',
        route: AppRoutes.radiologyMarketplace,
        color: AppColors.accent,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Servicios complementarios',
          subtitle:
              'Accesos menos frecuentes, agrupados para no saturar el inicio.',
        ),
        const SizedBox(height: 16),
        AppPanel(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: services
                .map(
                  (service) => _ServiceRow(
                    action: service,
                    onTap: () => Navigator.pushNamed(context, service.route),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointment(BuildContext context) {
    final appt = _nextAppointment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Próxima cita',
          subtitle: 'Tu agenda médica inmediata',
        ),
        const SizedBox(height: 16),
        AppPanel(
          child: Column(
            children: [
              if (_loadingNextAppt)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (appt == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No tienes citas próximas. Agenda una consulta cuando lo necesites.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appt.doctorName.isNotEmpty
                              ? appt.doctorName
                              : 'Médico',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            if (appt.specialty.isNotEmpty) appt.specialty,
                            _formatApptWhen(appt.dateTime),
                            if (appt.type == AppointmentType.online)
                              'Telemedicina',
                          ].join(' • '),
                          style: const TextStyle(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (appt.type == AppointmentType.online)
                    IconButton(
                      icon: const Icon(Icons.videocam_rounded),
                      onPressed: () =>
                          AppNavigation.openTelemedicineViaMessages(context),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: _dashboardButtonStyle(outlined: true),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.schedule),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Agendar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: _dashboardButtonStyle(outlined: false),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.appointments,
                      ),
                      icon: const Icon(Icons.event_note_rounded, size: 18),
                      label: const Text('Mis citas'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

ButtonStyle _dashboardButtonStyle({required bool outlined}) {
  final base = outlined
      ? OutlinedButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        )
      : FilledButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        );
  return base;
}

class _DashboardAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;
  final bool isPrimary;

  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
    this.isPrimary = false,
  });
}

class _EssentialActionCard extends StatelessWidget {
  final _DashboardAction action;
  final VoidCallback onTap;

  const _EssentialActionCard({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = action.isPrimary ? Colors.white : action.color;
    final background = action.isPrimary ? action.color : AppColors.surface;

    return AppPanel(
      padding: EdgeInsets.zero,
      color: background,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: action.isPrimary
                        ? Colors.white.withValues(alpha: 0.18)
                        : action.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: foreground, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: action.isPrimary ? Colors.white : null,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        action.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: action.isPrimary
                              ? Colors.white.withValues(alpha: 0.78)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionTile extends StatelessWidget {
  final _DashboardAction action;
  final VoidCallback onTap;

  const _PrimaryActionTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final _DashboardAction action;
  final VoidCallback onTap;

  const _ServiceRow({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: action.color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper that integrates the dashboard content into the global responsive scaffold.
class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final apptService = AppointmentApiService();
    return AppointmentReminderHost(
      loadAppointments: apptService.getMyAppointments,
      child: const ResponsiveScaffold(
        title: Text('Inicio'),
        child: PatientDashboardPage(),
      ),
    );
  }
}
