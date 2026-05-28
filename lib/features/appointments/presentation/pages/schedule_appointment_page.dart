import 'package:flutter/material.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../data/appointment_api_service.dart';
import '../../domain/models/appointment.dart';
import '../widgets/doctor_rating_dialog.dart';

class ScheduleAppointmentPage extends StatefulWidget {
  const ScheduleAppointmentPage({super.key});

  @override
  State<ScheduleAppointmentPage> createState() =>
      _ScheduleAppointmentPageState();
}

class _ScheduleAppointmentPageState extends State<ScheduleAppointmentPage> {
  final _catalog = CatalogApiService();
  final _apptService = AppointmentApiService();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOnline = false;
  late DateTime _selectedDate = _initialAppointmentDate();
  String? _selectedSpecialtyId;
  String? _selectedFacilityId;
  DoctorCatalogItem? _selectedDoctor;
  AppointmentTimeSlot? _pickedSlot;
  int _consultationMinutes = 30;

  String _search = '';
  final _searchController = TextEditingController();

  List<SpecialtyCatalogItem> _specialties = [];
  List<DoctorCatalogItem> _allDoctors = [];
  List<AppointmentTimeSlot> _slots = [];
  bool _loadingData = true;
  bool _loadingSlots = false;
  bool _isSubmitting = false;
  String? _loadError;
  String? _slotsError;

