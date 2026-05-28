import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../data/clinic_admin_api_service.dart';

class ClinicAdminDashboard extends StatefulWidget {
  const ClinicAdminDashboard({super.key});

  @override
  State<ClinicAdminDashboard> createState() => _ClinicAdminDashboardState();
}

class _ClinicAdminDashboardState extends State<ClinicAdminDashboard> {
  final _api = ClinicAdminApiService();
  ClinicDashboardData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppSession.isLoggedIn) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
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
        _error = 'No se pudo conectar al servidor';
        _loading = false;
      });
    }
  }

  Future<void> _openInviteDoctor() async {
    final changed = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.clinicAssignDoctor,
    );
    if (changed == true) _load();
  }

  Future<void> _unassignDoctor(ClinicDoctorListItem doctor) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Desvincular médico'),
        content: Text(
          '¿Quitar a ${doctor.name} de ${_data?.facilityName ?? 'esta clínica'}?\n\n'
          'Seguirá en el sistema y en sus otras sedes, pero no atenderá aquí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.unassignDoctor(doctor.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${doctor.name} desvinculado')),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _data?.facilityName ?? 'Clínica';

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text('Admin — $name'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
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
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(name),
                        const SizedBox(height: 20),
                        _buildStats(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        if (_data!.pendingInvitations.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _buildPendingInvitationsSection(),
                        ],
                        const SizedBox(height: 28),
                        _buildDoctorsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(String facilityName) {
    return AppHeroPanel(
      color: AppColors.primaryDark,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppStatusPill(
                  label: 'Administración de clínica',
                  color: Colors.white,
                  icon: Icons.local_hospital_rounded,
                ),
                const SizedBox(height: 12),
                Text(
                  facilityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppSession.currentUser?.name ?? 'Administrador',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.medical_services_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final d = _data!;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Médicos en sede',
            '${d.doctorsCount}',
            Icons.people_rounded,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Citas hoy',
            '${d.appointmentsToday}',
            Icons.event_available_rounded,
            Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Acciones rápidas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _actionTile(
          icon: Icons.mail_outline_rounded,
          title: 'Invitar médico existente',
          subtitle: 'Envía una solicitud; el doctor debe aceptar para unirse a la sede',
          color: AppColors.primary,
          onTap: _openInviteDoctor,
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Registrar médico nuevo',
          subtitle: 'Crea cuenta y asócialo directamente a esta sede',
          color: Colors.teal,
          onTap: () async {
            final created = await Navigator.pushNamed(
              context,
              AppRoutes.adminCreateDoctor,
            );
            if (created == true) _load();
          },
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.lock_rounded,
          title: 'Cambiar contraseña',
          subtitle: 'Actualiza el acceso de tu cuenta de administrador',
          color: Colors.orange,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.clinicAdminPassword);
          },
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingInvitationsSection() {
    final invites = _data!.pendingInvitations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Invitaciones pendientes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${invites.length}',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Esperando que el médico acepte desde su cuenta',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        ...invites.map(
          (inv) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                child: const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
              ),
              title: Text(
                inv.doctorName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(inv.doctorEmail),
              trailing: const Chip(
                label: Text('Pendiente', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorsSection() {
    final doctors = _data!.doctors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Médicos en tu clínica',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${doctors.length}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (doctors.isEmpty)
          AppPanel(
            color: Colors.white,
            child: Column(
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aún no hay médicos en esta sede.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openInviteDoctor,
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: const Text('Invitar primer médico'),
                ),
              ],
            ),
          )
        else
          ...doctors.map((d) => _doctorCard(d)),
      ],
    );
  }

  Widget _doctorCard(ClinicDoctorListItem doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: SafeAvatar(radius: 24, imageUrl: doctor.profilePic),
        title: Text(
          doctor.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctor.specialties.isNotEmpty)
              Text(doctor.specialties.join(' · '), style: const TextStyle(fontSize: 12)),
            Text(doctor.email, style: const TextStyle(fontSize: 11)),
            if (doctor.facilityNames.length > 1)
              Text(
                'También en: ${doctor.facilityNames.where((n) => n != _data!.facilityName).join(', ')}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Desvincular de esta clínica',
          icon: const Icon(Icons.link_off_rounded, color: Colors.red),
          onPressed: () => _unassignDoctor(doctor),
        ),
      ),
    );
  }
}
