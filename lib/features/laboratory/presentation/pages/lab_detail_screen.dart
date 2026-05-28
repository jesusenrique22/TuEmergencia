// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/laboratory_models.dart';
import '../../domain/models/lab_data_mock.dart';

class LabDetailScreen extends StatefulWidget {
  final Laboratory laboratory;
  const LabDetailScreen({super.key, required this.laboratory});

  @override
  State<LabDetailScreen> createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends State<LabDetailScreen> {
  final List<LabService> _selectedServices = [];
  String _attendanceMode = 'office'; // 'office' o 'home'

  @override
  Widget build(BuildContext context) {
    final labServices = LabDataMock.services
        .where((s) => s.laboratoryId == widget.laboratory.id)
        .toList();

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Servicios Disponibles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...labServices.map((service) => _buildServiceCard(service)),
                  const SizedBox(height: 32),
                  if (widget.laboratory.offersHomeService) ...[
                    const Text(
                      'Modalidad de Atención',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAttendanceSelector(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCheckout(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.laboratory.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(widget.laboratory.logoUrl, fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(LabService service) {
    final isSelected = _selectedServices.contains(service);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.primaryLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    if (val!) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                },
              ),
            ],
          ),
          Text(
            '\$${service.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            children: [
              Chip(
                avatar: const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.orange,
                ),
                label: Text(
                  service.requirements,
                  style: const TextStyle(fontSize: 10, color: Colors.orange),
                ),
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text(
            'Visitar Sede',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          value: 'office',
          groupValue: _attendanceMode,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _attendanceMode = val!),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: const Text(
            'Servicio a Domicilio',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          value: 'home',
          groupValue: _attendanceMode,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _attendanceMode = val!),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCheckout() {
    if (_selectedServices.isEmpty) return const SizedBox.shrink();

    final total = _selectedServices.fold(0.0, (sum, item) => sum + item.price);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedServices.length} exámenes seleccionados',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                'Total: \$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reserva de Laboratorio procesada con éxito'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Confirmar Reserva',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
