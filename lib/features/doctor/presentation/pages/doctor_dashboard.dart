import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../../appointments/data/appointment_api_service.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../appointments/domain/models/appointment.dart';
import '../../data/doctor_api_service.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final _apptService = AppointmentApiService();
  final _doctorApi = DoctorApiService();

  List<Appointment> _appointments = [];
  List<Appointment> _todayAppointments = [];
  DoctorProfileContext? _profile;
  bool _loadingAppts = false;
  bool _telemedicineRequestDismissed = false;

  bool get _showRequest =>
      !_telemedicineRequestDismissed &&
      _appointments.any(
        (a) =>
            a.type == AppointmentType.online &&
            a.status != AppointmentStatus.cancelled &&
            a.status != AppointmentStatus.completed,
      );

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([_loadProfile(), _loadAppointments()]);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _doctorApi.getProfileContext();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      // Perfil opcional; el header usa AppSession como respaldo.
    }
  }

  Future<void> _loadAppointments() async {
    setState(() => _loadingAppts = true);
    try {
      final list = await _apptService.getDoctorAppointments();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final upcoming = list
          .where(
            (a) =>
                a.status != AppointmentStatus.cancelled &&
                a.dateTime.isAfter(now.subtract(const Duration(minutes: 1))),
          )
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      final todayOnly = upcoming.where((a) {
        final d = a.dateTime.toLocal();
        return d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
      }).toList();

      if (!mounted) return;
      setState(() {
        _appointments = upcoming;
        _todayAppointments = todayOnly;
        _loadingAppts = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _loadingAppts = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAppts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel del Médico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi perfil',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.doctorProfile),
          ),
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadingAppts ? null : _refreshDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AppSession.clear();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorHeader(),
            const SizedBox(height: 24),
            _buildStatsCards(),
            const SizedBox(height: 32),
            _buildScheduleManagerCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('Próximas Consultas', 'Ver todas'),
            const SizedBox(height: 16),
            _buildUpcomingAppointments(),
            const SizedBox(height: 32),
            if (_showRequest) ...[
              _buildSectionHeader('Solicitudes de Telemedicina', null),
              const SizedBox(height: 16),
              _buildTelemedicineRequest(),
            ],
          ],
        ),
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewPrescriptionSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Receta',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showNewPrescriptionSheet() {
    String? selectedPatient;
    final observationsController = TextEditingController();
    List<Map<String, TextEditingController>> medications = [
      {
        'name': TextEditingController(),
        'dose': TextEditingController(),
        'frequency': TextEditingController(),
        'instructions': TextEditingController(),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Generar Receta Médica',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seleccionar Paciente en Espera',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPatient,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.person_search,
                            color: AppColors.primary,
                          ),
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        hint: const Text('Elija un paciente de la lista'),
                        items: _appointments
                            .map(
                              (appt) => DropdownMenuItem(
                                value: appt.patientName,
                                child: Text(appt.patientName),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedPatient = val),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Medicamentos y Tratamiento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...medications.asMap().entries.map((entry) {
                        int index = entry.key;
                        var med = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Medicamento #${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (medications.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => setModalState(
                                        () => medications.removeAt(index),
                                      ),
                                    ),
                                ],
                              ),
                              _buildPrescriptionField(
                                'Nombre (Ej: Amoxicilina)',
                                med['name']!,
                                Icons.medication_outlined,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPrescriptionField(
                                      'Dosis',
                                      med['dose']!,
                                      Icons.straighten,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildPrescriptionField(
                                      'Frecuencia',
                                      med['frequency']!,
                                      Icons.timer_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildPrescriptionField(
                                'Instrucciones (Ej: Después de comer)',
                                med['instructions']!,
                                Icons.info_outline,
                              ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () => setModalState(() {
                          medications.add({
                            'name': TextEditingController(),
                            'dose': TextEditingController(),
                            'frequency': TextEditingController(),
                            'instructions': TextEditingController(),
                          });
                        }),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Añadir otro medicamento'),
                      ),
                      const SizedBox(height: 24),
                      _buildPrescriptionField(
                        'Observaciones Adicionales',
                        observationsController,
                        Icons.note_alt_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 100), // Space for button
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedPatient == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, seleccione un paciente'),
                        ),
                      );
                      return;
                    }
                    // Start simulation
                    _simulatePrescriptionFlow(context, selectedPatient!);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Emitir Receta y Enviar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _registerIncome(String patientName, String type) {
    // Simulate a financial transaction record
    final amount = type == 'Telemedicina' ? '25.00' : '45.00';
    debugPrint(
      'FINANCIAL_LOG: Ingreso registrado - Paciente: $patientName, Monto: \$$amount, Concepto: Consulta $type',
    );
  }

  void _simulatePrescriptionFlow(BuildContext context, String patientName) {
    final appt = _appointments.cast<Appointment?>().firstWhere(
          (a) => a?.patientName == patientName,
          orElse: () => null,
        );
    final type = appt?.type == AppointmentType.online ? 'Telemedicina' : 'Presencial';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Sincronizando con Paciente...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Generando Documento PDF Digital',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Simulate completion
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;

      _registerIncome(patientName, type);

      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close bottom sheet

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text('¡Receta Emitida!', textAlign: TextAlign.center),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'La receta ha sido enviada exitosamente al expediente digital de $patientName y está lista para su descarga.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ingreso registrado: \$${type == 'Telemedicina' ? '25.00' : '45.00'}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Iniciando descarga: Receta_$patientName.pdf',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar PDF Ahora'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPrescriptionField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDoctorHeader() {
    final user = AppSession.currentUser;
    final name = _profile?.name ?? user?.name ?? 'Médico';
    final subtitle = _profile?.subtitle ?? 'Panel médico VITA';
    final avatar = _profile?.avatarUrl ?? user?.avatarUrl;

    return Row(
      children: [
        SafeAvatar(radius: 30, imageUrl: avatar ?? ''),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final todayCount = _todayAppointments.length.toString();
    return Row(
      children: [
        _statCard('Citas hoy', _loadingAppts ? '…' : todayCount,
            Icons.calendar_today, Colors.orange),
        const SizedBox(width: 16),
        _statCard(
            'Confirmadas',
            _loadingAppts
                ? '…'
                : _todayAppointments
                    .where((a) =>
                        a.status == AppointmentStatus.confirmed ||
                        a.status == AppointmentStatus.pending)
                    .length
                    .toString(),
            Icons.check_circle_outline,
            Colors.green),
        const SizedBox(width: 16),
        _statCard(
          'Calificación',
          _profile != null
              ? _profile!.rating.toStringAsFixed(1)
              : '…',
          Icons.star,
          Colors.amber,
          subtitle: _profile != null && _profile!.ratingCount > 0
              ? '${_profile!.ratingCount} reseñas'
              : null,
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleManagerCard() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.doctorSchedule),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Disponibilidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Configura tus horarios en múltiples sedes',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (action != null)
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.appointments),
            child: Text(
              action,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  String _fmtTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final period = d.hour >= 12 ? 'PM' : 'AM';
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Widget _buildUpcomingAppointments() {
    if (_loadingAppts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'No tienes citas próximas. Cuando un paciente agende, aparecerá aquí.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: _appointments.map((appt) {
        final isTele = appt.type == AppointmentType.online;
        final isCompleted = appt.status == AppointmentStatus.completed;
        final timeStr = _fmtTime(appt.dateTime);

        return Opacity(
          opacity: isCompleted ? 0.65 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.grey.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
              border: isCompleted
                  ? Border.all(color: Colors.green.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.green)
                        : Text(
                            timeStr.split(' ')[0],
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.patientName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        '${isTele ? 'Telemedicina' : 'Presencial'}  ·  $timeStr  ·  ${appt.durationMinutes} min',
                        style: TextStyle(
                          color: isTele ? AppColors.primary : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ver historial',
                  icon: const Icon(Icons.history_edu_rounded,
                      color: AppColors.primary),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.medicalHistory,
                  ),
                ),
                if (isCompleted)
                  const Text(
                    'Completado',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  )
                else if (isTele)
                  IconButton(
                    icon:
                        const Icon(Icons.videocam, color: AppColors.primary),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.videoCall),
                  )
                else
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTelemedicineRequest() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SafeAvatar(
                radius: 20,
                imageUrl: 'https://i.pravatar.cc/150?u=lucia',
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lucía Mendez',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Dolor de pecho agudo',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Hace 2 min',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _telemedicineRequestDismissed = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitud rechazada')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.videoCall,
                    arguments: 'Lucía Mendez',
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Atender Ahora'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
