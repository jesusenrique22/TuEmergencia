import 'package:flutter/material.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/appointment_api_service.dart';
import '../../../medical_history/domain/models/patient_medical_document.dart';
import '../../../medical_history/presentation/pages/medical_document_viewer_page.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/consultation_report.dart';
import '../../domain/services/consultation_report_pdf_service.dart';

/// Resumen de consulta visible para el paciente tras cierre del médico.
class ConsultationReportPatientCard extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback? onUpdated;

  const ConsultationReportPatientCard({
    super.key,
    required this.appointment,
    this.onUpdated,
  });

  @override
  State<ConsultationReportPatientCard> createState() =>
      _ConsultationReportPatientCardState();
}

class _ConsultationReportPatientCardState
    extends State<ConsultationReportPatientCard> {
  final _service = AppointmentApiService();
  bool _acknowledging = false;

  Appointment get appt => widget.appointment;
  ConsultationReport get report => appt.consultationReport!;

  String _fullUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base$path';
  }

  Future<void> _acknowledge() async {
    setState(() => _acknowledging = true);
    try {
      await _service.acknowledgeReport(appt.id);
      widget.onUpdated?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gracias. Quedó registrado que revisaste tu resumen.'),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _acknowledging = false);
    }
  }

  void _openAttachment(String url) {
    final doc = PatientMedicalDocument(
      id: url,
      category: MedicalDocumentCategory.prescription,
      title: 'Adjunto de consulta',
      fileName: url.split('/').last,
      mimeType: url.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
      fileUrl: url,
      fileSize: 0,
      createdAt: DateTime.now(),
    );
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MedicalDocumentViewerPage(
          document: doc,
          fileUrl: _fullUrl(url),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = report;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_information_rounded,
                  color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Resumen de tu consulta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (!r.patientAcknowledged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Nuevo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _block('Hallazgos de la consulta', r.findings),
          _block('Diagnóstico', r.diagnosis),
          _block(
            'Medicamentos',
            r.noMedication ? 'Sin medicación indicada' : r.medications,
          ),
          _block('Instrucciones', r.instructions),
          if (r.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Archivos adjuntos',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            ...r.attachmentUrls.map(
              (url) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file_rounded, size: 20),
                title: Text(url.split('/').last),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openAttachment(url),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ConsultationReportPdfService.shareOrPrint(
                    appointment: appt,
                    report: r,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Descargar PDF'),
                ),
              ),
            ],
          ),
          if (appt.patientNeedsToAcknowledge) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No es una firma en papel: solo confirmas en la app que '
                      'leíste el resumen de tu médico. Queda registrada la fecha.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _acknowledging ? null : _acknowledge,
              icon: _acknowledging
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Entendido, ya revisé mi resumen'),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Confirmaste que revisaste este resumen',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _block(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
