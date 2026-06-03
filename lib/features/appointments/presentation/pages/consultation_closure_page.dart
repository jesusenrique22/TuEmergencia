import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../data/appointment_api_service.dart';
import '../../domain/consultation_closure_templates.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/consultation_report.dart';

/// Formulario obligatorio al cerrar una consulta (fin de cita o botón Completar).
class ConsultationClosurePage extends StatefulWidget {
  final Appointment appointment;

  const ConsultationClosurePage({super.key, required this.appointment});

  @override
  State<ConsultationClosurePage> createState() => _ConsultationClosurePageState();
}

class _PendingAttachment {
  final String fileName;
  final String mimeType;
  final List<int> bytes;

  _PendingAttachment({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });
}

class _ConsultationClosurePageState extends State<ConsultationClosurePage> {
  final _service = AppointmentApiService();
  final _findings = TextEditingController();
  final _diagnosis = TextEditingController();
  final _medications = TextEditingController();
  final _instructions = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _noMedication = false;
  bool _saving = false;
  bool _showTemplateHelp = false;
  String? _selectedTemplateId;
  final List<_PendingAttachment> _attachments = [];

  bool get _isPresential => widget.appointment.type == AppointmentType.presential;

  @override
  void dispose() {
    _findings.dispose();
    _diagnosis.dispose();
    _medications.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _applyTemplate(ConsultationClosureTemplate t) {
    setState(() {
      _selectedTemplateId = t.id;
      if (t.findingsHint != null && t.findingsHint!.isNotEmpty) {
        _findings.text = t.findingsHint!;
      }
      if (t.diagnosisHint != null && t.diagnosisHint!.isNotEmpty) {
        _diagnosis.text = t.diagnosisHint!;
      }
      if (t.medicationsHint != null && t.medicationsHint!.isNotEmpty) {
        _medications.text = t.medicationsHint!;
      }
      if (t.instructionsHint != null && t.instructionsHint!.isNotEmpty) {
        _instructions.text = t.instructionsHint!;
      }
      _noMedication = t.defaultNoMedication;
    });
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Tomar foto del recetario'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Subir PDF'),
              onTap: () => Navigator.pop(ctx, null),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (source == null) {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final bytes = f.bytes;
      if (bytes == null) return;
      setState(() {
        _attachments.add(
          _PendingAttachment(
            fileName: f.name,
            mimeType: _mimeFor(f.name, f.extension),
            bytes: bytes,
          ),
        );
      });
      return;
    }

    final file = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _attachments.add(
        _PendingAttachment(
          fileName: file.name,
          mimeType: _mimeFor(file.name, null),
          bytes: bytes,
        ),
      );
    });
  }

  String _mimeFor(String name, String? ext) {
    final e = (ext ?? name.split('.').last).toLowerCase();
    if (e == 'pdf') return 'application/pdf';
    if (e == 'png') return 'image/png';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    final findings = _findings.text.trim();
    final diagnosis = _diagnosis.text.trim();
    final instructions = _instructions.text.trim();
    final medications = _medications.text.trim();

    if (findings.isEmpty || diagnosis.isEmpty || instructions.isEmpty) {
      _snack('Completa hallazgos, diagnóstico e instrucciones', error: true);
      return;
    }
    if (!_noMedication && medications.isEmpty) {
      _snack('Indica medicamentos o marca "Sin medicación"', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final report = ConsultationReport(
        id: '',
        appointmentId: widget.appointment.id,
        findings: findings,
        diagnosis: diagnosis,
        medications: medications,
        instructions: instructions,
        noMedication: _noMedication,
        templateId: _selectedTemplateId,
        createdAt: DateTime.now(),
      );

      await _service.updateStatus(
        widget.appointment.id,
        'COMPLETED',
        report: report,
        attachments: _attachments
            .map(
              (a) => (
                bytes: a.bytes,
                mimeType: a.mimeType,
                fileName: a.fileName,
              ),
            )
            .toList(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consulta cerrada. El paciente verá el resumen y podrá descargar el PDF.'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('No se pudo guardar el informe', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;

    return PopScope(
      canPop: !appt.needsClosure,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Cerrar consulta'),
        automaticallyImplyLeading: !appt.needsClosure,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeroPanel(
                    color: AppColors.primaryDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppStatusPill(
                          label: 'Informe obligatorio',
                          color: Colors.white,
                          icon: Icons.assignment_rounded,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appt.patientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          appt.needsClosure
                              ? 'La cita terminó. Completa este resumen para que el paciente tenga su receta e indicaciones.'
                              : 'Registra el resumen de la consulta antes de marcarla como completada.',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Plantillas rápidas (opcional)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _showTemplateHelp = !_showTemplateHelp),
                        icon: Icon(
                          _showTemplateHelp
                              ? Icons.expand_less_rounded
                              : Icons.help_outline_rounded,
                          size: 18,
                        ),
                        label: Text(_showTemplateHelp ? 'Ocultar' : '¿Qué es esto?'),
                      ),
                    ],
                  ),
                  if (_showTemplateHelp)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: const Text(
                        'Piensa en una plantilla como un borrador: al tocarla, los campos '
                        'se llenan con un texto de ejemplo (control, primera consulta, sin '
                        'medicación, etc.). Tú siempre puedes cambiar, borrar o ignorar ese '
                        'texto. No sustituye tu criterio clínico ni es obligatorio usarla.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: consultationClosureTemplates.map((t) {
                      final selected = _selectedTemplateId == t.id;
                      return FilterChip(
                        avatar: selected
                            ? const Icon(Icons.check_rounded, size: 16)
                            : null,
                        label: Text(t.label),
                        selected: selected,
                        onSelected: (_) => _applyTemplate(t),
                      );
                    }).toList(),
                  ),
                  if (templateById(_selectedTemplateId) case final t?) ...[
                    const SizedBox(height: 10),
                    Text(
                      t.description,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _field(
                    controller: _findings,
                    label: 'Qué presenta el paciente *',
                    hint: 'Síntomas, exploración, evolución…',
                    maxLines: 3,
                  ),
                  _field(
                    controller: _diagnosis,
                    label: 'Diagnóstico / impresión clínica *',
                    maxLines: 2,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sin medicación en esta consulta'),
                    value: _noMedication,
                    onChanged: (v) => setState(() {
                      _noMedication = v;
                      if (v) _medications.clear();
                    }),
                  ),
                  if (!_noMedication)
                    _field(
                      controller: _medications,
                      label: 'Medicamentos / receta *',
                      hint: 'Nombre, dosis, frecuencia, duración…',
                      maxLines: 4,
                    ),
                  _field(
                    controller: _instructions,
                    label: 'Instrucciones para el paciente *',
                    hint: 'Reposo, alarmas, próximo control…',
                    maxLines: 3,
                  ),
                  if (_isPresential) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.add_a_photo_rounded),
                      label: const Text('Foto o PDF del recetario (opcional)'),
                    ),
                    if (_attachments.isNotEmpty)
                      ..._attachments.map(
                        (a) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.attach_file_rounded),
                          title: Text(a.fileName, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () =>
                                setState(() => _attachments.remove(a)),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_saving ? 'Guardando…' : 'Finalizar y enviar al paciente'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
