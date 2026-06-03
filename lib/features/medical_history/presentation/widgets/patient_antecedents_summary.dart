import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../patient_profile/domain/models/patient_profile.dart';
import '../../data/medical_history_api_service.dart';

/// Resumen de antecedentes del perfil clínico + historial médico.
class PatientAntecedentsSummary extends StatelessWidget {
  final PatientProfile? profile;
  final PatientMedicalRecord? record;

  const PatientAntecedentsSummary({
    super.key,
    this.profile,
    this.record,
  });

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'El paciente aún no ha completado sus antecedentes en el perfil clínico.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Antecedentes y datos clínicos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (profile != null) ...[
            const SizedBox(height: 6),
            Text(
              profile!.fullName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  List<Widget> _buildRows() {
    final items = <_RowData>[];
    final p = profile;
    final r = record;

    void text(String label, String? value, {IconData? icon, Color? color}) {
      if (value == null || value.trim().isEmpty) return;
      items.add(_RowData(
        label: label,
        value: value.trim(),
        icon: icon ?? Icons.info_outline_rounded,
        color: color ?? AppColors.primary,
      ));
    }

    void flag(String label, bool value) {
      items.add(_RowData(
        label: label,
        value: value ? 'Sí' : 'No',
        icon: Icons.check_circle_outline_rounded,
        color: value ? AppColors.emergency : AppColors.textSecondary,
      ));
    }

    final blood = p?.bloodType ?? r?.bloodType;
    text('Tipo de sangre', blood, icon: Icons.bloodtype_rounded, color: Colors.red);
    text('Alergias', p?.allergies ?? r?.allergies,
        icon: Icons.warning_amber_rounded, color: Colors.orange);
    text('Condiciones crónicas', p?.chronicConditions ?? r?.chronicConditions,
        icon: Icons.monitor_heart_rounded, color: Colors.purple);
    text('Medicación actual', p?.currentMedications ?? r?.currentMedications,
        icon: Icons.medication_rounded);
    text('Cirugías previas', p?.surgeries ?? r?.surgeries,
        icon: Icons.healing_rounded, color: Colors.teal);

    if (p != null) {
      flag('Hipertensión', p.hasHypertension);
      flag('Diabetes', p.hasDiabetes);
      flag('Asma bronquial', p.hasBronchialAsthma);
      flag('Fumador', p.isSmoker);
      text('COVID-19', _covidLabel(p.covidSeverity));
      text('Vacunas', p.vaccines, icon: Icons.vaccines_rounded);
      text('Peso', p.weightKg.isNotEmpty ? '${p.weightKg} kg' : null);
      text('Talla', p.heightCm.isNotEmpty ? '${p.heightCm} cm' : null);
      text('Ocupación', p.occupation);
      text('Seguro médico', p.insuranceProvider);
      text('Observaciones', p.observations);
    }

    return items
        .map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(row.icon, color: row.color, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        row.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  String? _covidLabel(String severity) {
    switch (severity.toUpperCase()) {
      case 'MILD':
        return 'Leve';
      case 'MODERATE':
        return 'Moderado';
      case 'SEVERE':
        return 'Grave';
      case 'NONE':
        return null;
      default:
        return severity;
    }
  }
}

class _RowData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RowData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