  static DateTime _initialAppointmentDate() {
    var d = DateTime.now().add(const Duration(days: 1));
    while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return DateTime(d.year, d.month, d.day);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loadingData = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _catalog.listSpecialties(),
        _catalog.listDoctors(),
      ]);
      setState(() {
        _specialties = results[0] as List<SpecialtyCatalogItem>;
        _allDoctors = results[1] as List<DoctorCatalogItem>;
        _loadingData = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loadError = e.message;
        _loadingData = false;
      });
    } catch (_) {
      setState(() {
        _loadError = 'No se pudo conectar al servidor';
        _loadingData = false;
      });
    }
  }

  List<DoctorCatalogItem> get _filteredDoctors {
    var list = _allDoctors;
    if (_selectedSpecialtyId != null) {
      list = list
          .where((d) => d.specialtyIds.contains(_selectedSpecialtyId))
          .toList();
    }
    final q = _search.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.specialties.any((s) => s.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }

  String get _dateIso {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _selectDoctor(DoctorCatalogItem doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _pickedSlot = null;
      _selectedFacilityId =
          !_isOnline && doctor.facilityIds.length == 1 ? doctor.facilityIds.first : null;
      _consultationMinutes =
          doctor.consultationMinutesFor(_selectedSpecialtyId);
    });
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final doctor = _selectedDoctor;
    if (doctor == null) return;

    setState(() {
      _loadingSlots = true;
      _slotsError = null;
      _pickedSlot = null;
    });

    if (!_isOnline) {
      if (doctor.facilityIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _slots = [];
          _slotsError = 'Este médico no tiene clínicas asociadas para citas presenciales.';
          _loadingSlots = false;
        });
        return;
      }
      if (_selectedFacilityId == null) {
        if (!mounted) return;
        setState(() {
          _slots = [];
          _loadingSlots = false;
        });
        return;
      }
    }

    try {
      final result = await _catalog.getAvailability(
        doctorId: doctor.userId,
        date: _dateIso,
        type: _isOnline ? 'ONLINE' : 'PRESENTIAL',
        specialtyId: _selectedSpecialtyId,
        facilityId: !_isOnline ? _selectedFacilityId : null,
      );
      if (!mounted) return;
      setState(() {
        _slots = result.slots;
        _consultationMinutes = result.durationMinutes;
        _loadingSlots = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _slotsError = e.message;
        _loadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slotsError = 'No se pudieron cargar los horarios';
        _loadingSlots = false;
      });
    }
  }

  Future<void> _pickDateFromCalendar() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (_selectedDoctor != null) _loadSlots();
    }
  }

  Future<void> _submitBooking() async {
    final doctor = _selectedDoctor;
    final slot = _pickedSlot;
    if (doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un médico para continuar')),
      );
      return;
    }
    if (slot == null || !slot.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un horario disponible (los ocupados no se pueden elegir)'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _apptService.createAppointment(
        doctorId: doctor.userId,
        dateTime: slot.dateTime,
        type: _isOnline ? 'ONLINE' : 'PRESENTIAL',
        facilityId: slot.facilityId,
        specialtyId: _selectedSpecialtyId,
        reason: _reasonController.text.trim(),
        durationMinutes: _consultationMinutes,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cita agendada con ${doctor.name} · ${slot.startTime}',
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Ver mis citas',
            textColor: Colors.white,
            onPressed: () {
              messenger.hideCurrentSnackBar();
              Navigator.pushNamed(context, AppRoutes.appointments);
            },
          ),
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) messenger.hideCurrentSnackBar();
      });
      setState(() {
        _pickedSlot = null;
        _reasonController.clear();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: const Text('Agendar Cita'),
      hideNavigation: false,
      backgroundColor: AppColors.background,
      child: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildStepHeader(
                            step: 1,
                            title: 'Área de atención',
                            subtitle:
                                'Elige la especialidad que necesitas',
                          ),
                          _buildSpecialtyFilter(),
                          const SizedBox(height: 24),
                          _buildStepHeader(
                            step: 2,
                            title: 'Elige tu médico',
                            subtitle:
                                'Toca al profesional con quien deseas agendar',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildSearch(),
                          ),
                          const SizedBox(height: 12),
                          _buildDoctorSelector(),
                          if (_selectedDoctor != null) ...[
                            const SizedBox(height: 28),
                            _buildStepHeader(
                              step: 3,
                              title: 'Fecha y hora',
                              subtitle:
                                  'Duración de consulta: $_consultationMinutes min (definida por el médico)',
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildModeToggle(),
                            ),
                            if (!_isOnline) ...[
                              const SizedBox(height: 16),
                              _buildFacilitySelector(),
                            ],
                            const SizedBox(height: 16),
                            _buildDateStrip(),
                            const SizedBox(height: 20),
                            _buildTimeSlots(),
                            const SizedBox(height: 28),
                            _buildStepHeader(
                              step: 4,
                              title: 'Motivo de la consulta',
                              subtitle:
                                  'Cuéntale al médico por qué solicitas la cita',
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: TextFormField(
                                controller: _reasonController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText:
                                      'Ej: Dolor de pecho, control de rutina, seguimiento de tratamiento...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  final t = v?.trim() ?? '';
                                  if (t.length < 10) {
                                    return 'Describe el motivo con al menos 10 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed:
                                      _isSubmitting ? null : _submitBooking,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.event_available_rounded),
                                  label: Text(
                                    _pickedSlot != null
                                        ? 'Agendar cita · ${_pickedSlot!.startTime}'
                                        : 'Agendar cita',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildStepHeader({
    required int step,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _specialtyChip(label: 'Todas', id: null),
          ..._specialties.map((s) => _specialtyChip(label: s.name, id: s.id)),
        ],
      ),
    );
  }

  Widget _specialtyChip({required String label, required String? id}) {
    final selected = _selectedSpecialtyId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedSpecialtyId = id;
            _selectedDoctor = null;
            _pickedSlot = null;
            _slots = [];
          });
        },
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar médico por nombre',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      onChanged: (v) => setState(() => _search = v),
    );
  }

  Widget _buildDoctorSelector() {
    final doctors = _filteredDoctors;
    if (doctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No hay médicos en esta especialidad.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: doctors.map((doctor) {
          final selected = _selectedDoctor?.userId == doctor.userId;
          final mins = doctor.consultationMinutesFor(_selectedSpecialtyId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectDoctor(doctor),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SafeAvatar(radius: 26, imageUrl: doctor.profilePic),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (doctor.specialties.isNotEmpty)
                              Text(
                                doctor.specialties.join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            Text(
                              'Consulta: $mins min',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DoctorRatingStars(
                              rating: doctor.rating,
                              size: 14,
                            ),
                            if (doctor.ratingCount > 0)
                              Text(
                                '${doctor.ratingCount} valoraciones',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          _modeOption('Presencial', false),
          _modeOption('Virtual', true),
        ],
      ),
    );
  }

  Widget _modeOption(String label, bool online) {
    final selected = _isOnline == online;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final doctor = _selectedDoctor;
          setState(() {
            _isOnline = online;
            _pickedSlot = null;
            if (!online && doctor != null && doctor.facilityIds.length == 1) {
              _selectedFacilityId = doctor.facilityIds.first;
            } else if (online) {
              _selectedFacilityId = null;
            } else {
              _selectedFacilityId = null;
            }
          });
          _loadSlots();
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacilitySelector() {
    final doctor = _selectedDoctor;
    if (doctor == null || doctor.facilityIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clínica / sede',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(doctor.facilityIds.length, (i) {
              final id = doctor.facilityIds[i];
              final name = i < doctor.facilityNames.length
                  ? doctor.facilityNames[i]
                  : 'Sede ${i + 1}';
              final selected = _selectedFacilityId == id;
              return FilterChip(
                label: Text(name),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedFacilityId = id;
                    _pickedSlot = null;
                  });
                  _loadSlots();
                },
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    const monthShort = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximos días',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: _pickDateFromCalendar,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('Calendario'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 28,
            itemBuilder: (_, i) {
              final date = todayDate.add(Duration(days: i));
              final selected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                  _loadSlots();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 72,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNames[date.weekday % 7],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        monthShort[date.month - 1],
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    if (_loadingSlots) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_slotsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text(_slotsError!, style: const TextStyle(color: Colors.red)),
            TextButton.icon(
              onPressed: _loadSlots,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (!_isOnline && _selectedFacilityId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Selecciona una clínica para ver los horarios presenciales.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (_slots.isEmpty) {
      final isWeekend = _selectedDate.weekday == DateTime.saturday ||
          _selectedDate.weekday == DateTime.sunday;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AppPanel(
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.event_busy_rounded, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isWeekend
                      ? 'Este día no tiene agenda presencial. Prueba un día entre lunes y sábado.'
                      : 'Sin horarios este día. El médico puede configurar su agenda en la clínica; también puedes probar otra fecha.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasAvailable = _slots.any((s) => s.available);
    if (!hasAvailable) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: AppPanel(
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.textSecondary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Todos los horarios de este día están ocupados. Elige otra fecha o tipo de consulta.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<AppointmentTimeSlot>.from(_slots)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Horarios',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Los horarios en gris ya están ocupados (virtual o presencial).',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sorted.map((slot) {
              final selected = _pickedSlot?.dateTime == slot.dateTime;
              final available = slot.available;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: available ? () => setState(() => _pickedSlot = slot) : null,
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: !available
                          ? Colors.grey.shade200
                          : selected
                              ? AppColors.primary
                              : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: !available
                            ? Colors.grey.shade400
                            : selected
                                ? AppColors.primary
                                : AppColors.primaryLight,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          slot.startTime,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: !available
                                ? Colors.grey.shade600
                                : selected
                                    ? Colors.white
                                    : AppColors.primary,
                            decoration: !available
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (!available)
                          Text(
                            'Ocupado',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (slot.facilityName != null && _isOnline)
                          Text(
                            slot.facilityName!,
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
