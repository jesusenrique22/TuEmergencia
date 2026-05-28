import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../patient_profile/domain/models/weight_control_record.dart';

/// Tabla de control de peso (solo lectura para el paciente).
class PatientWeightControlReadOnly extends StatelessWidget {
  final List<WeightControlRecord> controls;

  const PatientWeightControlReadOnly({super.key, required this.controls});

  @override
  Widget build(BuildContext context) {
    final padded = List<WeightControlRecord>.generate(
      3,
      (i) => i < controls.length ? controls[i] : const WeightControlRecord(),
    );
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Control de peso'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _WeightControlTable(controls: padded, readOnly: true),
          ),
        ],
      ),
    );
  }
}

/// Editor para el médico de Medicina General.
class PatientWeightControlEditor extends StatefulWidget {
  final List<WeightControlRecord> initial;
  final Future<void> Function(List<WeightControlRecord> controls) onSave;
  final bool saving;

  const PatientWeightControlEditor({
    super.key,
    required this.initial,
    required this.onSave,
    this.saving = false,
  });

  @override
  State<PatientWeightControlEditor> createState() =>
      _PatientWeightControlEditorState();
}

class _PatientWeightControlEditorState extends State<PatientWeightControlEditor> {
  static const _rows = [
    ('Peso (kg)', 'weightKg'),
    ('Grasa %', 'fatPercent'),
    ('Visceral', 'visceral'),
    ('Músculo', 'muscleKg'),
    ('IMC', 'bmi'),
    ('Fecha dosis', 'doseDate'),
    ('Dosis', 'dose'),
  ];

  List<List<TextEditingController>> _cells = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final col in _cells) {
      for (final t in col) {
        t.dispose();
      }
    }
    final padded = List<WeightControlRecord>.generate(
      3,
      (i) =>
          i < widget.initial.length
              ? widget.initial[i]
              : const WeightControlRecord(),
    );
    _cells = List.generate(3, (col) {
      final c = padded[col];
      return [
        TextEditingController(text: c.weightKg),
        TextEditingController(text: c.fatPercent),
        TextEditingController(text: c.visceral),
        TextEditingController(text: c.muscleKg),
        TextEditingController(text: c.bmi),
        TextEditingController(text: c.doseDate),
        TextEditingController(text: c.dose),
      ];
    });
  }

  @override
  void didUpdateWidget(covariant PatientWeightControlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _initControllers();
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final col in _cells) {
      for (final t in col) {
        t.dispose();
      }
    }
    super.dispose();
  }

  List<WeightControlRecord> _collect() {
    return List.generate(3, (col) {
      final colCells = _cells[col];
      return WeightControlRecord(
        weightKg: colCells[0].text.trim(),
        fatPercent: colCells[1].text.trim(),
        visceral: colCells[2].text.trim(),
        muscleKg: colCells[3].text.trim(),
        bmi: colCells[4].text.trim(),
        doseDate: colCells[5].text.trim(),
        dose: colCells[6].text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Control de peso'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _WeightControlTable(
              controls: const [],
              readOnly: false,
              cellControllers: _cells,
              rowLabels: _rows.map((r) => r.$1).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.saving ? null : () => widget.onSave(_collect()),
              icon: widget.saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar control de peso'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightControlTable extends StatelessWidget {
  final List<WeightControlRecord> controls;
  final bool readOnly;
  final List<List<TextEditingController>>? cellControllers;
  final List<String>? rowLabels;

  const _WeightControlTable({
    required this.controls,
    required this.readOnly,
    this.cellControllers,
    this.rowLabels,
  });

  static const _defaultRows = [
    'Peso (kg)',
    'Grasa %',
    'Visceral',
    'Músculo',
    'IMC',
    'Fecha dosis',
    'Dosis',
  ];

  @override
  Widget build(BuildContext context) {
    final labels = rowLabels ?? _defaultRows;
    final rowCount = labels.length;

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        AppColors.primary.withValues(alpha: 0.08),
      ),
      columns: const [
        DataColumn(label: Text('')),
        DataColumn(label: Text('Control 1')),
        DataColumn(label: Text('Control 2')),
        DataColumn(label: Text('Control 3')),
      ],
      rows: List.generate(rowCount, (rowIndex) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                labels[rowIndex],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            for (var col = 0; col < 3; col++)
              DataCell(
                readOnly
                    ? Text(_readCell(controls, col, rowIndex))
                    : SizedBox(
                        width: 92,
                        child: TextFormField(
                          controller: cellControllers![col][rowIndex],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                          inputFormatters: rowIndex < 5
                              ? [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.,/\-]'),
                                  ),
                                ]
                              : null,
                        ),
                      ),
              ),
          ],
        );
      }),
    );
  }

  String _readCell(List<WeightControlRecord> list, int col, int row) {
    if (col >= list.length) return '—';
    final c = list[col];
    switch (row) {
      case 0:
        return c.weightKg.isEmpty ? '—' : c.weightKg;
      case 1:
        return c.fatPercent.isEmpty ? '—' : c.fatPercent;
      case 2:
        return c.visceral.isEmpty ? '—' : c.visceral;
      case 3:
        return c.muscleKg.isEmpty ? '—' : c.muscleKg;
      case 4:
        return c.bmi.isEmpty ? '—' : c.bmi;
      case 5:
        return c.doseDate.isEmpty ? '—' : c.doseDate;
      case 6:
        return c.dose.isEmpty ? '—' : c.dose;
      default:
        return '—';
    }
  }
}
