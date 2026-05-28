import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pregunta tras el registro si el paciente desea completar su historia clínica.
Future<bool?> showMedicalHistoryPrompt(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.medical_information_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        title: const Text(
          'Historia médica',
          textAlign: TextAlign.center,
        ),
        content: Text(
          '¿Desea rellenar su historia médica?\n\n'
          'Sus datos ayudan a los médicos a conocer antecedentes, alergias y medidas clínicas antes de la consulta.',
          textAlign: TextAlign.center,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Más tarde'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.edit_note_rounded, size: 20),
            label: const Text('Completar'),
          ),
        ],
      );
    },
  );
}
