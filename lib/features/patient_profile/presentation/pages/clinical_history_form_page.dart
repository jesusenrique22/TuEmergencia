import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../data/patient_api_service.dart';
import '../../data/patient_profile_repository.dart';
import '../../domain/models/patient_profile.dart';

class ClinicalHistoryFormPage extends StatefulWidget {
  const ClinicalHistoryFormPage({super.key});

  @override
  State<ClinicalHistoryFormPage> createState() => _ClinicalHistoryFormPageState();
}

class _ClinicalHistoryFormPageState extends State<ClinicalHistoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _didLoad = false;

  final _referredBy = TextEditingController();
  final _fullName = TextEditingController();
  final _documentId = TextEditingController();
  final _birthDate = TextEditingController();
  final _age = TextEditingController();
  String _maritalStatus = '';
  final _occupation = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();

  bool? _hypertension;
  bool? _diabetes;
  bool? _asthma;
  bool? _smoker;
  String _covidSeverity = 'NONE';
  final _vaccines = TextEditingController();
  final _allergies = TextEditingController();
  final _surgeries = TextEditingController();
  final _medications = TextEditingController();
  final _conditions = TextEditingController();

  String _bloodType = 'O+';
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _bmi = TextEditingController();
  final _obesityType = TextEditingController();
  final _recommendedSurgery = TextEditingController();
  final _observations = TextEditingController();
  final _insurance = TextEditingController();
  final _policy = TextEditingController();

  bool _isOnboarding(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Map && args['onboarding'] == true;
  }

  @override
  void initState() {
    super.initState();
    _weight.addListener(_recalculateBmi);
    _height.addListener(_recalculateBmi);
    _birthDate.addListener(_updateAge);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    _loadProfile();
    setState(() {});
  }

  void _loadProfile() {
    PatientProfile? profile = PatientProfileRepository.activeProfile;
    if (profile == null) {
      final user = AppSession.currentUser;
      if (user != null) {
        _fullName.text = user.name;
        _email.text = user.email;
        if (user.phone != null) _phone.text = user.phone!;
      }
      return;
    }
    _applyProfile(profile);
  }

  void _applyProfile(PatientProfile p) {
    _referredBy.text = p.referredBy;
    _fullName.text = p.fullName;
    _documentId.text = p.documentId;
    _birthDate.text = p.birthDate;
    _updateAge();
    _maritalStatus = p.maritalStatus;
    _occupation.text = p.occupation;
    _address.text = p.address;
    _phone.text = p.phone;
    _email.text = p.email;
    _emergencyName.text = p.emergencyContactName;
    _emergencyPhone.text = p.emergencyContactPhone;
    _hypertension = p.hasHypertension ? true : null;
    _diabetes = p.hasDiabetes ? true : null;
    _asthma = p.hasBronchialAsthma ? true : null;
    _smoker = p.isSmoker ? true : null;
    _covidSeverity = p.covidSeverity;
    _vaccines.text = p.vaccines;
    _allergies.text = p.allergies;
    _surgeries.text = p.surgeries;
    _medications.text = p.currentMedications;
    _conditions.text = p.chronicConditions;
    _bloodType = p.bloodType;
    _weight.text = p.weightKg;
    _height.text = p.heightCm;
    _recalculateBmi();
    _obesityType.text = p.obesityType;
    _recommendedSurgery.text = p.recommendedSurgery;
    _observations.text = p.observations;
    _insurance.text = p.insuranceProvider;
    _policy.text = p.policyNumber;
  }

  void _updateAge() {
    final parsed = DateTime.tryParse(_birthDate.text.trim());
    if (parsed == null) {
      _age.text = '';
      return;
    }
    final now = DateTime.now();
    var years = now.year - parsed.year;
    if (now.month < parsed.month ||
        (now.month == parsed.month && now.day < parsed.day)) {
      years--;
    }
    _age.text = years >= 0 ? '$years' : '';
    if (mounted) setState(() {});
  }

  void _recalculateBmi() {
    final w = double.tryParse(_weight.text.replaceAll(',', '.'));
    final hCm = double.tryParse(_height.text.replaceAll(',', '.'));
    if (w == null || hCm == null || hCm <= 0) {
      _bmi.text = '';
      return;
    }
    final hM = hCm / 100;
    final imc = w / (hM * hM);
    _bmi.text = imc.toStringAsFixed(1);
  }

  PatientProfile _buildProfile({required bool completed}) {
    final existing = PatientProfileRepository.activeProfile;
    final userId = AppSession.currentUser?.id ?? existing?.id ?? '';
    return PatientProfile(
      id: userId,
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      documentId: _documentId.text.trim(),
      birthDate: _birthDate.text.trim(),
      address: _address.text.trim(),
      emergencyContactName: _emergencyName.text.trim(),
      emergencyContactPhone: _emergencyPhone.text.trim(),
      referredBy: _referredBy.text.trim(),
      maritalStatus: _maritalStatus,
      occupation: _occupation.text.trim(),
      bloodType: _bloodType,
      allergies: _allergies.text.trim(),
      chronicConditions: _conditions.text.trim(),
      currentMedications: _medications.text.trim(),
      surgeries: _surgeries.text.trim(),
      weightKg: _weight.text.trim(),
      heightCm: _height.text.trim(),
      obesityType: _obesityType.text.trim(),
      recommendedSurgery: _recommendedSurgery.text.trim(),
      vaccines: _vaccines.text.trim(),
      hasHypertension: _hypertension == true,
      hasDiabetes: _diabetes == true,
      hasBronchialAsthma: _asthma == true,
      isSmoker: _smoker == true,
      covidSeverity: _covidSeverity,
      observations: _observations.text.trim(),
      weightControls: existing?.weightControls ?? const [],
      insuranceProvider: _insurance.text.trim(),
      policyNumber: _policy.text.trim(),
      medicalHistoryCompleted: completed,
    );
  }

  Future<void> _save({required bool completed}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_fullName.text.trim().isEmpty || _email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y correo son obligatorios')),
      );
      return;
    }

    setState(() => _loading = true);
    final profile = _buildProfile(completed: completed);
    PatientProfileRepository.save(profile);

    if (AppSession.isLoggedIn) {
      try {
        await PatientApiService().updateProfile(
          profile.toApiJson(markHistoryCompleted: completed),
        );
        await PatientProfileRepository.refreshFromApi();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        setState(() => _loading = false);
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo guardar: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? 'Historia clínica guardada correctamente.'
              : 'Borrador guardado.',
        ),
      ),
    );
    if (_isOnboarding(context)) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      AppNavigation.safeBack(context);
    }
  }

  Future<void> _pickBirthDate() async {
    final initial = DateTime.tryParse(_birthDate.text.trim()) ??
        DateTime(1990, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        _birthDate.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _updateAge();
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _referredBy,
      _fullName,
      _documentId,
      _birthDate,
      _age,
      _occupation,
      _address,
      _phone,
      _email,
      _emergencyName,
      _emergencyPhone,
      _vaccines,
      _allergies,
      _surgeries,
      _medications,
      _conditions,
      _weight,
      _height,
      _bmi,
      _obesityType,
      _recommendedSurgery,
      _observations,
      _insurance,
      _policy,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = _isOnboarding(context);
    return ResponsiveScaffold(
      hideNavigation: onboarding,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historia Clínica'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => onboarding
              ? Navigator.pushReplacementNamed(context, AppRoutes.dashboard)
              : AppNavigation.safeBack(context),
        ),
      ),
      body: AppPage(
        maxWidth: 920,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeroPanel(
                color: AppColors.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppStatusPill(
                      label: 'Historia clínica',
                      color: Colors.white,
                      icon: Icons.assignment_rounded,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tu expediente médico',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionPersonal(context),
              const SizedBox(height: 16),
              _sectionContact(context),
              const SizedBox(height: 16),
              _sectionAntecedents(context),
              const SizedBox(height: 16),
              _sectionClinical(context),
              const SizedBox(height: 16),
              _sectionInsurance(context),
              const SizedBox(height: 16),
              _sectionObservations(context),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _loading ? null : () => _save(completed: true),
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(onboarding ? 'Guardar y continuar' : 'Guardar historia'),
              ),
              if (onboarding) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.dashboard,
                          ),
                  child: const Text('Completar después'),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionPersonal(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Datos personales',
            subtitle: 'Identificación y datos demográficos.',
          ),
          const SizedBox(height: 16),
          _field(_referredBy, 'Referido por', Icons.share),
          const SizedBox(height: 12),
          _row(
            _field(_fullName, 'Nombre y apellido', Icons.badge_outlined,
                required: true),
            _field(_documentId, 'C.I.', Icons.credit_card),
          ),
          const SizedBox(height: 12),
          _row(
            GestureDetector(
              onTap: _pickBirthDate,
              child: AbsorbPointer(
                child: _field(
                  _birthDate,
                  'Fecha de nacimiento',
                  Icons.cake_outlined,
                  hint: 'Toca para elegir',
                ),
              ),
            ),
            _field(
              _age,
              'Edad',
              Icons.numbers,
              digitsOnly: true,
              hint: 'Se calcula al elegir fecha',
            ),
          ),
          const SizedBox(height: 12),
          _row(
            DropdownButtonFormField<String>(
              initialValue: _maritalStatus.isEmpty ? null : _maritalStatus,
              decoration: const InputDecoration(
                labelText: 'Estado civil',
                prefixIcon: Icon(Icons.favorite_border),
              ),
              items: const [
                'Soltero/a',
                'Casado/a',
                'Unión libre',
                'Divorciado/a',
                'Viudo/a',
              ]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _maritalStatus = v ?? ''),
            ),
            _field(_occupation, 'Ocupación', Icons.work_outline),
          ),
          const SizedBox(height: 12),
          _field(_address, 'Dirección', Icons.home_outlined, maxLines: 2),
        ],
      ),
    );
  }

  Widget _sectionContact(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Información de contacto',
            subtitle: 'Teléfono, correo y familiar de emergencia.',
          ),
          const SizedBox(height: 16),
          _row(
            _field(_phone, 'Telf. celular', Icons.phone_android, phone: true),
            _field(_email, 'Email', Icons.mail_outline, required: true),
          ),
          const SizedBox(height: 12),
          _row(
            _field(_emergencyName, 'Nombre de un familiar', Icons.family_restroom),
            _field(_emergencyPhone, 'Teléfono familiar', Icons.phone, phone: true),
          ),
        ],
      ),
    );
  }

  Widget _sectionAntecedents(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Antecedentes',
            subtitle: 'Indica Sí o No para cada condición.',
          ),
          const SizedBox(height: 16),
          _yesNoRow('Hipertensión', _hypertension, (v) => _hypertension = v),
          _yesNoRow('Diabetes', _diabetes, (v) => _diabetes = v),
          _yesNoRow('Asma bronquial', _asthma, (v) => _asthma = v),
          _yesNoRow('Fumador', _smoker, (v) => _smoker = v),
          const SizedBox(height: 16),
          Text(
            'COVID-19',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _covidChip('Sin COVID', 'NONE'),
              _covidChip('Leve', 'MILD'),
              _covidChip('Moderado', 'MODERATE'),
              _covidChip('Fuerte', 'SEVERE'),
            ],
          ),
          const SizedBox(height: 16),
          _field(_vaccines, 'Vacunas', Icons.vaccines_outlined),
          const SizedBox(height: 12),
          _field(_allergies, 'Alergias', Icons.warning_amber_rounded),
          const SizedBox(height: 12),
          _field(_surgeries, 'Cirugías previas', Icons.local_hospital_outlined),
          const SizedBox(height: 12),
          _field(_medications, 'Medicamentos actuales', Icons.medication_outlined),
          const SizedBox(height: 12),
          _field(_conditions, 'Otras condiciones crónicas', Icons.healing),
        ],
      ),
    );
  }

  Widget _sectionClinical(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Datos clínicos',
            subtitle: 'Medidas corporales e información relevante.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _bloodType,
            decoration: const InputDecoration(
              labelText: 'Tipo de sangre',
              prefixIcon: Icon(Icons.bloodtype),
            ),
            items: const ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _bloodType = v ?? 'O+'),
          ),
          const SizedBox(height: 12),
          _row(
            _field(
              _weight,
              'Peso (kg)',
              Icons.scale,
              keyboard: TextInputType.number,
            ),
            _field(
              _height,
              'Talla (cm)',
              Icons.height,
              keyboard: TextInputType.number,
              hint: 'Ej. 170',
            ),
          ),
          const SizedBox(height: 12),
          _row(
            _field(_bmi, 'IMC (kg/m²)', Icons.calculate, readOnly: true),
            _field(_obesityType, 'Tipo de obesidad', Icons.category_outlined),
          ),
          const SizedBox(height: 12),
          _field(
            _recommendedSurgery,
            'Cirugía recomendada',
            Icons.medical_services_outlined,
          ),
        ],
      ),
    );
  }

  Widget _sectionInsurance(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Seguro médico',
            subtitle: 'Opcional — para facturación y autorizaciones.',
          ),
          const SizedBox(height: 16),
          _row(
            _field(_insurance, 'Aseguradora', Icons.business),
            _field(_policy, 'Número de póliza', Icons.numbers),
          ),
        ],
      ),
    );
  }

  Widget _sectionObservations(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Observaciones',
            subtitle: 'Notas adicionales para el equipo médico.',
          ),
          const SizedBox(height: 16),
          _field(_observations, 'Observaciones', Icons.edit_note, maxLines: 5),
        ],
      ),
    );
  }

  Widget _yesNoRow(
    String label,
    bool? value,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          SegmentedButton<bool?>(
            segments: const [
              ButtonSegment(value: true, label: Text('Sí')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {value},
            emptySelectionAllowed: true,
            onSelectionChanged: (s) =>
                setState(() => onChanged(s.isEmpty ? null : s.first)),
          ),
        ],
      ),
    );
  }

  Widget _covidChip(String label, String value) {
    final selected = _covidSeverity == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _covidSeverity = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _row(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    bool readOnly = false,
    bool phone = false,
    bool digitsOnly = false,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    final inputType = phone
        ? TextInputType.phone
        : (digitsOnly || keyboard == TextInputType.number
            ? TextInputType.number
            : keyboard);
    final formatters = phone || digitsOnly
        ? [FilteringTextInputFormatter.digitsOnly]
        : keyboard == TextInputType.number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]
            : null;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: inputType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null
          : null,
    );
  }
}
