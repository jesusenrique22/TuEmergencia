import 'package:flutter/material.dart';

import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/staff_credentials_dialog.dart';
import '../../data/clinic_admin_api_service.dart';

class ClinicAmbulanceFleetPage extends StatefulWidget {
  const ClinicAmbulanceFleetPage({super.key});

  @override
  State<ClinicAmbulanceFleetPage> createState() => _ClinicAmbulanceFleetPageState();
}

class _ClinicAmbulanceFleetPageState extends State<ClinicAmbulanceFleetPage>
    with SingleTickerProviderStateMixin {
  final _api = ClinicAdminApiService();
  late final TabController _tabs;

  bool _loading = true;
  List<AmbulanceUnitItem> _units = [];
  List<AmbulanceStaffItem> _staff = [];
  String? _error;

  List<AmbulanceStaffItem> get _drivers =>
      _staff.where((s) => s.role == 'AMBULANCE_DRIVER').toList();

  List<AmbulanceStaffItem> get _paramedics =>
      _staff.where((s) => s.role == 'PARAMEDIC').toList();

  List<AmbulanceStaffItem> get _nurses =>
      _staff.where((s) => s.role == 'AMBULANCE_NURSE').toList();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.listAmbulances(),
        _api.listAmbulanceStaff(),
      ]);
      if (!mounted) return;
      setState(() {
        _units = results[0] as List<AmbulanceUnitItem>;
        _staff = results[1] as List<AmbulanceStaffItem>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createStaff({
    required String role,
    required String title,
  }) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
        ],
      ),
    );
    if (ok != true) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      return;
    }

    try {
      final result = await _api.createAmbulanceStaff(
        role: role,
        name: nameCtrl.text,
        email: emailCtrl.text,
        phone: phoneCtrl.text,
      );
      if (!mounted) return;
      await showStaffCredentialsDialog(
        context,
        title: 'Perfil creado',
        name: result.name,
        email: result.email,
        temporaryPassword: result.temporaryPassword,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
    }
  }

  Future<void> _createUnit() async {
    final plateCtrl = TextEditingController();
    final callSignCtrl = TextEditingController();
    String? selectedDriverId;
    String? selectedParamedicId;
    String? selectedNurseId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Nueva ambulancia'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: plateCtrl,
                    decoration: const InputDecoration(labelText: 'Placa *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: callSignCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Código de unidad',
                      hintText: 'Ej. VITA-04',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tripulación',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedDriverId,
                    decoration: const InputDecoration(labelText: 'Conductor'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                      ..._drivers.map(
                        (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => selectedDriverId = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedParamedicId,
                    decoration: const InputDecoration(labelText: 'Paramédico'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                      ..._paramedics.map(
                        (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => selectedParamedicId = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedNurseId,
                    decoration: const InputDecoration(labelText: 'Enfermero/a'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                      ..._nurses.map(
                        (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => selectedNurseId = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || plateCtrl.text.trim().isEmpty) {
      plateCtrl.dispose();
      callSignCtrl.dispose();
      return;
    }

    try {
      await _api.createAmbulance(
        plateNumber: plateCtrl.text,
        callSign: callSignCtrl.text,
        driverId: selectedDriverId,
        paramedicId: selectedParamedicId,
        nurseId: selectedNurseId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambulancia registrada')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      plateCtrl.dispose();
      callSignCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Movilización sanitaria'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => AppNavigation.safeBack(
            context,
            fallbackRoute: AppRoutes.clinicAdminDashboard,
          ),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 8),
        ],
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: 'Unidades (${_units.length})'),
                  Tab(text: 'Personal (${_staff.length})'),
                ],
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: _SummaryBanner(
                            units: _units.length,
                            drivers: _drivers.length,
                            paramedics: _paramedics.length,
                            nurses: _nurses.length,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: TabBarView(
                              controller: _tabs,
                              children: [
                                _UnitsTab(
                                  units: _units,
                                  onCreateUnit: _createUnit,
                                ),
                                _StaffTab(
                                  staff: _staff,
                                  onCreateDriver: () => _createStaff(
                                    role: 'AMBULANCE_DRIVER',
                                    title: 'Nuevo conductor',
                                  ),
                                  onCreateParamedic: () => _createStaff(
                                    role: 'PARAMEDIC',
                                    title: 'Nuevo paramédico',
                                  ),
                                  onCreateNurse: () => _createStaff(
                                    role: 'AMBULANCE_NURSE',
                                    title: 'Nuevo enfermero/a',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.units,
    required this.drivers,
    required this.paramedics,
    required this.nurses,
  });

  final int units;
  final int drivers;
  final int paramedics;
  final int nurses;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      color: AppColors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.emergency.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: AppColors.emergency),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Flota de emergencias',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '$units unidades · $drivers conductores · $paramedics paramédicos · $nurses enfermeros',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitsTab extends StatelessWidget {
  const _UnitsTab({
    required this.units,
    required this.onCreateUnit,
  });

  final List<AmbulanceUnitItem> units;
  final VoidCallback onCreateUnit;

  @override
  Widget build(BuildContext context) {
    final addButton = FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: AppColors.emergency),
      onPressed: onCreateUnit,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Nueva unidad'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            if (compact) ...[
              const AppSectionHeader(
                title: 'Unidades de traslado',
                subtitle: 'Cada unidad puede tener conductor, paramédico y enfermero',
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: addButton),
            ] else
              AppSectionHeader(
                title: 'Unidades de traslado',
                subtitle: 'Cada unidad puede tener conductor, paramédico y enfermero',
                trailing: addButton,
              ),
            const SizedBox(height: 16),
            if (units.isEmpty)
              _EmptyPanel(
                icon: Icons.local_shipping_outlined,
                title: 'Sin ambulancias registradas',
                message:
                    'Registra tu primera unidad para asignar tripulación y recibir emergencias.',
                actionLabel: 'Registrar ambulancia',
                onAction: onCreateUnit,
              )
            else
              ...units.map(
                (u) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UnitCard(unit: u),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StaffTab extends StatelessWidget {
  const _StaffTab({
    required this.staff,
    required this.onCreateDriver,
    required this.onCreateParamedic,
    required this.onCreateNurse,
  });

  final List<AmbulanceStaffItem> staff;
  final VoidCallback onCreateDriver;
  final VoidCallback onCreateParamedic;
  final VoidCallback onCreateNurse;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const AppSectionHeader(
          title: 'Personal prehospitalario',
          subtitle: 'Perfiles que pueden iniciar sesión y ver emergencias asignadas',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StaffAddChip(
              label: 'Conductor',
              icon: Icons.badge_rounded,
              onTap: onCreateDriver,
            ),
            _StaffAddChip(
              label: 'Paramédico',
              icon: Icons.medical_services_rounded,
              onTap: onCreateParamedic,
            ),
            _StaffAddChip(
              label: 'Enfermero/a',
              icon: Icons.healing_rounded,
              onTap: onCreateNurse,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (staff.isEmpty)
          _EmptyPanel(
            icon: Icons.groups_outlined,
            title: 'Sin personal registrado',
            message: 'Crea conductores, paramédicos o enfermeros y asígnalos a cada unidad.',
            actionLabel: 'Agregar conductor',
            onAction: onCreateDriver,
          )
        else
          AppPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < staff.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _StaffRow(member: staff[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit});

  final AmbulanceUnitItem unit;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.emergency.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: AppColors.emergency),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Placa ${unit.plateNumber}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: unit.status),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tripulación',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CrewChip(label: 'Conductor', name: unit.driverName),
              _CrewChip(label: 'Paramédico', name: unit.paramedicName),
              _CrewChip(label: 'Enfermero/a', name: unit.nurseName),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.member});

  final AmbulanceStaffItem member;

  IconData get _icon {
    return switch (member.role) {
      'PARAMEDIC' => Icons.medical_services_rounded,
      'AMBULANCE_NURSE' => Icons.healing_rounded,
      _ => Icons.badge_rounded,
    };
  }

  Color get _color {
    return switch (member.role) {
      'PARAMEDIC' => Colors.teal,
      'AMBULANCE_NURSE' => Colors.deepPurple,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _color.withValues(alpha: 0.12),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              member.roleLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrewChip extends StatelessWidget {
  const _CrewChip({required this.label, required this.name});

  final String label;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final assigned = name != null && name!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: assigned ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: assigned ? AppColors.border : AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            assigned ? name! : 'Sin asignar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: assigned ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final available = status == 'AVAILABLE';
    final color = available ? Colors.green : AppColors.emergency;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'Disponible' : status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _StaffAddChip extends StatelessWidget {
  const _StaffAddChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text('Agregar $label'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
