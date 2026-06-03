import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/appointment.dart';
import '../models/consultation_report.dart';

class ConsultationReportPdfService {
  static Future<void> shareOrPrint({
    required Appointment appointment,
    required ConsultationReport report,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('d MMM yyyy, HH:mm', 'es').format(appointment.dateTime);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Resumen de consulta — VITA OS',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Fecha: $dateStr'),
          pw.Text('Médico: ${appointment.doctorName}'),
          pw.Text('Paciente: ${appointment.patientName}'),
          pw.Text(
            'Modalidad: ${appointment.type == AppointmentType.online ? 'Telemedicina' : 'Presencial'}',
          ),
          if (appointment.specialty.isNotEmpty)
            pw.Text('Especialidad: ${appointment.specialty}'),
          pw.Divider(),
          _section('Qué presenta el paciente', report.findings),
          _section('Diagnóstico / impresión clínica', report.diagnosis),
          _section(
            'Medicamentos / receta',
            report.noMedication
                ? 'Sin medicación indicada en esta consulta.'
                : report.medications,
          ),
          _section('Instrucciones y seguimiento', report.instructions),
          if (report.followUpDate != null)
            _section(
              'Próximo control sugerido',
              [
                DateFormat('d MMM yyyy', 'es').format(report.followUpDate!.toLocal()),
                if (report.followUpNote != null && report.followUpNote!.isNotEmpty)
                  report.followUpNote!,
              ].join('\n'),
            ),
          pw.Spacer(),
          pw.Text(
            'Documento generado desde Smart Medic. No sustituye prescripción física cuando la ley lo exija.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'consulta_${appointment.id}.pdf',
    );
  }

  static pw.Widget _section(String title, String body) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 14),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(body.isEmpty ? '—' : body, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }
}
