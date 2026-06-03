import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/appointment.dart';
import '../../domain/services/consultation_report_pdf_service.dart';

/// Acceso rápido para el médico al informe ya enviado al paciente.
class ConsultationReportDoctorChip extends StatelessWidget {
  final Appointment appointment;

  const ConsultationReportDoctorChip({super.key, required this.appointment});

  Future<void> _showSummary(BuildContext context) async {
    final r = appointment.consultationReport!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Informe enviado al paciente',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (r.patientAcknowledged) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'El paciente confirmó que lo revisó',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Aún no confirma lectura en la app',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: [
                    _line('Hallazgos', r.findings),
                    _line('Diagnóstico', r.diagnosis),
                    _line(
                      'Medicamentos',
                      r.noMedication ? 'Sin medicación' : r.medications,
                    ),
                    _line('Instrucciones', r.instructions),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => ConsultationReportPdfService.shareOrPrint(
                  appointment: appointment,
                  report: r,
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Ver o compartir PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ack = appointment.consultationReport!.patientAcknowledged;
    return OutlinedButton.icon(
      onPressed: () => _showSummary(context),
      icon: Icon(
        ack ? Icons.check_circle_outline_rounded : Icons.assignment_turned_in_rounded,
        size: 18,
      ),
      label: Text(
        ack ? 'Informe enviado · paciente confirmó' : 'Informe enviado · ver resumen',
      ),
    );
  }
}
