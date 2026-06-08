import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Muestra credenciales temporales con texto seleccionable y botones de copiado.
Future<void> showStaffCredentialsDialog(
  BuildContext context, {
  required String title,
  required String email,
  required String temporaryPassword,
  String? name,
  String footer = 'Debe cambiarla al iniciar sesión.',
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name != null && name.isNotEmpty) ...[
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
          ],
          Text('Correo: $email'),
          const SizedBox(height: 12),
          const Text(
            'Contraseña temporal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              temporaryPassword,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            footer,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: temporaryPassword));
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Contraseña copiada')),
            );
          },
          child: const Text('Copiar contraseña'),
        ),
        TextButton(
          onPressed: () {
            final bundle = 'Correo: $email\nContraseña: $temporaryPassword';
            Clipboard.setData(ClipboardData(text: bundle));
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Correo y contraseña copiados')),
            );
          },
          child: const Text('Copiar todo'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
