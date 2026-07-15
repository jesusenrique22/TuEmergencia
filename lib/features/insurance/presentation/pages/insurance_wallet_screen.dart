import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/experience/experience_header.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/promo/promo_carousel.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../domain/models/insurance_models.dart';
import '../../domain/services/pdf_service.dart';
import '../../domain/services/insurance_api_service.dart';

class InsuranceWalletScreen extends StatefulWidget {
  const InsuranceWalletScreen({super.key});

  @override
  State<InsuranceWalletScreen> createState() => _InsuranceWalletScreenState();
}

class _InsuranceWalletScreenState extends State<InsuranceWalletScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  PatientPolicy? _activePolicy;
  List<MedicalInvoice> _recentInvoices = [];
  List<HealthInsurance> _availableCompanies = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final policy = await InsuranceApiService.instance.getMyPolicy();
      final invoices = await InsuranceApiService.instance.getMyInvoices();
      final companies = await InsuranceApiService.instance.getCompanies();

      setState(() {
        _activePolicy = policy;
        _recentInvoices = invoices;
        _availableCompanies = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo cargar la información de seguros. Verifica tu conexión.';
        _isLoading = false;
      });
    }
  }

  void _showAddInsuranceSheet() {
    if (_availableCompanies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay aseguradoras disponibles en este momento.')),
      );
      return;
    }

    HealthInsurance? selectedCompany = _availableCompanies.first;
    final policyController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Asociar Seguro Médico',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Elige una de las aseguradoras asociadas a VITA Network e introduce tu número de póliza.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<HealthInsurance>(
                      value: selectedCompany,
                      decoration: InputDecoration(
                        labelText: 'Compañía Aseguradora',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _availableCompanies.map((c) {
                        return DropdownMenuItem<HealthInsurance>(
                          value: c,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  c.logoUrl,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(c.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedCompany = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: policyController,
                      decoration: InputDecoration(
                        labelText: 'Número de Póliza',
                        hintText: 'Ej: MC-2026-12345',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa tu número de póliza';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setSheetState(() {
                                  isSaving = true;
                                });

                                try {
                                  await InsuranceApiService.instance.updateMyPolicy(
                                    insuranceId: selectedCompany!.id,
                                    policyNumber: policyController.text.trim(),
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Seguro médico actualizado con éxito.'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                    _loadData();
                                  }
                                } catch (e) {
                                  setSheetState(() {
                                    isSaving = false;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al asociar seguro: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Registrar Seguro'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      hideAppBar: true,
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: ExperienceHeader(
                        title: 'Mis seguros',
                        subtitle: 'Pólizas activas, copagos y actividad reciente.',
                        badge: _activePolicy != null ? '1 póliza' : '0 pólizas',
                        icon: Icons.shield_rounded,
                        gradient: AppColors.insuranceGradient,
                        actions: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                          ),
                          IconButton(
                            onPressed: _showAddInsuranceSheet,
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: PromoCarousel(
                          offers: PromoMockData.insurancePromos,
                          onOfferTap: (_) {},
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text(
                          'Tus pólizas',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _activePolicy == null
                          ? Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.shield_outlined,
                                      size: 48, color: AppColors.textSecondary),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No tienes un seguro activo registrado',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Registra tu póliza para acceder a descuentos en consultas, ambulancias y farmacias.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _showAddInsuranceSheet,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Asociar Seguro'),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              height: 220,
                              child: PageView.builder(
                                controller: PageController(viewportFraction: 0.88),
                                itemCount: 1,
                                itemBuilder: (context, index) {
                                  return FadeSlideIn(
                                    index: index,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: _buildPolicyCard(context, _activePolicy!),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                        child: Text(
                          'Actividad reciente',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                      sliver: SliverToBoxAdapter(child: _buildRecentActivity(context)),
                    ),
                  ],
                ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    if (_recentInvoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'No hay actividad reciente de reclamos o facturas.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      children: _recentInvoices.asMap().entries.map((entry) {
        final inv = entry.value;
        final insurance = inv.insurance ??
            _availableCompanies.firstWhere(
              (c) => c.id == inv.insuranceId,
              orElse: () => HealthInsurance(id: 'unknown', name: 'Seguro', logoUrl: ''),
            );
        return FadeSlideIn(
          index: entry.key,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.promo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: AppColors.promo),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.copayAmount == 0.0
                            ? 'Cobertura total: Emergencia'
                            : 'Copago: \$${inv.copayAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Aseguradora: ${insurance.name}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                  onPressed: () => PdfService.generateInvoicePdf(
                    invoice: inv,
                    insurance: insurance,
                    patientName: 'Juan Pérez',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPolicyCard(BuildContext context, PatientPolicy policy) {
    final insurance = policy.insurance ??
        _availableCompanies.firstWhere(
          (c) => c.id == policy.insuranceId,
          orElse: () => HealthInsurance(id: 'unknown', name: 'Seguro', logoUrl: ''),
        );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: insurance.isGlobal
              ? [const Color(0xFF064E3B), const Color(0xFF047857)]
              : [const Color(0xFF0369A1), const Color(0xFF075985)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insurance.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  policy.status.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            policy.policyNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'TITULAR: JUAN PÉREZ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
