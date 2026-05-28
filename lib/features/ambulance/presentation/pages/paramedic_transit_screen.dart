import 'package:flutter/material.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/ambulance_models.dart';
import '../../domain/models/ambulance_data_mock.dart';

class ParamedicTransitScreen extends StatefulWidget {
  const ParamedicTransitScreen({super.key});

  @override
  State<ParamedicTransitScreen> createState() => _ParamedicTransitScreenState();
}

class _ParamedicTransitScreenState extends State<ParamedicTransitScreen> {
  late AmbulanceRequest _currentRequest;
  bool _isSavingLog = false;

  // Controladores para el formulario médico
  final _bpController = TextEditingController();
  final _hrController = TextEditingController();
  final _satController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tomamos la solicitud activa del mock para la prueba
    _currentRequest = AmbulanceDataMock.activeRequests.first;
  }

  void _markPatientOnboard() {
    setState(() {
      _currentRequest.status = AmbulanceStatus.patientOnboard;
    });
  }

  void _completeService() async {
    setState(() => _isSavingLog = true);
    // Simulación de entrega de datos al hospital
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isSavingLog = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Entrega Exitosa'),
            ],
          ),
          content: const Text(
            'Toda la bitácora médica y el perfil VITA han sido transferidos a la Clínica de recepción.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppNavigation.safeBack(this.context);
              },
              child: const Text(
                'CONTINUAR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentRequest.status == AmbulanceStatus.dispatched
              ? 'Navegación'
              : 'Registro Médico',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _currentRequest.status.name.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_currentRequest.status == AmbulanceStatus.dispatched)
                    _buildNavigationPhase()
                  else
                    _buildMedicalPhase(),
                ],
              ),
            ),
          ),
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildNavigationPhase() {
    return Column(
      children: [
        _buildPatientCard(),
        Container(
          height: 400,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_rounded, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Mapa de Ruta Activo',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Conectando con GPS...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalPhase() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmergencyProfile(), // Nueva sección de perfil cargado
          const SizedBox(height: 32),
          const Text(
            'Triage en Tránsito',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Registre los signos vitales cada 15 min.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildVitalField('P.A.', '120/80', _bpController, Icons.speed),
              const SizedBox(width: 16),
              _buildVitalField('F.C.', '75', _hrController, Icons.favorite),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildVitalField('SAT%', '98', _satController, Icons.opacity),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()), // Espaciador
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Notas Clínicas y Síntomas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Describa el estado actual del paciente...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyProfile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety, color: Colors.red),
              const SizedBox(width: 12),
              const Text(
                'PERFIL DE EMERGENCIA VITA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TIPO: O+',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfileItem('ALERGIAS:', 'Penicilina, AINES', Colors.red),
          const SizedBox(height: 8),
          _buildProfileItem(
            'ANTECEDENTES:',
            _currentRequest.backgroundHistory ?? 'Hipertensión Crónica',
            Colors.black87,
          ),
          const SizedBox(height: 8),
          _buildProfileItem(
            'MEDICACIÓN:',
            'Enalapril 10mg/día',
            Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paciente: Juan Pérez',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Urgencia: Plaza Venezuela',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (_currentRequest.initialSymptoms != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'MOTIVO: ${_currentRequest.initialSymptoms}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Llamando al centro de coordinación'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVitalField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter() {
    bool isDispatched = _currentRequest.status == AmbulanceStatus.dispatched;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ElevatedButton(
        onPressed: _isSavingLog
            ? null
            : (isDispatched ? _markPatientOnboard : _completeService),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDispatched ? Colors.blue : Colors.green,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isSavingLog
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isDispatched
                    ? 'MARCAR: PACIENTE ABORDADO'
                    : 'FINALIZAR Y REPORTAR',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_currentRequest.status) {
      case AmbulanceStatus.dispatched:
        return Colors.blue;
      case AmbulanceStatus.patientOnboard:
        return Colors.orange;
      case AmbulanceStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
