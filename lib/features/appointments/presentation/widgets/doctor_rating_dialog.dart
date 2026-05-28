import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Diálogo para que el paciente califique al médico tras una cita completada.
Future<({int rating, String? comment})?> showDoctorRatingDialog(
  BuildContext context, {
  required String doctorName,
}) {
  return showDialog<({int rating, String? comment})>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _DoctorRatingDialog(doctorName: doctorName),
  );
}

class _DoctorRatingDialog extends StatefulWidget {
  final String doctorName;

  const _DoctorRatingDialog({required this.doctorName});

  @override
  State<_DoctorRatingDialog> createState() => _DoctorRatingDialogState();
}

class _DoctorRatingDialogState extends State<_DoctorRatingDialog> {
  int _stars = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Calificar consulta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Cómo fue tu experiencia con ${widget.doctorName}?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final value = i + 1;
                final filled = value <= _stars;
                return IconButton(
                  onPressed: () => setState(() => _stars = value),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Cuéntanos brevemente tu experiencia',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Más tarde'),
        ),
        FilledButton(
          onPressed: _stars < 1
              ? null
              : () {
                  final comment = _commentController.text.trim();
                  Navigator.pop(
                    context,
                    (
                      rating: _stars,
                      comment: comment.isEmpty ? null : comment,
                    ),
                  );
                },
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

/// Muestra estrellas de calificación (solo lectura).
class DoctorRatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;

  const DoctorRatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = rating >= i + 1 - 0.25;
          final half = !filled && rating > i && rating < i + 1;
          return Icon(
            filled
                ? Icons.star_rounded
                : half
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: Colors.amber.shade700,
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: size * 0.85,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
