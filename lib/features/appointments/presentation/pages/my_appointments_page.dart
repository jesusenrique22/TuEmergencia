import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/appointment_datetime.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../../auth/domain/models/role.dart';
import '../../../../core/services/consultation_closure_coordinator.dart';
import '../../data/appointment_api_service.dart';
import '../../domain/models/appointment.dart';
import '../widgets/consultation_report_doctor_chip.dart';
import '../widgets/consultation_report_patient_card.dart';
import '../widgets/doctor_rating_dialog.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = AppointmentApiService();

  List<Appointment> _appointments = [];
  bool _loading = true;
  String? _error;
  bool _ratingPromptShown = false;

  bool get _isDoctor => AppSession.activeRole == Role.doctor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppSession.isLoggedIn) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = _isDoctor
          ? await _service.getDoctorAppointments()
          : await _service.getMyAppointments();
      setState(() {
        _appointments = data;
        _loading = false;
      });
      _maybePromptRating();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        AppSession.clear();
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudo conectar al servidor';
        _loading = false;
      });
    }
  }

  List<Appointment> get _upcoming => _appointments
      .where((a) =>
          a.status != AppointmentStatus.completed &&
          a.status != AppointmentStatus.cancelled &&
          a.dateTime.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<Appointment> get _past => _appointments
      .where((a) =>
          a.status == AppointmentStatus.completed ||
          a.status == AppointmentStatus.cancelled ||
          a.dateTime.isBefore(DateTime.now()))
      .toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  Appointment? get _nextToRate {
    final pending = _appointments.where((a) => a.canRate).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return pending.isEmpty ? null : pending.first;
  }

  void _maybePromptRating() {
    if (_isDoctor || _ratingPromptShown || !mounted) return;
    final appt = _nextToRate;
    if (appt == null) return;
    _ratingPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _rateDoctor(appt);
    });
  }

  Future<void> _rateDoctor(Appointment appt) async {
    final result = await showDoctorRatingDialog(
      context,
      doctorName: appt.doctorName,
    );
    if (result == null || !mounted) return;

    try {
      await _service.rateAppointment(
        appt.id,
        rating: result.rating,
        comment: result.comment,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gracias por tu calificación'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  String _fmt(DateTime d) => formatAppointmentDateTime(d);

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: const Text('Mis Citas'),
      child: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            if (!_isDoctor) _PatientShareExamsBanner(),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Próximas'),
                Tab(text: 'Historial'),
              ],
            ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_upcoming, isUpcoming: true),
                    _buildList(_past, isUpcoming: false),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Appointment> list, {required bool isUpcoming}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 44,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isUpcoming
                    ? 'No tienes citas próximas'
                    : 'No hay citas en el historial',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Agenda una consulta presencial o por videollamada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              if (!_isDoctor) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.schedule),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agendar cita'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _AppointmentCard(
        appt: list[i],
        isDoctor: _isDoctor,
        formatDate: _fmt,
        onCancel: () => _cancelAppt(list[i]),
        onComplete: _isDoctor ? () => _completeAppt(list[i]) : null,
        onPatientReportUpdated: _load,
        onViewHistory: _isDoctor
            ? () => Navigator.pushNamed(
                  context,
                  AppRoutes.medicalHistory,
                  arguments: {'patientId': list[i].patientId},
                )
            : null,
        onRate: !_isDoctor && list[i].canRate
            ? () => _rateDoctor(list[i])
            : null,
      ),
    );
  }

  Future<void> _cancelAppt(Appointment appt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar cita'),
        content: const Text('¿Seguro que quieres cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.cancelAppointment(appt.id);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeAppt(Appointment appt) async {
    final done = await ConsultationClosureCoordinator.openFor(appt);
    if (done == true) _load();
  }
}

class _PatientShareExamsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.patientShareExams),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compartir exámenes con tu médico',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Laboratorio, radiografías o PDF',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appt;
  final bool isDoctor;
  final String Function(DateTime) formatDate;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final VoidCallback? onViewHistory;
  final VoidCallback? onRate;
  final VoidCallback? onPatientReportUpdated;

  const _AppointmentCard({
    required this.appt,
    required this.isDoctor,
    required this.formatDate,
    this.onCancel,
    this.onComplete,
    this.onViewHistory,
    this.onRate,
    this.onPatientReportUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = appt.type == AppointmentType.online;
    final name = isDoctor ? appt.patientName : appt.doctorName;
    final avatar = isDoctor ? appt.patientAvatar : appt.doctorAvatar;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SafeAvatar(radius: 24, imageUrl: avatar),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (appt.specialty.isNotEmpty)
                      Text(
                        appt.specialty,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusBadge(status: appt.status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                formatDate(appt.dateTime),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(
                isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                isOnline ? 'Online' : 'Presencial',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (appt.durationMinutes > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.hourglass_bottom_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${appt.durationMinutes} minutos',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (appt.reason != null && appt.reason!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appt.reason!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (!isDoctor && appt.hasRating) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                DoctorRatingStars(
                  rating: appt.patientRating!.toDouble(),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tu calificación',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (appt.patientReview != null &&
                appt.patientReview!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                appt.patientReview!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
          if (!isDoctor && onRate != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRate,
                icon: const Icon(Icons.star_rounded, size: 18),
                label: const Text('Calificar al médico'),
              ),
            ),
          ],
          if (!isDoctor && appt.hasConsultationReport) ...[
            ConsultationReportPatientCard(
              appointment: appt,
              onUpdated: onPatientReportUpdated,
            ),
          ],
          if (isDoctor && appt.needsClosure) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.assignment_rounded, size: 18),
                label: const Text('Completar informe de consulta'),
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ),
          ],
          if (isDoctor &&
              appt.hasConsultationReport &&
              !appt.needsClosure) ...[
            const SizedBox(height: 14),
            ConsultationReportDoctorChip(appointment: appt),
          ],
          if (isDoctor && onViewHistory != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewHistory,
                icon: const Icon(Icons.folder_shared_rounded, size: 18),
                label: const Text('Historial y documentos del paciente'),
              ),
            ),
          ],
          if (isDoctor &&
              onComplete != null &&
              !appt.needsClosure &&
              (appt.status == AppointmentStatus.confirmed ||
                  appt.status == AppointmentStatus.pending)) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Completar consulta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (onCancel != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                if (!isDoctor && onCancel == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isOnline
                          ? () => AppNavigation.openTelemedicineViaMessages(
                                context,
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                          isOnline ? 'Unirse a consulta' : 'Presencial'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String text;

    switch (status) {
      case AppointmentStatus.confirmed:
        color = Colors.green;
        text = 'Confirmada';
      case AppointmentStatus.pending:
        color = Colors.orange;
        text = 'Pendiente';
      case AppointmentStatus.completed:
        color = AppColors.primary;
        text = 'Completada';
      case AppointmentStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelada';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
