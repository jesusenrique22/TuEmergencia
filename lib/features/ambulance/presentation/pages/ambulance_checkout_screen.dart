import 'package:flutter/material.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../domain/models/ambulance_models.dart';
import '../../domain/models/ambulance_data_mock.dart';
import '../../../clinics/domain/models/clinic_models.dart';
import '../../../clinics/domain/models/clinic_data_mock.dart';
import '../../../insurance/domain/services/insurance_calculator.dart';

class AmbulanceCheckoutScreen extends StatefulWidget {
  const AmbulanceCheckoutScreen({super.key});

  @override
  State<AmbulanceCheckoutScreen> createState() =>
      _AmbulanceCheckoutScreenState();
}

class _AmbulanceCheckoutScreenState extends State<AmbulanceCheckoutScreen> {
  AmbulanceCompany? _selectedCompany;
  AlliedClinic? _selectedClinic;
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();
  double _painLevel = 5;
  bool _isRequesting = false;
  double _estimatedDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedCompany = AmbulanceDataMock.companies.first;
  }

  double _calculateFare() {
    if (_selectedCompany == null || _selectedClinic == null) return 0.0;
    // Simulación: La distancia varía según la clínica (mockeado)
    _estimatedDistance = _selectedClinic!.id == 'clinic-001' ? 5.2 : 12.8;
    return _selectedCompany!.baseRate + (_estimatedDistance * 2.5);
  }

  void _requestAmbulance() async {
    if (_selectedClinic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una clínica de destino'),
        ),
      );
      return;
    }

    setState(() => _isRequesting = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _isRequesting = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text('¡Unidad Asignada!', textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'La unidad VITA-04 de ${_selectedCompany!.name} va en camino a tu ubicación con destino a ${_selectedClinic!.name}.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.of(
                this.context,
              ).pushReplacementNamed(AppRoutes.tracking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Solicitar Ambulancia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => AppNavigation.safeBack(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('1', 'Selecciona la empresa'),
            const SizedBox(height: 16),
            _buildCompanySelector(),
            const SizedBox(height: 32),
            _buildStepHeader('2', 'Clínica de Destino'),
            const SizedBox(height: 16),
            _buildClinicSelector(),
            const SizedBox(height: 32),
            _buildStepHeader('3', 'Motivo de la Emergencia'),
            const SizedBox(height: 16),
            _buildSymptomsInput(),
            const SizedBox(height: 24),
            _buildPainSelector(),
            const SizedBox(height: 24),
            _buildHistoryInput(),
            const SizedBox(height: 32),
            _buildStepHeader('4', 'Resumen de Cotización'),
            const SizedBox(height: 16),
            _buildPriceSummary(),
            const SizedBox(height: 40),
            _buildRequestButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanySelector() {
    return Column(
      children: AmbulanceDataMock.companies.map((company) {
        bool isSelected = _selectedCompany?.id == company.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedCompany = company),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                SafeAvatar(radius: 24, imageUrl: company.logoUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    company.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClinicSelector() {
    // Solo mostramos clínicas con Sala de Emergencia (ER)
    final erClinics = ClinicDataMock.clinics
        .where((c) => c.hasEmergencyRoom)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AlliedClinic>(
          isExpanded: true,
          hint: const Text('Selecciona una clínica'),
          value: _selectedClinic,
          items: erClinics.map((clinic) {
            return DropdownMenuItem(
              value: clinic,
              child: Text(clinic.name, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedClinic = val),
        ),
      ),
    );
  }

  Widget _buildSymptomsInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.report_problem_outlined,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                '¿Qué síntomas presenta el paciente?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _symptomsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Ej: Dolor abdominal fuerte, dificultad para respirar...',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nivel de Dolor / Malestar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Leve',
                style: TextStyle(color: Colors.green.shade700, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Severo',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: _painLevel,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Color.lerp(Colors.green, Colors.red, _painLevel / 10),
            onChanged: (val) => setState(() => _painLevel = val),
          ),
          Center(
            child: Text(
              'Escala: ${_painLevel.toInt()} / 10',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.lerp(Colors.green, Colors.red, _painLevel / 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Antecedentes Médicos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _historyController,
            decoration: InputDecoration(
              hintText:
                  'Ej: Hipertenso, Diabético, Alérgico a la Penicilina...',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    final subtotal = _calculateFare();
    if (subtotal == 0) return const SizedBox.shrink();

    final breakdown = InsuranceCalculator.calculateCopay(
      subtotal: subtotal,
      category: 'ambulance',
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Subtotal del Servicio',
            '\$${subtotal.toStringAsFixed(2)}',
            isBold: false,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Cobertura Seguro (${(breakdown['percentage']! * 100).toInt()}%)',
            '-\$${breakdown['coveredAmount']!.toStringAsFixed(2)}',
            isBold: false,
            valueColor: Colors.greenAccent,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          _buildSummaryRow(
            'Total a Pagar (Copago)',
            '\$${breakdown['totalToPay']!.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 22,
          ),
          const SizedBox(height: 8),
          Text(
            'Distancia estimada: ${_estimatedDistance.toStringAsFixed(1)} KM',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color valueColor = Colors.white,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: fontSize * 0.8),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestButton() {
    return ElevatedButton(
      onPressed: _isRequesting ? null : _requestAmbulance,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emergency,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isRequesting
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              'CONFIRMAR SOLICITUD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
