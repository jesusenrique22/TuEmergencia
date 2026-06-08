import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../data/super_admin_api_service.dart';
import '../widgets/super_admin_create_dialogs.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final _api = SuperAdminApiService();
  OverviewStats? _overview;
  List<FacilityStatItem> _facilityStats = [];
  List<PharmacyStatItem> _pharmacyStats = [];
  List<LaboratoryStatItem> _laboratoryStats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getOverview(),
        _api.getFacilityStats(),
        _api.getPharmacyStats(),
        _api.getLaboratoryStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as OverviewStats;
        _facilityStats = results[1] as List<FacilityStatItem>;
        _pharmacyStats = results[2] as List<PharmacyStatItem>;
        _laboratoryStats = results[3] as List<LaboratoryStatItem>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las estadísticas';
        _loading = false;
      });
    }
  }

  Future<void> _toggleFacilityService(FacilityStatItem item) async {
    try {
      await _api.setFacilityService(item.id, !item.serviceEnabled);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _togglePharmacyService(PharmacyStatItem item) async {
    try {
      await _api.setPharmacyService(item.id, !item.serviceEnabled);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleLaboratoryService(LaboratoryStatItem item) async {
    try {
      await _api.setLaboratoryService(item.id, !item.serviceEnabled);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  List<NamedOption> _mapOptions(List<Map<String, dynamic>> rows) {
    return rows
        .map(
          (row) => NamedOption(
            row['_id']?.toString() ?? row['id']?.toString() ?? '',
            row['name'] as String? ?? '',
          ),
        )
        .where((o) => o.id.isNotEmpty)
        .toList();
  }

  Future<void> _showCreateLaboratory({void Function(String id, String name)? onCreated}) async {
    final created = await showDialog<NamedOption>(
      context: context,
      builder: (_) => CreateLaboratoryDialog(api: _api),
    );
    if (created == null || !mounted) return;
    onCreated?.call(created.id, created.name);
    if (onCreated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laboratorio "${created.name}" registrado'),
          backgroundColor: AppColors.secondary,
        ),
      );
      _load();
    }
  }

  Future<void> _showCreateLabTech() async {
    final laboratories = await _api.listLaboratories();
    if (!mounted) return;

    final form = await showDialog<StaffFormData>(
      context: context,
      builder: (ctx) => StaffOptionPickerDialog(
        title: 'Crear perfil de laboratorio',
        optionLabel: 'Laboratorio',
        intro:
            'Cuenta de técnico para procesar exámenes (sangre, orina, heces, etc.).',
        options: _mapOptions(laboratories),
        registerNewLabel: 'Registrar nuevo laboratorio',
        registerNewIcon: Icons.biotech_rounded,
        onRegisterNew: (dialogCtx) => showDialog<NamedOption>(
          context: dialogCtx,
          builder: (_) => CreateLaboratoryDialog(api: _api),
        ),
      ),
    );
    if (form == null || !mounted) return;

    try {
      final result = await _api.createLabTech(
        name: form.name,
        email: form.email,
        phone: form.phone,
        laboratoryId: form.optionId,
      );
      if (!mounted) return;
      await showAccountCreatedDialog(
        context,
        result,
        roleLabel: 'Técnico de laboratorio',
      );
      if (mounted) _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showCreateFacility({void Function(String id, String name)? onCreated}) async {
    final created = await showDialog<NamedOption>(
      context: context,
      builder: (_) => CreateFacilityDialog(api: _api),
    );
    if (created == null || !mounted) return;
    onCreated?.call(created.id, created.name);
    if (onCreated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clínica "${created.name}" registrada'),
          backgroundColor: AppColors.secondary,
        ),
      );
      _load();
    }
  }

  Future<void> _showCreateClinicAdmin() async {
    final facilities = await _api.listFacilities();
    if (!mounted) return;

    final form = await showDialog<StaffFormData>(
      context: context,
      builder: (ctx) => StaffOptionPickerDialog(
        title: 'Crear administrador de clínica',
        optionLabel: 'Clínica',
        options: _mapOptions(facilities),
        registerNewLabel: 'Registrar nueva clínica',
        registerNewIcon: Icons.add_business_rounded,
        onRegisterNew: (dialogCtx) => showDialog<NamedOption>(
          context: dialogCtx,
          builder: (_) => CreateFacilityDialog(api: _api),
        ),
      ),
    );
    if (form == null || !mounted) return;

    try {
      final result = await _api.createClinicAdmin(
        name: form.name,
        email: form.email,
        phone: form.phone,
        facilityId: form.optionId,
      );
      if (!mounted) return;
      await showAccountCreatedDialog(context, result);
      if (mounted) _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showCreatePharmacyAdmin() async {
    final pharmacies = await _api.listPharmacies();
    if (!mounted) return;
    await _showCreateStaffAdmin(
      title: 'Crear administrador de farmacia',
      optionLabel: 'Farmacia',
      options: _mapOptions(pharmacies),
      onSubmit: (form) => _api.createPharmacyAdmin(
        name: form.name,
        email: form.email,
        phone: form.phone,
        pharmacyId: form.optionId,
      ),
    );
  }

  Future<void> _showCreateStaffAdmin({
    required String title,
    required String optionLabel,
    required List<NamedOption> options,
    required Future<StaffCreateResult> Function(StaffFormData form) onSubmit,
  }) async {
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay opciones disponibles en el catálogo')),
      );
      return;
    }

    final form = await showDialog<StaffFormData>(
      context: context,
      builder: (_) => StaffOptionPickerDialog(
        title: title,
        optionLabel: optionLabel,
        options: options,
      ),
    );
    if (form == null || !mounted) return;

    try {
      final result = await onSubmit(form);
      if (!mounted) return;
      await showAccountCreatedDialog(context, result);
      if (mounted) _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administración global VITA'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AppSession.clear();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Panel del jefe de la app',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Estadísticas globales, control de servicios y creación de administradores, farmacias y laboratorios.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      if (_overview != null) _buildOverview(_overview!),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCreateFacility(),
                              icon: const Icon(Icons.add_business_rounded),
                              label: const Text('Nueva clínica'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _showCreateClinicAdmin,
                              icon: const Icon(Icons.local_hospital),
                              label: const Text('Admin de clínica'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _showCreatePharmacyAdmin,
                              icon: const Icon(Icons.local_pharmacy),
                              label: const Text('Admin farmacia'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCreateLaboratory(),
                              icon: const Icon(Icons.biotech_rounded),
                              label: const Text('Nuevo lab.'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _showCreateLabTech,
                          icon: const Icon(Icons.science_rounded),
                          label: const Text('Perfil de laboratorio (técnico)'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Clínicas — pacientes vía app',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._facilityStats.map(_buildFacilityCard),
                      const SizedBox(height: 24),
                      const Text(
                        'Farmacias — pedidos y productos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._pharmacyStats.map(_buildPharmacyCard),
                      const SizedBox(height: 24),
                      const Text(
                        'Laboratorios — personal y exámenes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._laboratoryStats.map(_buildLaboratoryCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverview(OverviewStats s) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statChip('Pacientes', '${s.patients}', Colors.blue),
        _statChip('Médicos', '${s.doctors}', Colors.green),
        _statChip('Citas app', '${s.appointments}', AppColors.primary),
        _statChip('Pedidos farmacia', '${s.pharmacyOrders}', Colors.orange),
        _statChip('Adm. clínicas', '${s.clinicAdmins}', Colors.teal),
        _statChip('Adm. farmacias', '${s.pharmacyAdmins}', Colors.purple),
        _statChip('Técnicos lab.', '${s.labTechs}', const Color(0xFF7C3AED)),
        _statChip('Laboratorios', '${s.laboratories}', Colors.indigo),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(FacilityStatItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          '${item.city ?? ''} · ${item.appointmentsCount} citas · ${item.patientsViaApp} pacientes únicos',
        ),
        trailing: Switch(
          value: item.serviceEnabled,
          onChanged: (_) => _toggleFacilityService(item),
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(PharmacyStatItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          '${item.ordersCount} pedidos · ${item.productsCount} productos · \$${item.revenueTotal.toStringAsFixed(2)}',
        ),
        trailing: Switch(
          value: item.serviceEnabled,
          onChanged: (_) => _togglePharmacyService(item),
        ),
      ),
    );
  }

  Widget _buildLaboratoryCard(LaboratoryStatItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
          child: const Icon(Icons.biotech_rounded, color: Color(0xFF7C3AED)),
        ),
        title: Text(item.name),
        subtitle: Text('${item.staffCount} técnico(s) registrado(s)'),
        trailing: Switch(
          value: item.serviceEnabled,
          onChanged: (_) => _toggleLaboratoryService(item),
        ),
      ),
    );
  }
}
