import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/dialog_controllers.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../../auth/domain/models/role.dart';
import '../../data/medical_history_api_service.dart';
import '../../../chat/data/chat_api_service.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../patient_profile/data/patient_profile_repository.dart';
import '../../../patient_profile/domain/models/patient_profile.dart';
import '../../../patient_profile/domain/models/weight_control_record.dart';
import '../widgets/medical_documents_section.dart';
import '../widgets/patient_antecedents_summary.dart';
import '../widgets/patient_weight_control_panel.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  final _service = MedicalHistoryApiService();
  final _chat = ChatApiService();

  // Shared state
  bool _loading = true;
  String? _error;

  // Patient view
  PatientMedicalRecord? _myRecord;

  // Doctor view — patient list
  List<DoctorPatientItem> _patients = [];
  DoctorPatientItem? _selectedPatient;
  PatientMedicalRecord? _selectedRecord;
  PatientProfile? _selectedProfile;
  PatientProfile? _myProfile;
  String? _initialPatientId;
  List<WeightControlRecord> _patientWeightControls = [];
  bool _loadingRecord = false;
  bool _savingWeightControls = false;
  String? _recordError;

  bool _didReadArgs = false;

  bool get _isDoctor => AppSession.activeRole == Role.doctor;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final id = args['patientId'];
      if (id is String && id.isNotEmpty) _initialPatientId = id;
    } else if (args is String && args.isNotEmpty && _isDoctor) {
      _initialPatientId = args;
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isDoctor) {
        final pts = await _service.getMyPatients();
        setState(() {
          _patients = pts;
          _loading = false;
        });
        final targetId = _initialPatientId;
        if (targetId != null && targetId.isNotEmpty) {
          final match = pts.where((p) => p.userId == targetId).firstOrNull;
          await _loadPatientRecord(
            match ??
                DoctorPatientItem(
                  userId: targetId,
                  name: 'Paciente',
                ),
          );
        }
      } else {
        await PatientProfileRepository.refreshFromApi();
        final record = await _service.getMyHistory();
        setState(() {
          _myRecord = record;
          _myProfile = PatientProfileRepository.activeProfile;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
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

  Future<void> _loadPatientRecord(DoctorPatientItem patient) async {
    setState(() {
      _selectedPatient = patient;
      _loadingRecord = true;
      _recordError = null;
      _selectedRecord = null;
      _selectedProfile = null;
    });
    try {
      final result = await _service.getPatientHistory(patient.userId);
      setState(() {
        _selectedRecord = result.record;
        _selectedProfile = result.profile;
        _patientWeightControls = result.weightControls;
        if (result.patientName != null && result.patientName!.isNotEmpty) {
          _selectedPatient = DoctorPatientItem(
            userId: patient.userId,
            name: result.patientName!,
            profilePic: patient.profilePic,
            bloodType: result.profile?.bloodType ?? patient.bloodType,
            chronicConditions:
                result.profile?.chronicConditions ?? patient.chronicConditions,
          );
        }
        _loadingRecord = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _recordError = e.message;
        _loadingRecord = false;
      });
    } catch (_) {
      setState(() {
        _recordError = 'No se pudo cargar el historial';
        _loadingRecord = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text(
          _isDoctor
              ? (_selectedPatient == null
                  ? 'Historial Médico'
                  : _selectedPatient!.name)
              : 'Mi historial clínico',
        ),
        actions: [
          if (_isDoctor && _selectedPatient != null)
            TextButton.icon(
              onPressed: () => setState(() {
                _selectedPatient = null;
                _selectedRecord = null;
              }),
              icon: const Icon(Icons.person_search_rounded),
              label: const Text('Cambiar'),
            ),
          if (_isDoctor && _selectedPatient != null && _selectedRecord != null) ...[
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: 'Enviar mensaje al paciente',
              onPressed: () => _sendMessageToPatient(_selectedPatient!),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Agregar entrada',
              onPressed: () => _showAddEntry(_selectedPatient!),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(_error!, _loadInitial)
              : _isDoctor
                  ? (_selectedPatient == null
                      ? _buildPatientSelector()
                      : _buildDoctorView())
                  : _buildPatientView(),
    );
  }

  Widget _buildError(String msg, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  DOCTOR: Patient selector list
  // ─────────────────────────────────────────────────

  Widget _buildPatientSelector() {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeroPanel(
            color: AppColors.primaryDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppStatusPill(
                  label: 'Vista médica',
                  color: Colors.white,
                  icon: Icons.health_and_safety_rounded,
                ),
                SizedBox(height: 18),
                Text(
                  'Historial de pacientes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Solo puedes ver el historial de pacientes con los que hayas tenido citas.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppSectionHeader(
            title: 'Mis pacientes',
            subtitle: '${_patients.length} paciente(s) registrado(s)',
          ),
          const SizedBox(height: 16),
          if (_patients.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline_rounded,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text(
                      'No tienes pacientes registrados aún.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cuando completes una consulta, el paciente aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._patients.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AppTappablePanel(
                  onTap: () => _loadPatientRecord(p),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        SafeAvatar(radius: 26, imageUrl: p.profilePic),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              if (p.bloodType != null)
                                Text(
                                  'Sangre: ${p.bloodType}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              if (p.chronicConditions != null &&
                                  p.chronicConditions!.isNotEmpty)
                                Text(
                                  p.chronicConditions!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.emergency,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  DOCTOR: Selected patient history
  // ─────────────────────────────────────────────────

  Widget _buildDoctorView() {
    if (_loadingRecord) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recordError != null) {
      return _buildError(_recordError!, () => _loadPatientRecord(_selectedPatient!));
    }
    final record = _selectedRecord!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatientWeightControlEditor(
            initial: _patientWeightControls,
            saving: _savingWeightControls,
            onSave: _saveWeightControls,
          ),
          const SizedBox(height: 24),
          PatientAntecedentsSummary(
            profile: _selectedProfile,
            record: record,
          ),
          const SizedBox(height: 24),
          MedicalDocumentsSection(
            readOnly: true,
            patientId: _selectedPatient?.userId,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Visitas registradas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${record.entries.length} entrada(s)',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (record.entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'Aún no hay entradas en el historial.\nCompleta una consulta para que se registre automáticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...record.entries.map((e) => _EntryCard(entry: e)),
        ],
      ),
    );
  }

  Future<void> _sendMessageToPatient(DoctorPatientItem patient) async {
    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mensaje a ${patient.name}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Escribe instrucciones, recordatorios o seguimiento...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    releaseDialogControllers([controller]);
    if (sent != true || text.isEmpty || !mounted) return;

    try {
      final conv = await _chat.getOrCreateConversation(patientId: patient.userId);
      await _chat.sendMessage(
        conversationId: conv.id,
        text: text,
        kind: ChatMessageKind.clinical,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mensaje enviado a ${patient.name}'),
          action: SnackBarAction(
            label: 'Ver chat',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.messages,
              arguments: {'conversationId': conv.id},
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveWeightControls(List<WeightControlRecord> controls) async {
    final patient = _selectedPatient;
    if (patient == null) return;
    setState(() => _savingWeightControls = true);
    try {
      await _service.updatePatientWeightControls(
        patientId: patient.userId,
        controls: controls,
      );
      setState(() {
        _patientWeightControls = controls;
        _savingWeightControls = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Control de peso guardado en el perfil del paciente'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      setState(() => _savingWeightControls = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      setState(() => _savingWeightControls = false);
    }
  }

  Future<void> _showAddEntry(DoctorPatientItem patient) async {
    String title = '';
    String description = '';
    String diagnosis = '';
    String treatment = '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nueva entrada — ${patient.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(
                'Título',
                'Ej: Revisión general',
                onChanged: (v) => title = v,
              ),
              const SizedBox(height: 10),
              _dialogField(
                'Descripción',
                'Síntomas y hallazgos',
                onChanged: (v) => description = v,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              _dialogField(
                'Diagnóstico',
                'Diagnóstico clínico',
                onChanged: (v) => diagnosis = v,
              ),
              const SizedBox(height: 10),
              _dialogField(
                'Tratamiento',
                'Medicamentos, indicaciones...',
                onChanged: (v) => treatment = v,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (title.trim().isEmpty || description.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await _service.addEntry(
        patientId: patient.userId,
        title: title.trim(),
        description: description.trim(),
        diagnosis: diagnosis.trim(),
        treatment: treatment.trim(),
      );
      await _loadPatientRecord(patient);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrada guardada correctamente'),
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

  Widget _dialogField(
    String label,
    String hint, {
    required void Function(String) onChanged,
    int maxLines = 1,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  // ─────────────────────────────────────────────────
  //  PATIENT: Own history
  // ─────────────────────────────────────────────────

  Widget _buildPatientView() {
    final record = _myRecord;
    final name = AppSession.currentUser?.name ?? 'Paciente';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(name),
          const SizedBox(height: 16),
          _buildPatientUploadPrompt(context),
          const SizedBox(height: 24),
          PatientAntecedentsSummary(
            profile: _myProfile,
            record: record,
          ),
          const SizedBox(height: 24),
          const MedicalDocumentsSection(),
          const SizedBox(height: 24),
          const Text(
            'Visitas pasadas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (record == null || record.entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'Aún no tienes visitas registradas.\nAgenda y completa tu primera consulta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...record.entries.map((e) => _EntryCard(entry: e)),
        ],
      ),
    );
  }

  Widget _buildPatientUploadPrompt(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.patientShareExams),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.upload_file_rounded,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subir exámenes para tu médico',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Toca aquí para laboratorio, radiografías o PDF',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
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

  Widget _buildProfileHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_myRecord?.bloodType != null)
                  Text(
                    'Sangre: ${_myRecord!.bloodType}',
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _EntryCard extends StatelessWidget {
  final MedicalHistoryEntry entry;

  const _EntryCard({required this.entry});

  String _fmt(DateTime d) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                _fmt(entry.date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'Dr. ${entry.doctorName}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (entry.diagnosis?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _LabeledText(
              label: 'Diagnóstico',
              value: entry.diagnosis!,
              color: Colors.purple,
            ),
          ],
          if (entry.treatment?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            _LabeledText(
              label: 'Tratamiento',
              value: entry.treatment!,
              color: Colors.teal,
            ),
          ],
        ],
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LabeledText({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: color.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}
