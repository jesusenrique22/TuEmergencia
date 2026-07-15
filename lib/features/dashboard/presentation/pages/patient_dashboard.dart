import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/auth/app_session.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/appointment_datetime.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/promo/promo_carousel.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../../../core/widgets/promo/merchant_row.dart';
import '../../../../core/widgets/promo/quick_actions_row.dart';
import '../../../../core/widgets/profile_ui.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../appointments/data/appointment_api_service.dart';
import '../../../appointments/data/consultation_follow_up_api_service.dart';
import '../../../appointments/domain/models/appointment.dart';
import '../../../appointments/presentation/widgets/appointment_reminder_host.dart';
import '../../../appointments/presentation/widgets/consultation_follow_up_section.dart';
import '../../../patient_profile/data/patient_profile_repository.dart';

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
      AppRealtime.maintainSessionConnection();
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

  void _navigate(String route) {
    Navigator.pushNamed(context, route);
  }

  void _onPromoTap(PromoOffer offer) {
    if (offer.route != null) _navigate(offer.route!);
  }

  void _onPartnerTap(PromoPartner partner) {
    if (partner.route != null) _navigate(partner.route!);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: FadeSlideIn(child: _buildHeader(context))),
          SliverToBoxAdapter(
            child: FadeSlideIn(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: PromoCarousel(
                  offers: PromoMockData.offers,
                  onOfferTap: _onPromoTap,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: QuickActionsRow(
                actions: [
                  QuickAction(
                    icon: Icons.calendar_month_rounded,
                    label: 'Agendar',
                    color: AppColors.primary,
                    onTap: () => _navigate(AppRoutes.schedule),
                  ),
                  QuickAction(
                    icon: Icons.chat_rounded,
                    label: 'Mensajes',
                    color: AppColors.secondary,
                    onTap: () => _navigate(AppRoutes.messages),
                  ),
                  QuickAction(
                    icon: Icons.event_note_rounded,
                    label: 'Mis citas',
                    color: AppColors.info,
                    onTap: () => _navigate(AppRoutes.appointments),
                  ),
                  QuickAction(
                    icon: Icons.assignment_turned_in_rounded,
                    label: 'Resultados',
                    color: AppColors.promo,
                    onTap: () => _navigate(AppRoutes.labResults),
                  ),
                  QuickAction(
                    icon: Icons.grid_view_rounded,
                    label: 'Servicios',
                    color: AppColors.accent,
                    onTap: () => _navigate(AppRoutes.healthServices),
                  ),
                ],
              ),
            ),
          ),
          if (!_historyComplete)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: ProfileAlertBanner(
                  message:
                      'Completa tu historia clínica para recibir mejor atención.',
                  icon: Icons.medical_information_outlined,
                  color: AppColors.warning,
                  onTap: () => _navigate(AppRoutes.clinicalHistory),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildUpcomingAppointment(context),
            ),
          ),
          if (_followUps.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConsultationFollowUpSection(
                  items: _followUps,
                  isDoctor: false,
                  onScheduleTap: () => _navigate(AppRoutes.schedule),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: MerchantRow(
              title: 'Doctores destacados',
              subtitle: 'Promociones exclusivas esta semana',
              partners: PromoMockData.featuredDoctors,
              onSeeAll: () => _navigate(AppRoutes.schedule),
              onPartnerTap: _onPartnerTap,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          SliverToBoxAdapter(
            child: MerchantRow(
              title: 'Clínicas aliadas',
              partners: PromoMockData.clinics,
              onSeeAll: () => _navigate(AppRoutes.clinicNetwork),
              onPartnerTap: _onPartnerTap,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          SliverToBoxAdapter(
            child: MerchantRow(
              title: 'Farmacias con delivery',
              partners: PromoMockData.pharmacies,
              onSeeAll: () => _navigate(AppRoutes.pharmacy),
              onPartnerTap: _onPartnerTap,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          SliverToBoxAdapter(
            child: MerchantRow(
              title: 'Laboratorios y estudios',
              partners: PromoMockData.laboratories,
              onSeeAll: () => _navigate(AppRoutes.healthServices),
              onPartnerTap: _onPartnerTap,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _buildExploreAllCard(context),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final profile = PatientProfileRepository.activeProfile;
    final user = AppSession.currentUser;
    final displayName = profile?.fullName ?? user?.name ?? 'Paciente';
    final firstName = displayName.split(' ').first;
    // Initials for avatar
    final parts = displayName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : displayName.substring(0, displayName.length.clamp(0, 2)).toUpperCase();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Ambient decorative blob — top-right corner
            Positioned(
              top: -18,
              right: -12,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Second subtle blob — bottom-left
            Positioned(
              bottom: -10,
              left: 60,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.08),
                      AppColors.secondary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User avatar with initials
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF34D399)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hola, $firstName',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.waving_hand_rounded,
                                color: Colors.amber[600],
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            '¿Cómo podemos ayudarte hoy?',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // SOS button — tight, intentional
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.ambulanceCheckout),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.emergency,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emergency.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const NotificationBadge(onDarkBackground: false),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Minimal stat pills — inline, no box
                Row(
                  children: [
                    _HeaderStatChip(
                      icon: Icons.water_drop_rounded,
                      label: profile?.bloodType ?? '—',
                      iconColor: AppColors.emergency,
                      backgroundColor: AppColors.emergencyLight,
                      textColor: AppColors.textPrimary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _HeaderStatChip(
                      icon: Icons.verified_rounded,
                      label: profile?.insuranceProvider ?? 'Sin seguro',
                      iconColor: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                      textColor: AppColors.textPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointment(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Próxima cita',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loadingNextAppt)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_nextAppointment == null)
            Text(
              'No tienes citas próximas. ¡Agenda una cuando quieras!',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            _AppointmentRow(
              appointment: _nextAppointment!,
              onVideoTap: () =>
                  AppNavigation.openTelemedicineViaMessages(context),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _navigate(AppRoutes.schedule),
              child: const Text('Agendar cita'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreAllCard(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigate(AppRoutes.healthServices),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explorar todos los servicios',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Citas, labs, farmacia, seguros y más',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final Color textColor;

  const _HeaderStatChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onVideoTap;

  const _AppointmentRow({
    required this.appointment,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.doctorName.isNotEmpty
                    ? appointment.doctorName
                    : 'Médico',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                [
                  if (appointment.specialty.isNotEmpty) appointment.specialty,
                  formatAppointmentDateTimeLong(appointment.dateTime),
                  if (appointment.type == AppointmentType.online)
                    'Telemedicina',
                ].join(' · '),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (appointment.type == AppointmentType.online)
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AppColors.primary),
            onPressed: onVideoTap,
          ),
      ],
    );
  }
}

/// Wrapper que integra el dashboard dentro del scaffold responsive global.
class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final apptService = AppointmentApiService();
    return AppointmentReminderHost(
      loadAppointments: apptService.getMyAppointments,
      child: const ResponsiveScaffold(
        hideAppBar: true,
        child: PatientDashboardPage(),
      ),
    );
  }
}
