import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/insurance_models.dart';
import '../../domain/models/insurance_data_mock.dart';
import '../../domain/services/pdf_service.dart';

class InsuranceWalletScreen extends StatelessWidget {
  const InsuranceWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final policies = InsuranceDataMock.activePolicies;

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bóveda de Seguros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_moderator),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Formulario para agregar seguro en preparación',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryHeader(policies.length),
          SizedBox(
            height: 250,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: policies.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: _buildPolicyCard(context, policies[index]),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(child: _buildRecentActivity()),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    // Simulamos facturas recientes para el paciente pat-123
    final recentInvoices = [
      MedicalInvoice(
        id: 'INV-8801',
        requestId: 'req-9901',
        patientId: 'pat-123',
        insuranceId: 'ins-001',
        subtotal: 150.0,
        coveredAmount: 150.0,
        copayAmount: 0.0,
        status: InvoiceStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: recentInvoices.length,
      itemBuilder: (context, index) {
        final inv = recentInvoices[index];
        final insurance = InsuranceDataMock.companies.firstWhere(
          (c) => c.id == inv.insuranceId,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergencia & Traslado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                    '-\$${inv.coveredAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    inv.copayAmount > 0
                        ? 'Copago: \$${inv.copayAmount}'
                        : 'Cubierto 100%',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  Icons.download_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => PdfService.generateInvoicePdf(
                  invoice: inv,
                  insurance: insurance,
                  patientName: 'Juan Pérez',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tus Pólizas Activas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Tienes $count cobertura${count == 1 ? '' : 's'} vinculada${count == 1 ? '' : 's'} a tu cuenta VITA OS.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, PatientPolicy policy) {
    // Buscamos la aseguradora para el diseño
    final insurance = InsuranceDataMock.companies.firstWhere(
      (c) => c.id == policy.insuranceId,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            insurance.isGlobal
                ? const Color(0xFF1E293B)
                : const Color(0xFF0369A1),
            insurance.isGlobal
                ? const Color(0xFF0F172A)
                : const Color(0xFF075985),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Image.network(
                          insurance.logoUrl,
                          height: 32,
                          color: Colors.white,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.shield,
                                color: Colors.white70,
                                size: 30,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      policy.policyNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TITULAR: JUAN PÉREZ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'VITA HEALTH NETWORK',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.nfc,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
