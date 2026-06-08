import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/profile_ui.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../auth/domain/models/role.dart';
import '../../data/ambulance_crew_api_service.dart';

class _CrewProfileTheme {
  const _CrewProfileTheme({
    required this.badgeLabel,
    required this.badgeIcon,
    required this.badgeColor,
    required this.headerIcon,
    required this.accent,
    required this.subtitle,
  });

  final String badgeLabel;
  final IconData badgeIcon;
  final Color badgeColor;
  final IconData headerIcon;
  final Color accent;
  final String subtitle;

  static _CrewProfileTheme forRole(Role role) {
    return switch (role) {
      Role.paramedic => const _CrewProfileTheme(
          badgeLabel: 'Paramédico prehospitalario',
          badgeIcon: Icons.medical_services_rounded,
          badgeColor: Color(0xFF2DD4BF),
          headerIcon: Icons.medical_services_rounded,
          accent: Color(0xFF0D9488),
          subtitle: 'Atención en tránsito y triage móvil',
        ),
      Role.ambulanceNurse => const _CrewProfileTheme(
          badgeLabel: 'Enfermero/a móvil',
          badgeIcon: Icons.healing_rounded,
          badgeColor: Color(0xFFC4B5FD),
          headerIcon: Icons.healing_rounded,
          accent: Color(0xFF7C3AED),
          subtitle: 'Apoyo clínico durante el traslado',
        ),
      _ => const _CrewProfileTheme(
          badgeLabel: 'Conductor de ambulancia',
          badgeIcon: Icons.local_shipping_rounded,
          badgeColor: Color(0xFFFCA5A5),
          headerIcon: Icons.local_shipping_rounded,
          accent: AppColors.emergency,
          subtitle: 'Movilización y GPS en emergencias',
        ),
    };
  }
}

class AmbulanceCrewProfilePage extends StatefulWidget {
  const AmbulanceCrewProfilePage({super.key});

  @override
  State<AmbulanceCrewProfilePage> createState() => _AmbulanceCrewProfilePageState();
}

class _AmbulanceCrewProfilePageState extends State<AmbulanceCrewProfilePage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _api = AmbulanceCrewApiService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _certificationController = TextEditingController();
  final _bioController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;
  AmbulanceCrewProfileData? _profile;

  _CrewProfileTheme get _theme => _CrewProfileTheme.forRole(AppSession.activeRole);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _certificationController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.getProfile();
      if (!mounted) return;
      _applyProfile(profile);
      setState(() => _loading = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
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

  void _applyProfile(AmbulanceCrewProfileData profile) {
    _profile = profile;
    _nameController.text = profile.name;
    _phoneController.text = profile.phone ?? '';
    _licenseController.text = profile.licenseNumber ?? '';
    _certificationController.text = profile.certification ?? '';
    _bioController.text = profile.bio ?? '';
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _savingProfile = true);
    try {
      final updated = await _api.updateProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        licenseNumber: _licenseController.text,
        certification: _certificationController.text,
        bio: _bioController.text,
      );
      if (!mounted) return;
      _applyProfile(updated);
      await AppSession.updateCurrentUser(
        name: updated.name,
        phone: updated.phone,
      );
      setState(() => _savingProfile = false);
      _showSnack('Perfil actualizado', success: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingProfile = false);
      _showSnack(e.message);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _savingPassword = true);
    try {
      await _api.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _savingPassword = false);
      _showSnack('Contraseña actualizada', success: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingPassword = false);
      _showSnack(e.message);
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.secondary : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => AppNavigation.safeBack(
            context,
            fallbackRoute: AppRoutes.ambulanceDashboard,
          ),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : ProfileScreenLayout(
                  children: [
                    ProfileGradientHeader(
                      name: _profile?.name ?? '',
                      subtitle: _profile?.email ?? '',
                      badgeLabel: _theme.badgeLabel,
                      badgeIcon: _theme.badgeIcon,
                      badgeColor: _theme.badgeColor,
                      leading: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Icon(_theme.headerIcon, color: Colors.white, size: 32),
                      ),
                      stats: [
                        ProfileStatChip(
                          icon: Icons.badge_rounded,
                          label: 'Rol',
                          value: _roleShortLabel,
                        ),
                        if (_profile?.assignedUnit != null)
                          ProfileStatChip(
                            icon: Icons.local_shipping_rounded,
                            label: 'Unidad',
                            value: _profile!.assignedUnit!.displayName,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_profile?.assignedUnit != null) ...[
                      ProfileSectionCard(
                        title: 'Unidad asignada',
                        icon: Icons.local_shipping_outlined,
                        children: [
                          Text(
                            _profile!.assignedUnit!.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_profile!.assignedUnit!.facilityName != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Clínica: ${_profile!.assignedUnit!.facilityName}',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _crewTag('Conductor', _profile!.assignedUnit!.driverName),
                              _crewTag('Paramédico', _profile!.assignedUnit!.paramedicName),
                              _crewTag('Enfermero/a', _profile!.assignedUnit!.nurseName),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Form(
                      key: _profileFormKey,
                      child: ProfileSectionCard(
                        title: 'Datos personales',
                        icon: Icons.person_outline_rounded,
                        children: [
                          Text(
                            _theme.subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              prefixIcon: Icon(Icons.phone_rounded),
                            ),
                          ),
                          if (AppSession.activeRole != Role.ambulanceNurse) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _licenseController,
                              decoration: InputDecoration(
                                labelText: AppSession.activeRole == Role.paramedic
                                    ? 'Licencia paramédica'
                                    : 'Licencia de conducir',
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _certificationController,
                            decoration: InputDecoration(
                              labelText: AppSession.activeRole == Role.ambulanceNurse
                                  ? 'Registro profesional'
                                  : 'Certificaciones',
                              prefixIcon: const Icon(Icons.verified_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _bioController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notas de perfil',
                              hintText: 'Experiencia, idiomas, observaciones...',
                              prefixIcon: Icon(Icons.notes_rounded),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ProfileGradientButton(
                            label: 'Guardar perfil',
                            icon: Icons.save_rounded,
                            loading: _savingProfile,
                            onPressed: _saveProfile,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _passwordFormKey,
                      child: ProfileSectionCard(
                        title: 'Cambiar contraseña',
                        icon: Icons.lock_outline_rounded,
                        children: [
                          Text(
                            'Actualiza tu acceso. Si recibiste una contraseña temporal, cámbiala aquí.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrent,
                            decoration: InputDecoration(
                              labelText: 'Contraseña actual',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrent
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureCurrent = !_obscureCurrent),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              labelText: 'Nueva contraseña',
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNew
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirmar nueva contraseña',
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v != _newPasswordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          ProfileGradientButton(
                            label: 'Guardar nueva contraseña',
                            icon: Icons.lock_rounded,
                            loading: _savingPassword,
                            onPressed: _savePassword,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String get _roleShortLabel {
    return switch (AppSession.activeRole) {
      Role.paramedic => 'Paramédico',
      Role.ambulanceNurse => 'Enfermero/a',
      _ => 'Conductor',
    };
  }

  Widget _crewTag(String label, String? name) {
    final assigned = name != null && name.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: assigned ? _theme.accent.withValues(alpha: 0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: ${assigned ? name : '—'}',
        style: TextStyle(
          fontSize: 11,
          color: assigned ? _theme.accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}
