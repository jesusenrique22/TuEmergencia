import 'package:flutter/material.dart';

/// Cierra un diálogo tras quitar el foco del teclado.
/// Evita crashes por [TextEditingController] usado durante la animación de cierre.
void closeDialog<T>(BuildContext context, [T? result]) {
  FocusScope.of(context).unfocus();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) Navigator.pop(context, result);
  });
}
