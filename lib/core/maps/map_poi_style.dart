import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Estilos visuales de POIs en mapa — desacoplados de pantallas concretas.
class MapPoiStyle {
  final Color color;
  final IconData icon;
  final String label;

  const MapPoiStyle({
    required this.color,
    required this.icon,
    required this.label,
  });

  static const styles = {
    'CLINIC': MapPoiStyle(
      color: AppColors.primary,
      icon: Icons.local_hospital_rounded,
      label: 'Clínicas',
    ),
    'LABORATORY': MapPoiStyle(
      color: Color(0xFF15803D),
      icon: Icons.biotech_rounded,
      label: 'Laboratorios',
    ),
    'PHARMACY': MapPoiStyle(
      color: Color(0xFFC2410C),
      icon: Icons.local_pharmacy_rounded,
      label: 'Farmacias',
    ),
    'PATIENT': MapPoiStyle(
      color: Colors.red,
      icon: Icons.location_on,
      label: 'Paciente',
    ),
    'AMBULANCE': MapPoiStyle(
      color: AppColors.emergency,
      icon: Icons.local_shipping_rounded,
      label: 'Ambulancias',
    ),
  };

  static MapPoiStyle forType(String type) =>
      styles[type] ??
      const MapPoiStyle(
        color: AppColors.textSecondary,
        icon: Icons.place_rounded,
        label: 'Punto',
      );
}
