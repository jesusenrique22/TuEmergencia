import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/dialog_controllers.dart';
import '../../../../core/widgets/profile_ui.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../../appointments/domain/models/appointment.dart';
import '../../data/doctor_api_service.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _api = DoctorApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _licenseController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DoctorFullProfile? _profile;
  List<SpecialtyCatalogItem> _catalog = [];
  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  String? _busySpecialtyId;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  StreamSubscription<void>? _profileRefreshSub;

  @override
  void initState() {
    super.initState();
    _profileRefreshSub =
        AppRealtime.onDoctorProfileRefresh.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _profileRefreshSub?.cancel();
    _nameController.dispose();
    _bioController.dispose();
    _licenseController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Tras hot reload el State puede conservar el tipo antiguo [DoctorProfileContext].
  void _migrateStaleProfileState() {
    final dynamic cached = _profile;
    if (cached != null && cached is! DoctorFullProfile) {
      _profile = null;
      if (!_loading) _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _profile = null;
    });
    try {
      final profile = await _api.getFullProfile();
      final catalog = await _api.listCatalogSpecialties();
      if (!mounted) return;
      _applyProfileToControllers(profile);
      setState(() {
        _profile = profile;
        _catalog = catalog;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyProfileToControllers(DoctorFullProfile profile) {
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _licenseController.text = profile.licenseNumber ?? '';
  }

  void _syncSession(DoctorFullProfile profile) {
    AppSession.updateCurrentUser(
      name: profile.name,
      avatarUrl: profile.avatarUrl,
    );
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    setState(() => _savingProfile = true);
    try {
      final updated = await _api.updateProfileDetails(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
      );
      if (!mounted) return;
      _syncSession(updated);
      setState(() {
        _profile = updated;
        _savingProfile = false;
      });
      _applyProfileToControllers(updated);
      _showSnack('Perfil actualizado', success: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingProfile = false);
      _showSnack(e.message);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

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

  Future<void> _pickCatalogSpecialty() async {
    if (_profile == null) return;
    final existing = _profile!.specialties.map((s) => s.id).toSet();
    final available =
        _catalog.where((s) => !existing.contains(s.id)).toList();
    if (available.isEmpty) {
      _showSnack('Ya tienes todas las especialidades del catálogo');
      return;
    }

    final picked = await showModalBottomSheet<SpecialtyCatalogItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SpecialtyPickerSheet(items: available),
    );
    if (picked == null || !mounted) return;
    await _addSpecialty(picked.id);
  }

  Future<void> _createNewSpecialty() async {
    final controller = TextEditingController();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar nueva especialidad',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quedará disponible en el catálogo para todos los médicos y pacientes.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Cardiología intervencionista',
                    prefixIcon: Icon(Icons.auto_awesome_rounded),
                  ),
                  onSubmitted: (_) {
                    final v = controller.text.trim();
                    if (v.length >= 2) Navigator.pop(ctx, v);
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    final v = controller.text.trim();
                    if (v.length < 2) return;
                    Navigator.pop(ctx, v);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Registrar y agregar a mi perfil'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    releaseDialogControllers([controller]);
    if (name == null || name.trim().isEmpty || !mounted) return;
    await _addSpecialtyByName(name.trim());
  }

  Future<void> _addSpecialty(String specialtyId) async {
    setState(() => _busySpecialtyId = specialtyId);
    try {
      final updated = await _api.addSpecialty(specialtyId);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _busySpecialtyId = null;
      });
      _showSnack('Especialidad agregada', success: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busySpecialtyId = null);
      _showSnack(e.message);
    }
  }

  Future<void> _addSpecialtyByName(String name) async {
    setState(() => _busySpecialtyId = 'new');
    try {
      final updated = await _api.createAndAddSpecialty(name);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _busySpecialtyId = null;
      });
      _showSnack('Especialidad registrada en el sistema', success: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busySpecialtyId = null);
      _showSnack(e.message);
    }
  }

  Future<void> _removeSpecialty(DoctorSpecialtyEntry specialty) async {
    final ok = await AppModernDialog.show(
      context: context,
      title: 'Quitar especialidad',
      subtitle: specialty.name,
      headerIcon: Icons.remove_circle_outline_rounded,
      accentColor: AppColors.emergency,
      destructive: true,
      confirmLabel: 'Quitar',
      confirmIcon: Icons.delete_outline_rounded,
      body: Text(
        'Los pacientes ya no podrán filtrarte por "${specialty.name}" al agendar citas.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busySpecialtyId = specialty.id);
    try {
      final updated = await _api.removeSpecialty(specialty.id);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _busySpecialtyId = null;
      });
      _showSnack('Especialidad eliminada', success: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busySpecialtyId = null);
      _showSnack(e.message);
    }
  }

  Future<void> _updateDuration(DoctorSpecialtyEntry specialty, int minutes) async {
    setState(() => _busySpecialtyId = specialty.id);
    try {
      final updated = await _api.updateSpecialtyDuration(specialty.id, minutes);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _busySpecialtyId = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busySpecialtyId = null);
      _showSnack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    _migrateStaleProfileState();
    final user = AppSession.currentUser;
    final profile = _profile;

    if (profile == null) {
      return ResponsiveScaffold(
        backgroundColor: AppColors.background,
        title: const Text('Mi perfil'),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
        ),
      );
    }

    final p = profile;

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      title: const Text('Mi perfil'),
      body: ProfileScreenLayout(
        loading: _loading,
        onRefresh: _load,
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileGradientHeader(
                  name: p.name,
                  subtitle: p.specialtySubtitle,
                  badgeLabel: 'Perfil médico',
                  badgeIcon: Icons.medical_services_rounded,
                  leading: SafeAvatar(
                    radius: 32,
                    imageUrl: p.avatarUrl.isNotEmpty
                        ? p.avatarUrl
                        : user?.avatarUrl ?? '',
                    placeholderIcon: Icons.person_rounded,
                  ),
                  stats: [
                    ProfileStatChip(
                      icon: Icons.star_rounded,
                      label: 'Calificación',
                      value: p.rating.toStringAsFixed(1),
                    ),
                    ProfileStatChip(
                      icon: Icons.rate_review_rounded,
                      label: 'Reseñas',
                      value: '${p.ratingCount}',
                    ),
                    ProfileStatChip(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Especialidades',
                      value: '${p.specialties.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPersonalSection(p),
                const SizedBox(height: 16),
                _buildSpecialtiesSection(p),
                const SizedBox(height: 16),
                _buildFacilitiesSection(p),
                const SizedBox(height: 16),
                _buildPasswordSection(),
                const SizedBox(height: 16),
                ProfileLogoutButton(
                  onPressed: () {
                    AppSession.clear();
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.login,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection(DoctorFullProfile profile) {
    return ProfileSectionCard(
      title: 'Información personal',
      icon: Icons.badge_outlined,
      children: [
        Text(
          'Estos datos se muestran a pacientes y clínicas en toda la app.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _licenseController,
          decoration: const InputDecoration(
            labelText: 'Nº de colegiado / licencia (opcional)',
            prefixIcon: Icon(Icons.verified_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _bioController,
          minLines: 3,
          maxLines: 5,
          maxLength: 600,
          decoration: const InputDecoration(
            labelText: 'Presentación profesional',
            hintText: 'Cuéntale a tus pacientes tu experiencia y enfoque…',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          profile.email,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        ProfileGradientButton(
          label: 'Guardar información',
          icon: Icons.save_rounded,
          loading: _savingProfile,
          onPressed: _saveProfile,
        ),
      ],
    );
  }

  Widget _buildSpecialtiesSection(DoctorFullProfile profile) {
    final busy = _busySpecialtyId != null;

    return ProfileSectionCard(
      title: 'Especialidades médicas',
      icon: Icons.medical_information_outlined,
      trailing: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      children: [
        Text(
          'Agrega o quita especialidades. Los pacientes te encontrarán al agendar citas según estas áreas.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        if (profile.specialties.isEmpty)
          AppPanel(
            color: AppColors.surfaceMuted,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Aún no tienes especialidades. Añade al menos una para aparecer en el catálogo.',
                  ),
                ),
              ],
            ),
          )
        else
          ...profile.specialties.map((s) => _SpecialtyDurationCard(
                specialty: s,
                busy: _busySpecialtyId == s.id,
                onRemove: () => _removeSpecialty(s),
                onDurationChanged: (m) => _updateDuration(s, m),
              )),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : _pickCatalogSpecialty,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Del catálogo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: busy ? null : _createNewSpecialty,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Nueva'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilitiesSection(DoctorFullProfile profile) {
    return ProfileSectionCard(
      title: 'Clínicas y sedes',
      icon: Icons.local_hospital_outlined,
      children: [
        Text(
          'Sedes donde atiendes. Se actualizan al aceptar invitaciones desde notificaciones.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 14),
        if (profile.facilities.isEmpty)
          const Text(
            'Sin clínicas vinculadas aún.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.facilities
                .map(
                  (f) => Chip(
                    avatar: Icon(
                      Icons.local_hospital_rounded,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.9),
                    ),
                    label: Text(f.name),
                    backgroundColor: AppColors.primaryLight,
                    side: BorderSide.none,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return ProfileSectionCard(
      title: 'Seguridad',
      icon: Icons.lock_outline_rounded,
      children: [
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
          validator: (v) => v == null || v.isEmpty ? 'Requerida' : null,
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
            if (v == null || v.isEmpty) return 'Requerida';
            if (v.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirmar contraseña',
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
          label: 'Actualizar contraseña',
          icon: Icons.shield_rounded,
          loading: _savingPassword,
          onPressed: _changePassword,
        ),
      ],
    );
  }
}

class _SpecialtyDurationCard extends StatelessWidget {
  final DoctorSpecialtyEntry specialty;
  final bool busy;
  final VoidCallback onRemove;
  final ValueChanged<int> onDurationChanged;

  const _SpecialtyDurationCard({
    required this.specialty,
    required this.busy,
    required this.onRemove,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  specialty.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Quitar especialidad',
                onPressed: busy ? null : onRemove,
                icon: const Icon(Icons.close_rounded, color: AppColors.emergency),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Duración de consulta',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: busy || specialty.durationMinutes <= 15
                    ? null
                    : () => onDurationChanged(specialty.durationMinutes - 5),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Expanded(
                child: Slider(
                  value: specialty.durationMinutes.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 21,
                  label: '${specialty.durationMinutes} min',
                  onChanged: busy
                      ? null
                      : (v) => onDurationChanged(v.round()),
                ),
              ),
              IconButton(
                onPressed: busy || specialty.durationMinutes >= 120
                    ? null
                    : () => onDurationChanged(specialty.durationMinutes + 5),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
              Text(
                '${specialty.durationMinutes} min',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecialtyPickerSheet extends StatefulWidget {
  final List<SpecialtyCatalogItem> items;

  const _SpecialtyPickerSheet({required this.items});

  @override
  State<_SpecialtyPickerSheet> createState() => _SpecialtyPickerSheetState();
}

class _SpecialtyPickerSheetState extends State<_SpecialtyPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elegir especialidad',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(
                          Icons.medical_services_rounded,
                          color: AppColors.primary.withValues(alpha: 0.9),
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: const Icon(Icons.add_circle_rounded,
                          color: AppColors.primary),
                      onTap: () => Navigator.pop(context, item),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
