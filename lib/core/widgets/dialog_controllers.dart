import 'package:flutter/material.dart';

/// Dispone [TextEditingController] tras la animación de cierre del diálogo.
///
/// No llamar [TextEditingController.dispose] justo después de [showDialog]:
/// los [TextField] siguen montados durante la transición y provocan
/// "used after being disposed" / `_dependents.isEmpty`.
void releaseDialogControllers(List<TextEditingController> controllers) {
  if (controllers.isEmpty) return;
  Future<void>.delayed(const Duration(milliseconds: 400), () {
    for (final c in controllers) {
      c.dispose();
    }
  });
}
