import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../data/clinic_admin_api_service.dart';

/// Invitar médicos al sistema y desvincular los ya asignados a la sede.
class ClinicAssignDoctorPage extends StatefulWidget {
  const ClinicAssignDoctorPage({super.key});

  @override
  State<ClinicAssignDoctorPage> createState() => _ClinicAssignDoctorPageState();
}

class _ClinicAssignDoctorPageState extends State<ClinicAssignDoctorPage>
    with SingleTickerProviderStateMixin {
  final _api = ClinicAdminApiService();
  final _searchController = TextEditingController();

  late final TabController _tabs;

  List<ClinicDoctorListItem> _assignable = [];
  List<ClinicDoctorListItem> _inClinic = [];
  bool _loadingAssignable = true;
  bool _loadingInClinic = true;
  String? _errorAssignable;
  String? _errorInClinic;
  String? _invitingId;
  String? _removingId;
  bool _changesMade = false;
  StreamSubscription<Map<String, dynamic>>? _rosterSub;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _rosterSub = AppRealtime.chatSocket.onClinicRosterUpdated.listen((_) {
      _changesMade = true;
      _loadAssignable();
      _loadInClinic();
    });
    _loadAssignable();
    _loadInClinic();
  }

  @override
  void dispose() {
    _rosterSub?.cancel();
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(_changesMade);
      return;
    }
    navigator.pushReplacementNamed(AppRoutes.clinicAdminDashboard);
  }

  Future<void> _loadAssignable({String? search}) async {
    setState(() {
      _loadingAssignable = true;
      _errorAssignable = null;
    });
    try {
      final list = await _api.listAssignableDoctors(search: search);
      if (!mounted) return;
      setState(() {
        _assignable = list;
        _loadingAssignable = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorAssignable = e.message;
        _loadingAssignable = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorAssignable = e.toString();
        _loadingAssignable = false;
      });
    }
  }

  Future<void> _loadInClinic() async {
    setState(() {
      _loadingInClinic = true;
      _errorInClinic = null;
    });
    try {
      final list = await _api.listFacilityDoctors();
      if (!mounted) return;
      setState(() {
        _inClinic = list;
        _loadingInClinic = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorInClinic = e.message;
        _loadingInClinic = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorInClinic = e.toString();
        _loadingInClinic = false;
      });
    }
  }

  Future<void> _openCreateDoctor() async {
    final created = await Navigator.pushNamed(context, AppRoutes.adminCreateDoctor);
    if (created == true && mounted) {
      _changesMade = true;
      await Future.wait([_loadAssignable(), _loadInClinic()]);
    }
  }

  Future<void> _invite(ClinicDoctorListItem doctor) async {
    if (!doctor.canInvite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            doctor.inviteBlockedReason ??
                'Este médico no puede recibir invitaciones todavía.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ok = await AppModernDialog.showDoctorInvite(
      context,
      name: doctor.name,
      email: doctor.email,
      profilePic: doctor.profilePic,
      specialties: doctor.specialties,
    );

    if (ok != true || !mounted) return;

    setState(() => _invitingId = doctor.userId);
    try {
      final result = await _api.assignDoctor(doctor.userId);
      if (!mounted) return;
      _changesMade = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: AppColors.secondary),
      );
      await Future.wait([_loadAssignable(), _loadInClinic()]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _invitingId = null);
    }
  }

  Future<void> _unassign(ClinicDoctorListItem doctor) async {
    final onlyHere = doctor.facilityNames.length <= 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(onlyHere ? 'Eliminar médico' : 'Desvincular médico'),
        content: Text(
          onlyHere
              ? '¿Eliminar la cuenta de ${doctor.name}?\n\n'
                  'Solo está vinculado a esta clínica. '
                  'Un médico debe pertenecer al menos a una sede; '
                  'al eliminarlo dejará de existir en el sistema.'
              : '¿Quitar a ${doctor.name} de esta clínica?\n\n'
                  'Seguirá en el sistema y podrá atender en otras sedes, '
                  'pero ya no aparecerá aquí hasta que acepte una nueva invitación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(onlyHere ? 'Eliminar cuenta' : 'Desvincular'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _removingId = doctor.userId);
    try {
      await _api.unassignDoctor(doctor.userId, deleteAccount: onlyHere);
      if (!mounted) return;
      _changesMade = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            onlyHere
                ? 'Cuenta de ${doctor.name} eliminada'
                : '${doctor.name} desvinculado de la clínica',
          ),
        ),
      );
      await Future.wait([_loadAssignable(), _loadInClinic()]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _removingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: ResponsiveScaffold(
        hideNavigation: true,
        appBar: AppBar(
          title: const Text('Gestionar médicos'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _goBack,
          ),
          bottom: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Invitar'),
              Tab(text: 'En la clínica'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            Column(
              children: [
                _buildSearchBar(onSearch: _loadAssignable),
                _buildSubtitle(
                  'Médicos del sistema que aún no pertenecen a tu clínica',
                ),
                Expanded(child: _buildAssignableBody()),
              ],
            ),
            Column(
              children: [
                _buildSubtitle(
                  'Médicos vinculados a esta sede. Puedes desvincularlos sin borrar su cuenta.',
                ),
                Expanded(child: _buildInClinicBody()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar({required void Function({String? search}) onSearch}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o correo…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    onSearch();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (v) => onSearch(search: v.trim()),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
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

  Widget _buildAssignableBody() {
    if (_loadingAssignable) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorAssignable != null) {
      return _buildError(_errorAssignable!, () => _loadAssignable());
    }
    if (_assignable.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay médicos disponibles para invitar',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Todos pueden estar ya en tu clínica, con invitación pendiente '
                'o no hay más médicos registrados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _openCreateDoctor,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Registrar médico nuevo'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _assignable.length,
      itemBuilder: (_, i) => _buildInviteCard(_assignable[i]),
    );
  }

  Widget _buildInClinicBody() {
    if (_loadingInClinic) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorInClinic != null) {
      return _buildError(_errorInClinic!, _loadInClinic);
    }
    if (_inClinic.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aún no hay médicos en esta sede',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _tabs.animateTo(0),
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('Ir a invitar médico'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _inClinic.length,
      itemBuilder: (_, i) => _buildInClinicCard(_inClinic[i]),
    );
  }

  Widget _buildInviteCard(ClinicDoctorListItem d) {
    final busy = _invitingId == d.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SafeAvatar(radius: 26, imageUrl: d.profilePic),
            const SizedBox(width: 14),
            Expanded(child: _doctorInfo(d)),
            const SizedBox(width: 8),
            if (busy)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              FilledButton(
                onPressed: d.canInvite ? () => _invite(d) : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Invitar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInClinicCard(ClinicDoctorListItem d) {
    final busy = _removingId == d.userId;
    final otherFacilities =
        d.facilityNames.length > 1 ? d.facilityNames.join(', ') : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SafeAvatar(radius: 26, imageUrl: d.profilePic),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _doctorInfo(d),
                  if (otherFacilities != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'También en: $otherFacilities',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (busy)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _unassign(d),
                icon: const Icon(Icons.link_off_rounded, size: 18),
                label: const Text('Quitar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _doctorInfo(ClinicDoctorListItem d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          d.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        if (d.specialties.isNotEmpty)
          Text(
            d.specialties.join(' · '),
            style: const TextStyle(fontSize: 12, color: AppColors.primary),
          ),
        Text(
          d.email,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        if (d.canInvite == false && d.inviteBlockedReason != null)
          Text(
            d.inviteBlockedReason!,
            style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
          ),
      ],
    );
  }
}
