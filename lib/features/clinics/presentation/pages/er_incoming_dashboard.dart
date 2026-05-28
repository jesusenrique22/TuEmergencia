import 'package:flutter/material.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../ambulance/domain/models/ambulance_models.dart';
import '../../../ambulance/domain/models/ambulance_data_mock.dart';
import '../../../insurance/domain/models/insurance_models.dart';
import '../../../insurance/domain/models/insurance_data_mock.dart';

import '../../../notifications/presentation/widgets/notification_badge.dart';

class ERIncomingDashboard extends StatefulWidget {
  const ERIncomingDashboard({super.key});

  @override
  State<ERIncomingDashboard> createState() => _ERIncomingDashboardState();
}

class _ERIncomingDashboardState extends State<ERIncomingDashboard> {
  AmbulanceRequest? _selectedRequest;
  final List<AmbulanceRequest> _incomingAmbulances =
      AmbulanceDataMock.activeRequests;

  @override
  void initState() {
    super.initState();
    if (_incomingAmbulances.isNotEmpty) {
      _selectedRequest = _incomingAmbulances.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy para Command Center
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // Lado Izquierdo: Lista de Ambulancias en Camino
          Expanded(flex: 2, child: _buildInboundList()),
          // Lado Derecho: Detalle Clínico en Tiempo Real
          Expanded(
            flex: 3,
            child: _selectedRequest != null
                ? _buildTriageDetails(_selectedRequest!)
                : _buildNoSelectionPlaceholder(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.emergency, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMAND CENTER: EMERGENCIAS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Clínica Méndez Gimón • Sede Central',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: const Text(
              'ER ACTIVE: 4 CAMAS LIBRES',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Center(child: NotificationBadge()),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildInboundList() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'AMBULANCIAS EN TRANSITO',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _incomingAmbulances.length,
              itemBuilder: (context, index) {
                final request = _incomingAmbulances[index];
                bool isSelected = _selectedRequest?.id == request.id;
                return _buildInboundCard(request, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboundCard(AmbulanceRequest request, bool isSelected) {
    // Simulamos la búsqueda de la póliza del paciente
    final policy = InsuranceDataMock.activePolicies.firstWhere(
      (p) => p.patientId == request.patientId,
    );
    final insurance = InsuranceDataMock.companies.firstWhere(
      (c) => c.id == policy.insuranceId,
    );

    // Verificamos si es un seguro anclado a ESTA clínica (Méndez Gimón = clinic-001)
    bool isAnchoredPlan = insurance.clinicId == 'clinic-001';

    return GestureDetector(
      onTap: () => setState(() => _selectedRequest = request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withValues(alpha: 0.1)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAnchoredPlan
                ? Colors.green
                : (isSelected ? Colors.red : Colors.white10),
            width: isAnchoredPlan ? 3 : 2,
          ),
          boxShadow: isAnchoredPlan
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Juan Pérez',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ETA: 8 Minutos • VITA-04',
                        style: TextStyle(
                          color: isSelected ? Colors.redAccent : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildInsuranceBadge(insurance, isAnchoredPlan),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceBadge(HealthInsurance insurance, bool isAnchored) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAnchored
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAnchored ? Colors.green : Colors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAnchored ? Icons.stars : Icons.verified_user,
            size: 10,
            color: isAnchored ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            isAnchored ? 'PLAN INTERNO' : 'ASEGURADO',
            style: TextStyle(
              color: isAnchored ? Colors.green : Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageDetails(AmbulanceRequest request) {
    // Obtenemos el log clínico del mock
    final log = AmbulanceDataMock.historyLogs.firstWhere(
      (l) => l.requestId == request.id,
      orElse: () => AmbulanceDataMock.historyLogs.first,
    );

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MONITOR DE TRANSITO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _admitPatient(),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
                label: const Text(
                  'INGRESAR PACIENTE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildVitalSignsGrid(log),
          const SizedBox(height: 40),
          _buildClinicalNoteSection(log),
          const Spacer(),
          _buildEmergencyProfileBox(request),
        ],
      ),
    );
  }

  Widget _buildVitalSignsGrid(TransitMedicalLog log) {
    return Row(
      children: [
        _vitalMonitorBox(
          'P.A.',
          log.vitals.bloodPressure,
          'mmHg',
          Colors.blue,
          false,
        ),
        const SizedBox(width: 20),
        _vitalMonitorBox(
          'F.C.',
          '${log.vitals.heartRate}',
          'BPM',
          Colors.red,
          log.vitals.heartRate > 100,
        ),
        const SizedBox(width: 20),
        _vitalMonitorBox(
          'SAT%',
          '${log.vitals.saturation}%',
          'O2',
          Colors.green,
          log.vitals.saturation < 95,
        ),
      ],
    );
  }

  Widget _vitalMonitorBox(
    String label,
    String value,
    String unit,
    Color color,
    bool isAlert,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: isAlert ? Border.all(color: Colors.red, width: 2) : null,
          boxShadow: isAlert
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: isAlert ? Colors.red : color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: isAlert
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.white24,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalNoteSection(TransitMedicalLog log) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Text(
                'BITÁCORA DEL PARAMÉDICO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            log.clinicalNotes,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyProfileBox(AmbulanceRequest request) {
    final policy = InsuranceDataMock.activePolicies.firstWhere(
      (p) => p.patientId == request.patientId,
    );
    final insurance = InsuranceDataMock.companies.firstWhere(
      (c) => c.id == policy.insuranceId,
    );
    final coverage = InsuranceDataMock.coverages.firstWhere(
      (c) => c.insuranceId == insurance.id,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Image.network(
            insurance.logoUrl,
            height: 30,
            color: Colors.white,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.shield, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PÓLIZA VITA: ${policy.policyNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _miniBadge(
                      'ER: ${(coverage.erConsultationPercentage * 100).toInt()}%',
                    ),
                    const SizedBox(width: 8),
                    _miniBadge(
                      'LAB: ${(coverage.laboratoryPercentage * 100).toInt()}%',
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'O+ | Sin Alergias Críticas',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'ESTADO',
                style: TextStyle(color: Colors.white38, fontSize: 8),
              ),
              Text(
                policy.status == PolicyStatus.active
                    ? 'VERIFICADA'
                    : 'INACTIVA',
                style: TextStyle(
                  color: policy.status == PolicyStatus.active
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNoSelectionPlaceholder() {
    return const Center(
      child: Text(
        'SELECCIONE UNA AMBULANCIA PARA VER EL ESTADO CLÍNICO',
        style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _admitPatient() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PACIENTE INGRESADO EN SALA DE EMERGENCIAS'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
