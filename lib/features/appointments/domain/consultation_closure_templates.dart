/// Plantillas = textos de ayuda que el médico puede aplicar con un toque
/// para no escribir todo desde cero en cada consulta.
class ConsultationClosureTemplate {
  final String id;
  final String label;
  final String description;
  final String? findingsHint;
  final String? diagnosisHint;
  final String? medicationsHint;
  final String? instructionsHint;
  final bool defaultNoMedication;

  const ConsultationClosureTemplate({
    required this.id,
    required this.label,
    required this.description,
    this.findingsHint,
    this.diagnosisHint,
    this.medicationsHint,
    this.instructionsHint,
    this.defaultNoMedication = false,
  });
}

const consultationClosureTemplates = [
  ConsultationClosureTemplate(
    id: 'control',
    label: 'Control de seguimiento',
    description:
        'Rellena campos típicos de una cita de control (puedes editarlos después).',
    findingsHint: 'Paciente en control, refiere evolución estable.',
    diagnosisHint: 'Control de patología en seguimiento.',
    medicationsHint: 'Continuar tratamiento actual según indicación previa.',
    instructionsHint:
        'Mantener hábitos saludables. Regresar si empeoran síntomas o antes de la próxima cita.',
  ),
  ConsultationClosureTemplate(
    id: 'first_visit',
    label: 'Primera consulta',
    description: 'Estructura básica para una consulta inicial.',
    findingsHint: 'Paciente acude por primera vez. Revisar antecedentes en perfil.',
    diagnosisHint: 'Impresión diagnóstica según evaluación clínica.',
    medicationsHint: '',
    instructionsHint:
        'Explicar plan de tratamiento. Agendar seguimiento. Acudir a urgencias si signos de alarma.',
  ),
  ConsultationClosureTemplate(
    id: 'no_medication',
    label: 'Sin medicación nueva',
    description: 'Cuando no se prescribe farmacoterapia.',
    findingsHint: '',
    diagnosisHint: '',
    medicationsHint: '',
    instructionsHint: 'Reposo relativo, hidratación y vigilancia de síntomas.',
    defaultNoMedication: true,
  ),
];

ConsultationClosureTemplate? templateById(String? id) {
  if (id == null) return null;
  for (final t in consultationClosureTemplates) {
    if (t.id == id) return t;
  }
  return null;
}
