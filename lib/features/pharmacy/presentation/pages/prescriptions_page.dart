import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';

class PrescriptionsPage extends StatelessWidget {
  const PrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: const Text('Mis Recetas'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Carga de receta habilitada desde el módulo Farmacias',
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text(
          'Subir Receta',
          style: TextStyle(color: Colors.white),
        ),
      ),
      child: Column(
        children: const [
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('Activas')),
              Chip(label: Text('Expiradas')),
              Chip(label: Text('Descargadas')),
            ],
          ),
          Expanded(child: Center(child: Text('Lista de recetas'))),
        ],
      ),
    );
  }
}
