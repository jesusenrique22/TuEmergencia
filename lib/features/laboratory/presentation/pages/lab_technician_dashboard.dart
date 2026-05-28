import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/laboratory_models.dart';
import '../../domain/models/lab_data_mock.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';

class LabTechnicianDashboard extends StatefulWidget {
  const LabTechnicianDashboard({super.key});

  @override
  State<LabTechnicianDashboard> createState() => _LabTechnicianDashboardState();
}

class _LabTechnicianDashboardState extends State<LabTechnicianDashboard> {
  final List<LabResult> _pendingRequests = LabDataMock.results
      .where((r) => r.status == LabResultStatus.pending)
      .toList();

  void _showUploadModal(LabResult request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UploadResultModal(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel de Laboratorio'),
        actions: const [
          NotificationBadge(),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Solicitudes Pendientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Icon(Icons.filter_list, size: 20, color: Colors.grey),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _pendingRequests.length + 2, // Simulamos un par más
              itemBuilder: (context, index) {
                // Usamos el mock real o uno simulado para llenar la lista
                final result = index < _pendingRequests.length
                    ? _pendingRequests[index]
                    : LabDataMock.results.first;

                return _buildPendingCard(result);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _statCard('Pendientes', '12', Colors.orange),
          const SizedBox(width: 16),
          _statCard('Entregados', '45', Colors.green),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(LabResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.background,
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paciente: Juan Pérez',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'ID Examen: ${result.id}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showUploadModal(result),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cargar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _UploadResultModal extends StatelessWidget {
  final LabResult request;
  const _UploadResultModal({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cargar Resultado Médico',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Solicitud #${request.id}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Dropzone Placeholder
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                style: BorderStyle.none,
              ), // Aquí iría borde punteado
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 50,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Arrastra el PDF aquí o haz clic para buscar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Soporta: PDF, JPG, PNG',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'Observaciones del Técnico (Opcional)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Ej: Valores normales, se recomienda control en 6 meses...',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resultado publicado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Publicar Resultado',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
