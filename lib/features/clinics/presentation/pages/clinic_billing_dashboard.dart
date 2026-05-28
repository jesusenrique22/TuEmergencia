import 'package:flutter/material.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../insurance/domain/models/insurance_models.dart';
import '../../../insurance/domain/models/insurance_data_mock.dart';
import '../../../insurance/domain/services/pdf_service.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';

class ClinicBillingDashboard extends StatefulWidget {
  const ClinicBillingDashboard({super.key});

  @override
  State<ClinicBillingDashboard> createState() => _ClinicBillingDashboardState();
}

class _ClinicBillingDashboardState extends State<ClinicBillingDashboard> {
  // Datos simulados de facturas generadas por emergencias recientes
  final List<MedicalInvoice> _invoices = [
    MedicalInvoice(
      id: 'INV-8801',
      requestId: 'req-9901',
      patientId: 'pat-123',
      insuranceId: 'ins-001',
      subtotal: 150.0,
      coveredAmount: 150.0, // 100% cobertura ambulancia
      copayAmount: 0.0,
      status: InvoiceStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MedicalInvoice(
      id: 'INV-8802',
      requestId: 'req-9902',
      patientId: 'pat-456',
      insuranceId: 'ins-002',
      subtotal: 200.0,
      coveredAmount: 140.0, // 70% cobertura
      copayAmount: 60.0,
      status: InvoiceStatus.draft,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consola de Facturación VITA'),
        backgroundColor: Colors.white,
        actions: const [
          NotificationBadge(),
          SizedBox(width: 16),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildFinancialOverview(),
            const SizedBox(height: 32),
            Expanded(child: _buildInvoiceList()),
            _buildActionFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    double totalPending = _invoices.fold(
      0,
      (sum, inv) => sum + inv.coveredAmount,
    );

    return Row(
      children: [
        _statCard(
          'POR COBRAR SEGURAS',
          '\$${totalPending.toStringAsFixed(2)}',
          Colors.blue,
        ),
        const SizedBox(width: 20),
        _statCard('FACTURAS PENDIENTES', '${_invoices.length}', Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FACTURAS RECIENTES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _invoices.length,
            itemBuilder: (context, index) {
              final inv = _invoices[index];
              return _buildInvoiceTile(inv);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceTile(MedicalInvoice inv) {
    final insurance = InsuranceDataMock.companies.firstWhere(
      (c) => c.id == inv.insuranceId,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Image.network(insurance.logoUrl, height: 30, width: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.id,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  insurance.name,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${inv.coveredAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                inv.status.name.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(inv.status),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.blue,
              size: 20,
            ),
            onPressed: () => PdfService.generateInvoicePdf(
              invoice: inv,
              insurance: insurance,
              patientName: 'Juan Pérez', // Simulado
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.denied:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LOTE DE FACTURACIÓN ENVIADO A ASEGURADORAS'),
              backgroundColor: Colors.blue,
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
          'ENVIAR LOTE A ASEGURADORAS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
