export type PrescriptionImageIssue =
  | 'not_prescription'
  | 'blurry'
  | 'unreadable'
  | 'no_medications';

export class PrescriptionImageError extends Error {
  readonly issue: PrescriptionImageIssue;
  readonly statusCode = 422;

  constructor(message: string, issue: PrescriptionImageIssue) {
    super(message);
    this.name = 'PrescriptionImageError';
    this.issue = issue;
  }
}

export const PRESCRIPTION_ISSUE_MESSAGES: Record<PrescriptionImageIssue, string> = {
  not_prescription:
    'Esta imagen no parece una receta médica. Sube una foto de tu receta con los medicamentos prescritos.',
  blurry:
    'La foto se ve borrosa o con poca luz. Toma otra imagen más nítida, sin movimiento y con buena iluminación.',
  unreadable:
    'No pudimos leer la receta con claridad. Acerca la cámara, enfoca el texto y evita reflejos.',
  no_medications:
    'Parece una receta, pero no detectamos medicamentos. Verifica que se vean los nombres de los fármacos.',
};
