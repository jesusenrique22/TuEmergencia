import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/safe_dialog.dart';
import '../../data/super_admin_api_service.dart';

class NamedOption {
  final String id;
  final String name;

  const NamedOption(this.id, this.name);
}

class StaffFormData {
  final String name;
  final String email;
  final String phone;
  final String optionId;

  const StaffFormData({
    required this.name,
    required this.email,
    required this.phone,
    required this.optionId,
  });
}

Future<void> showAccountCreatedDialog(
  BuildContext context,
  StaffCreateResult result, {
  String? roleLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cuenta creada'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${result.name} — ${result.email}'),
          if (roleLabel != null) ...[
            const SizedBox(height: 8),
            Text('Rol: $roleLabel'),
          ],
          const SizedBox(height: 8),
          SelectableText('Contraseña: ${result.temporaryPassword}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: result.temporaryPassword));
            closeDialog(ctx);
          },
          child: const Text('Copiar contraseña'),
        ),
        FilledButton(
          onPressed: () => closeDialog(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class CreateFacilityDialog extends StatefulWidget {
  final SuperAdminApiService api;

  const CreateFacilityDialog({super.key, required this.api});

  @override
  State<CreateFacilityDialog> createState() => _CreateFacilityDialogState();
}

class _CreateFacilityDialogState extends State<CreateFacilityDialog> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  String _type = 'CLINIC';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y dirección son obligatorios')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final facility = await widget.api.createFacility(
        name: _name.text,
        address: _address.text,
        type: _type,
        city: _city.text,
        phone: _phone.text,
      );
      final id = facility['_id']?.toString() ?? '';
      final facilityName =
          facility['name'] as String? ?? _name.text.trim();
      if (!mounted) return;
      closeDialog(context, NamedOption(id, facilityName));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre de la clínica *',
                hintText: 'Ej: Clínica Paraíso',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'CLINIC', child: Text('Clínica')),
                DropdownMenuItem(value: 'HOSPITAL', child: Text('Hospital')),
                DropdownMenuItem(
                  value: 'CONSULTORY',
                  child: Text('Consultorio'),
                ),
              ],
              onChanged: _saving ? null : (v) => setState(() => _type = v ?? 'CLINIC'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Dirección *'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => closeDialog(context, null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Registrar clínica'),
        ),
      ],
    );
  }
}

class CreateLaboratoryDialog extends StatefulWidget {
  final SuperAdminApiService api;

  const CreateLaboratoryDialog({super.key, required this.api});

  @override
  State<CreateLaboratoryDialog> createState() => _CreateLaboratoryDialogState();
}

class _CreateLaboratoryDialogState extends State<CreateLaboratoryDialog> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y dirección son obligatorios')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final lab = await widget.api.createLaboratory(
        name: _name.text,
        address: _address.text,
        phone: _phone.text,
      );
      final id = lab['_id']?.toString() ?? lab['id']?.toString() ?? '';
      final labName = lab['name'] as String? ?? _name.text.trim();
      if (!mounted) return;
      closeDialog(context, NamedOption(id, labName));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar laboratorio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'El laboratorio quedará disponible para asignar técnicos.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre del laboratorio *',
                hintText: 'Ej: BioLab Central',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Dirección *'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => closeDialog(context, null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Registrar'),
        ),
      ],
    );
  }
}

class StaffOptionPickerDialog extends StatefulWidget {
  final String title;
  final String optionLabel;
  final String? intro;
  final List<NamedOption> options;
  final String registerNewLabel;
  final IconData registerNewIcon;
  final Future<NamedOption?> Function(BuildContext context)? onRegisterNew;

  const StaffOptionPickerDialog({
    super.key,
    required this.title,
    required this.optionLabel,
    required this.options,
    this.intro,
    this.registerNewLabel = 'Registrar nuevo',
    this.registerNewIcon = Icons.add_rounded,
    this.onRegisterNew,
  });

  @override
  State<StaffOptionPickerDialog> createState() => _StaffOptionPickerDialogState();
}

class _StaffOptionPickerDialogState extends State<StaffOptionPickerDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  late List<NamedOption> _options;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _options = [...widget.options];
    _selectedId = _options.isNotEmpty ? _options.first.id : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    final optionId = _selectedId;
    if (optionId == null) return;
    closeDialog(
      context,
      StaffFormData(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        optionId: optionId,
      ),
    );
  }

  Future<void> _registerNew() async {
    final register = widget.onRegisterNew;
    if (register == null) return;
    final created = await register(context);
    if (!mounted || created == null || created.id.isEmpty) return;
    setState(() {
      _options = [..._options, created];
      _selectedId = created.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.intro != null) ...[
              Text(
                widget.intro!,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Correo'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            if (_options.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No hay ${widget.optionLabel.toLowerCase()} registrados. Crea uno primero.',
                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedId,
                decoration: InputDecoration(labelText: widget.optionLabel),
                items: _options
                    .map(
                      (o) => DropdownMenuItem(value: o.id, child: Text(o.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedId = v),
              ),
            if (widget.onRegisterNew != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _registerNew,
                icon: Icon(widget.registerNewIcon, size: 20),
                label: Text(widget.registerNewLabel),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => closeDialog(context, null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selectedId == null ? null : _submit,
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
