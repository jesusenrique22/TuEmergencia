import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../data/super_admin_api_service.dart';

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
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as OverviewStats;
        _facilityStats = results[1] as List<FacilityStatItem>;
        _pharmacyStats = results[2] as List<PharmacyStatItem>;
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

  Future<void> _showCreateFacility({void Function(String id, String name)? onCreated}) async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String type = 'CLINIC';
    bool saving = false;

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Registrar nueva clínica'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'La clínica quedará disponible para asignar administradores y médicos.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la clínica *',
                    hintText: 'Ej: Clínica Paraíso',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'CLINIC', child: Text('Clínica')),
                    DropdownMenuItem(value: 'HOSPITAL', child: Text('Hospital')),
                    DropdownMenuItem(
                      value: 'CONSULTORY',
                      child: Text('Consultorio'),
                    ),
                  ],
                  onChanged: saving ? null : (v) => setModal(() => type = v ?? 'CLINIC'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección *',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: 'Ciudad'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          addressCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nombre y dirección son obligatorios'),
                          ),
                        );
                        return;
                      }
                      setModal(() => saving = true);
                      try {
                        final facility = await _api.createFacility(
                          name: nameCtrl.text,
                          address: addressCtrl.text,
                          type: type,
                          city: cityCtrl.text,
                          phone: phoneCtrl.text,
                        );
                        final id = facility['_id']?.toString() ?? '';
                        final facilityName =
                            facility['name'] as String? ?? nameCtrl.text.trim();
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx, true);
                        onCreated?.call(id, facilityName);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Clínica "$facilityName" registrada'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                          _load();
                        }
                      } on ApiException catch (e) {
                        setModal(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (_) {
                        setModal(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Registrar clínica'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<void> _showCreateClinicAdmin() async {
    var facilities = await _api.listFacilities();
    if (!mounted) return;

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    List<(String id, String name)> options = facilities
        .map(
          (f) => (
            f['_id']?.toString() ?? '',
            f['name'] as String? ?? '',
          ),
        )
        .where((o) => o.$1.isNotEmpty)
        .toList();

    String? selectedId = options.isNotEmpty ? options.first.$1 : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Crear administrador de clínica'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                if (options.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'No hay clínicas registradas. Crea una clínica primero.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: selectedId,
                    decoration: const InputDecoration(labelText: 'Clínica'),
                    items: options
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.$1,
                            child: Text(o.$2),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModal(() => selectedId = v),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _showCreateFacility(
                      onCreated: (id, name) {
                        setModal(() {
                          options = [...options, (id, name)];
                          selectedId = id;
                        });
                      },
                    );
                  },
                  icon: const Icon(Icons.add_business_rounded, size: 20),
                  label: const Text('Registrar nueva clínica'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selectedId == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    final facilityId = selectedId;
    final adminName = nameCtrl.text;
    final adminEmail = emailCtrl.text;
    final adminPhone = phoneCtrl.text;

    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();

    if (ok != true || facilityId == null) return;

    try {
      final result = await _api.createClinicAdmin(
        name: adminName,
        email: adminEmail,
        phone: adminPhone,
        facilityId: facilityId,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cuenta creada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${result.name} — ${result.email}'),
              const SizedBox(height: 8),
              SelectableText('Contraseña: ${result.temporaryPassword}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.temporaryPassword));
                Navigator.pop(ctx);
              },
              child: const Text('Copiar contraseña'),
            ),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showCreatePharmacyAdmin() async {
    final pharmacies = await _api.listPharmacies();
    if (!mounted) return;
    await _showCreateAdminDialog(
      title: 'Crear administrador de farmacia',
      options: pharmacies
          .map(
            (p) => (
              p['_id']?.toString() ?? '',
              p['name'] as String? ?? '',
            ),
          )
          .toList(),
      optionLabel: 'Farmacia',
      onSubmit: (name, email, phone, optionId) => _api.createPharmacyAdmin(
        name: name,
        email: email,
        phone: phone,
        pharmacyId: optionId,
      ),
    );
  }

  Future<void> _showCreateAdminDialog({
    required String title,
    required List<(String id, String name)> options,
    required String optionLabel,
    required Future<StaffCreateResult> Function(
      String name,
      String email,
      String phone,
      String optionId,
    ) onSubmit,
  }) async {
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay opciones disponibles en el catálogo')),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedId = options.first.$1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedId,
                  decoration: InputDecoration(labelText: optionLabel),
                  items: options
                      .map(
                        (o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                      )
                      .toList(),
                  onChanged: (v) => setModal(() => selectedId = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      final result = await onSubmit(
        nameCtrl.text,
        emailCtrl.text,
        phoneCtrl.text,
        selectedId,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cuenta creada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${result.name} — ${result.email}'),
              const SizedBox(height: 8),
              SelectableText('Contraseña: ${result.temporaryPassword}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.temporaryPassword));
                Navigator.pop(ctx);
              },
              child: const Text('Copiar contraseña'),
            ),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
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
                        'Estadísticas globales, control de servicios por clínica/farmacia y creación de otros administradores.',
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
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _showCreatePharmacyAdmin,
                          icon: const Icon(Icons.local_pharmacy),
                          label: const Text('Admin de farmacia'),
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
}
