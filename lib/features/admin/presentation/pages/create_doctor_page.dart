import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../auth/domain/models/role.dart';
import '../../../appointments/data/appointment_api_service.dart';
import '../../data/admin_api_service.dart' show CreateDoctorResult, FacilityCatalogItem;
import '../../data/clinic_admin_api_service.dart';
import '../../../appointments/domain/models/appointment.dart' show SpecialtyCatalogItem;

class CreateDoctorPage extends StatefulWidget {
  const CreateDoctorPage({super.key});

  @override
  State<CreateDoctorPage> createState() => _CreateDoctorPageState();
}

class _CreateDoctorPageState extends State<CreateDoctorPage> {
  final _formKey = GlobalKey<FormState>();
  final _clinicApi = ClinicAdminApiService();
  final _catalog = CatalogApiService();

  bool get _isClinicAdmin => AppSession.activeRole == Role.clinicAdmin;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();

  List<SpecialtyCatalogItem> _specialties = [];
  List<FacilityCatalogItem> _facilities = [];
  final Set<String> _selectedFacilityIds = {};

  String? _selectedSpecialtyId;
  bool _loadingCatalog = true;
  bool _submitting = false;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingCatalog = true;
      _catalogError = null;
    });
    try {
      final mapped = await _catalog.listSpecialties();

      List<FacilityCatalogItem> facilities = [];
      if (_isClinicAdmin) {
        final ctx = await _clinicApi.getMyContext();
        final facility = ctx['facility'] as Map<String, dynamic>? ?? {};
        final fid = facility['_id']?.toString() ?? '';
        if (fid.isNotEmpty) {
          facilities = [
            FacilityCatalogItem(
              id: fid,
              name: facility['name'] as String? ?? 'Mi clínica',
            ),
          ];
          _selectedFacilityIds.add(fid);
        }
      }

      if (!mounted) return;
      setState(() {
        _specialties = mapped;
        _facilities = facilities;
        _loadingCatalog = false;
        if (_specialties.isNotEmpty) {
          _selectedSpecialtyId = _specialties.first.id;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogError = e.message;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogError = 'No se pudo cargar especialidades y clínicas';
        _loadingCatalog = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecialtyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una especialidad')),
      );
      return;
    }
    if (!_isClinicAdmin && _selectedFacilityIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una clínica donde atiende el médico'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await _clinicApi.createDoctor(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        documentId: _documentController.text,
        specialtyId: _selectedSpecialtyId!,
      );
      if (!mounted) return;
      await _showSuccessDialog(result);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear el perfil del médico'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccessDialog(CreateDoctorResult result) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Médico registrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.name} fue creado correctamente.'),
            const SizedBox(height: 12),
            Text('Correo: ${result.email}'),
            const SizedBox(height: 8),
            const Text(
              'Contraseña temporal (compártela con el médico):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(
              result.temporaryPassword,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El médico podrá iniciar sesión y configurar sus horarios solo en las clínicas asociadas.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.temporaryPassword));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Contraseña copiada')),
              );
            },
            child: const Text('Copiar contraseña'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isClinicAdmin) {
      return ResponsiveScaffold(
        appBar: AppBar(title: const Text('Registrar médico')),
        body: const Center(
          child: Text('Solo el administrador de clínica puede registrar médicos.'),
        ),
      );
    }

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Registrar médico')),
      body: _loadingCatalog
          ? const Center(child: CircularProgressIndicator())
          : _catalogError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_catalogError!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadCatalog,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Datos del médico',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isClinicAdmin
                              ? 'El médico quedará asociado a tu clínica y podrá configurar horarios solo en esa sede.'
                              : 'Las clínicas seleccionadas definen dónde puede atender y configurar horarios.',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre y apellido',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (!v.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Número de teléfono',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _documentController,
                          decoration: const InputDecoration(
                            labelText: 'Cédula de identidad',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSpecialtyId,
                          decoration: const InputDecoration(
                            labelText: 'Especialidad',
                            prefixIcon: Icon(Icons.medical_services_outlined),
                          ),
                          items: _specialties
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedSpecialtyId = v),
                        ),
                        if (!_isClinicAdmin) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Clínicas asociadas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'El médico solo podrá agendar citas presenciales y horarios en estas sedes.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ..._facilities.map(_buildFacilityChip),
                        ] else if (_facilities.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.local_hospital, color: AppColors.primary),
                            title: const Text('Clínica asignada'),
                            subtitle: Text(_facilities.first.name),
                          ),
                        ],
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Crear perfil de médico',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFacilityChip(FacilityCatalogItem facility) {
    final selected = _selectedFacilityIds.contains(facility.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilterChip(
        label: Text(
          facility.city != null
              ? '${facility.name} (${facility.city})'
              : facility.name,
        ),
        selected: selected,
        onSelected: (value) {
          setState(() {
            if (value) {
              _selectedFacilityIds.add(facility.id);
            } else {
              _selectedFacilityIds.remove(facility.id);
            }
          });
        },
        selectedColor: AppColors.primaryLight,
        checkmarkColor: AppColors.primary,
      ),
    );
  }
}
