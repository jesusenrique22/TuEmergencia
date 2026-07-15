import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../insurance/domain/models/insurance_models.dart';
import '../../../insurance/domain/services/insurance_api_service.dart';
import '../../data/patient_api_service.dart';
import '../../data/patient_profile_repository.dart';
import '../../domain/models/patient_profile.dart';

class ClinicalHistoryFormPage extends StatefulWidget {
  const ClinicalHistoryFormPage({super.key});

  @override
  State<ClinicalHistoryFormPage> createState() =>
      _ClinicalHistoryFormPageState();
}

class _ClinicalHistoryFormPageState extends State<ClinicalHistoryFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _didLoad = false;
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerAnim;

  List<HealthInsurance> _availableInsurances = [];
  bool _loadingInsurances = true;

  // ── Controllers ───────────────────────────────────────────────────────────
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

  // ── Completion tracking ───────────────────────────────────────────────────
  int get _filledSections {
    int filled = 0;
    if (_fullName.text.isNotEmpty || _documentId.text.isNotEmpty) filled++;
    if (_phone.text.isNotEmpty || _emergencyName.text.isNotEmpty) filled++;
    if (_hypertension != null || _diabetes != null || _allergies.text.isNotEmpty) filled++;
    if (_weight.text.isNotEmpty || _height.text.isNotEmpty) filled++;
    if (_insurance.text.isNotEmpty) filled++;
    return filled;
  }

  bool _isOnboarding(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Map && args['onboarding'] == true;
  }

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
    _weight.addListener(_recalculateBmi);
    _height.addListener(_recalculateBmi);
    _birthDate.addListener(_updateAge);
    _loadInsurances();
  }

  Future<void> _loadInsurances() async {
    try {
      final list = await InsuranceApiService.instance.getCompanies();
      setState(() {
        _availableInsurances = list;
        _loadingInsurances = false;
      });
    } catch (_) {
      setState(() {
        _loadingInsurances = false;
      });
    }
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
    if (mounted) setState(() {});
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
      _showSnack('Nombre y correo son obligatorios', isError: true);
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
        if (mounted) _showSnack(e.message, isError: true);
        setState(() => _loading = false);
        return;
      } catch (e) {
        if (mounted) _showSnack('No se pudo guardar: $e', isError: true);
        setState(() => _loading = false);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
    _showSnack(
      completed ? '¡Historia clínica guardada! 🎉' : 'Borrador guardado',
      isError: false,
    );
    if (_isOnboarding(context)) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      AppNavigation.safeBack(context);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? AppColors.emergency : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final initial =
        DateTime.tryParse(_birthDate.text.trim()) ?? DateTime(1990, 1, 1);
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
    _headerCtrl.dispose();
    for (final c in [
      _referredBy, _fullName, _documentId, _birthDate, _age, _occupation,
      _address, _phone, _email, _emergencyName, _emergencyPhone, _vaccines,
      _allergies, _surgeries, _medications, _conditions, _weight, _height,
      _bmi, _obesityType, _recommendedSurgery, _observations, _insurance, _policy,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !onboarding,
        leading: onboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => AppNavigation.safeBack(context),
              ),
        title: onboarding
            ? null
            : const Text(
                'Historia Clínica',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero Header ────────────────────────────────────────────
              FadeTransition(
                opacity: _headerAnim,
                child: _HeroHeader(
                  onboarding: onboarding,
                  filledSections: _filledSections,
                  totalSections: 5,
                ),
              ),
              const SizedBox(height: 8),

              // ── Sections ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _FormSection(
                      title: 'Datos personales',
                      subtitle: 'Identificación y demografía',
                      icon: Icons.badge_rounded,
                      color: AppColors.primary,
                      child: _sectionPersonal(),
                    ),
                    const SizedBox(height: 12),
                    _FormSection(
                      title: 'Contacto',
                      subtitle: 'Teléfono, correo y emergencias',
                      icon: Icons.contact_phone_rounded,
                      color: AppColors.info,
                      child: _sectionContact(),
                    ),
                    const SizedBox(height: 12),
                    _FormSection(
                      title: 'Antecedentes médicos',
                      subtitle: 'Condiciones, alergias y medicamentos',
                      icon: Icons.medical_services_rounded,
                      color: AppColors.emergency,
                      child: _sectionAntecedents(),
                    ),
                    const SizedBox(height: 12),
                    _FormSection(
                      title: 'Datos clínicos',
                      subtitle: 'Medidas corporales y tipo de sangre',
                      icon: Icons.monitor_heart_rounded,
                      color: AppColors.secondary,
                      child: _sectionClinical(),
                    ),
                    const SizedBox(height: 12),
                    _FormSection(
                      title: 'Seguro médico',
                      subtitle: 'Opcional — para facturación',
                      icon: Icons.shield_rounded,
                      color: AppColors.promo,
                      child: _sectionInsurance(),
                    ),
                    const SizedBox(height: 12),
                    _FormSection(
                      title: 'Observaciones',
                      subtitle: 'Notas para el equipo médico',
                      icon: Icons.edit_note_rounded,
                      color: AppColors.textSecondary,
                      child: _sectionObservations(),
                    ),
                    const SizedBox(height: 28),

                    // ── Save Button ──────────────────────────────────────
                    _SaveButton(
                      loading: _loading,
                      onSave: () => _save(completed: true),
                      label: onboarding ? 'Guardar y entrar al portal' : 'Guardar historia clínica',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────
  Widget _sectionPersonal() {
    return Column(
      children: [
        _CleanField(ctrl: _referredBy, label: 'Referido por', icon: Icons.share_rounded),
        const SizedBox(height: 12),
        _TwoCol(
          left: _CleanField(
            ctrl: _fullName,
            label: 'Nombre completo *',
            icon: Icons.person_outline_rounded,
            capitalization: TextCapitalization.words,
            required: true,
          ),
          right: _CleanField(ctrl: _documentId, label: 'Cédula / C.I.', icon: Icons.credit_card_rounded),
        ),
        const SizedBox(height: 12),
        _TwoCol(
          left: GestureDetector(
            onTap: _pickBirthDate,
            child: AbsorbPointer(
              child: _CleanField(
                ctrl: _birthDate,
                label: 'Fecha de nacimiento',
                icon: Icons.cake_rounded,
                hint: 'Toca para elegir',
              ),
            ),
          ),
          right: _CleanField(
            ctrl: _age,
            label: 'Edad',
            icon: Icons.numbers_rounded,
            digits: true,
            hint: 'Auto',
          ),
        ),
        const SizedBox(height: 12),
        _TwoCol(
          left: _DropField(
            value: _maritalStatus.isEmpty ? null : _maritalStatus,
            label: 'Estado civil',
            icon: Icons.favorite_border_rounded,
            items: const ['Soltero/a', 'Casado/a', 'Unión libre', 'Divorciado/a', 'Viudo/a'],
            onChanged: (v) => setState(() => _maritalStatus = v ?? ''),
          ),
          right: _CleanField(ctrl: _occupation, label: 'Ocupación', icon: Icons.work_outline_rounded),
        ),
        const SizedBox(height: 12),
        _CleanField(
          ctrl: _address,
          label: 'Dirección de residencia',
          icon: Icons.home_outlined,
          maxLines: 2,
          capitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _sectionContact() {
    return Column(
      children: [
        _TwoCol(
          left: _CleanField(ctrl: _phone, label: 'Teléfono celular', icon: Icons.phone_android_rounded, phone: true),
          right: _CleanField(ctrl: _email, label: 'Correo *', icon: Icons.mail_outline_rounded, required: true),
        ),
        const SizedBox(height: 16),
        // Emergency contact header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.emergency.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.emergency.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.emergency_rounded, color: AppColors.emergency, size: 18),
              SizedBox(width: 10),
              Text(
                'Contacto de emergencia',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.emergency,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _TwoCol(
          left: _CleanField(ctrl: _emergencyName, label: 'Nombre familiar', icon: Icons.family_restroom_rounded, capitalization: TextCapitalization.words),
          right: _CleanField(ctrl: _emergencyPhone, label: 'Teléfono familiar', icon: Icons.phone_outlined, phone: true),
        ),
      ],
    );
  }

  Widget _sectionAntecedents() {
    return Column(
      children: [
        // Condiciones Yes/No
        _YesNoRow(label: 'Hipertensión', value: _hypertension, onChanged: (v) => setState(() => _hypertension = v)),
        _YesNoRow(label: 'Diabetes', value: _diabetes, onChanged: (v) => setState(() => _diabetes = v)),
        _YesNoRow(label: 'Asma bronquial', value: _asthma, onChanged: (v) => setState(() => _asthma = v)),
        _YesNoRow(label: 'Fumador activo', value: _smoker, onChanged: (v) => setState(() => _smoker = v)),
        const SizedBox(height: 16),
        // COVID chips
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'COVID-19',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _CovidChip(label: 'Sin COVID', value: 'NONE', current: _covidSeverity, onTap: (v) => setState(() => _covidSeverity = v)),
                _CovidChip(label: 'Leve', value: 'MILD', current: _covidSeverity, onTap: (v) => setState(() => _covidSeverity = v)),
                _CovidChip(label: 'Moderado', value: 'MODERATE', current: _covidSeverity, onTap: (v) => setState(() => _covidSeverity = v)),
                _CovidChip(label: 'Grave', value: 'SEVERE', current: _covidSeverity, onTap: (v) => setState(() => _covidSeverity = v)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CleanField(ctrl: _vaccines, label: 'Vacunas recibidas', icon: Icons.vaccines_outlined),
        const SizedBox(height: 12),
        _CleanField(ctrl: _allergies, label: 'Alergias conocidas', icon: Icons.warning_amber_rounded),
        const SizedBox(height: 12),
        _CleanField(ctrl: _surgeries, label: 'Cirugías previas', icon: Icons.local_hospital_outlined),
        const SizedBox(height: 12),
        _CleanField(ctrl: _medications, label: 'Medicamentos actuales', icon: Icons.medication_outlined),
        const SizedBox(height: 12),
        _CleanField(ctrl: _conditions, label: 'Otras condiciones crónicas', icon: Icons.healing_rounded),
      ],
    );
  }

  Widget _sectionClinical() {
    final bmiValue = double.tryParse(_bmi.text);
    String bmiLabel = '';
    Color bmiColor = AppColors.textSecondary;
    if (bmiValue != null) {
      if (bmiValue < 18.5) {
        bmiLabel = 'Bajo peso';
        bmiColor = AppColors.info;
      } else if (bmiValue < 25) {
        bmiLabel = 'Normal ✓';
        bmiColor = AppColors.primary;
      } else if (bmiValue < 30) {
        bmiLabel = 'Sobrepeso';
        bmiColor = AppColors.warning;
      } else {
        bmiLabel = 'Obesidad';
        bmiColor = AppColors.emergency;
      }
    }

    return Column(
      children: [
        _DropField(
          value: _bloodType,
          label: 'Tipo de sangre',
          icon: Icons.bloodtype_rounded,
          items: const ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'],
          onChanged: (v) => setState(() => _bloodType = v ?? 'O+'),
        ),
        const SizedBox(height: 12),
        _TwoCol(
          left: _CleanField(ctrl: _weight, label: 'Peso (kg)', icon: Icons.scale_rounded, keyboard: TextInputType.number, numericDecimal: true),
          right: _CleanField(ctrl: _height, label: 'Talla (cm)', icon: Icons.height_rounded, keyboard: TextInputType.number, numericDecimal: true, hint: 'Ej. 170'),
        ),
        if (_bmi.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bmiColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bmiColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.calculate_rounded, color: bmiColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  'IMC: ${_bmi.text} kg/m²',
                  style: TextStyle(fontWeight: FontWeight.w700, color: bmiColor, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bmiColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bmiLabel,
                    style: TextStyle(color: bmiColor, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _TwoCol(
          left: _CleanField(ctrl: _obesityType, label: 'Tipo de obesidad', icon: Icons.category_outlined),
          right: _CleanField(ctrl: _recommendedSurgery, label: 'Cirugía recomendada', icon: Icons.medical_services_outlined),
        ),
      ],
    );
  }

  Widget _sectionInsurance() {
    if (_loadingInsurances) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableInsurances.isEmpty) {
      return _TwoCol(
        left: _CleanField(ctrl: _insurance, label: 'Aseguradora', icon: Icons.business_rounded),
        right: _CleanField(ctrl: _policy, label: 'Número de póliza', icon: Icons.numbers_rounded),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _insurance.text.isEmpty ? null : _insurance.text,
          decoration: InputDecoration(
            labelText: 'Selecciona tu Aseguradora',
            prefixIcon: const Icon(Icons.business_rounded, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _availableInsurances.map((c) {
            return DropdownMenuItem<String>(
              value: c.name,
              child: Text(c.name),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _insurance.text = val;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        _CleanField(ctrl: _policy, label: 'Número de póliza', icon: Icons.numbers_rounded),
      ],
    );
  }

  Widget _sectionObservations() {
    return _CleanField(
      ctrl: _observations,
      label: 'Observaciones generales',
      icon: Icons.edit_note_rounded,
      maxLines: 5,
      capitalization: TextCapitalization.sentences,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final bool onboarding;
  final int filledSections;
  final int totalSections;

  const _HeroHeader({
    required this.onboarding,
    required this.filledSections,
    required this.totalSections,
  });

  @override
  Widget build(BuildContext context) {
    final progress = filledSections / totalSections;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      onboarding ? '¡Último paso!' : 'Tu historia clínica',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      onboarding
                          ? 'Completa tu expediente para acceder al portal'
                          : 'Expediente médico personal',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onboarding) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(progress * 100).round()}% completado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$filledSections/$totalSections secciones',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: const [
              _HeaderChip(icon: Icons.lock_outline_rounded, label: 'Datos protegidos'),
              _HeaderChip(icon: Icons.local_hospital_rounded, label: 'Uso médico exclusivo'),
              _HeaderChip(icon: Icons.edit_off_rounded, label: 'Editable siempre'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Section Card (Collapsible)
// ─────────────────────────────────────────────────────────────────────────────
class _FormSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  State<_FormSection> createState() => _FormSectionState();
}

class _FormSectionState extends State<_FormSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SizeTransition(
            sizeFactor: _anim,
            child: Column(
              children: [
                Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save Button
// ─────────────────────────────────────────────────────────────────────────────
class _SaveButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onSave;
  final String label;

  const _SaveButton({
    required this.loading,
    required this.onSave,
    required this.label,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.loading) widget.onSave();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 58,
          decoration: BoxDecoration(
            gradient: widget.loading
                ? null
                : const LinearGradient(
                    colors: AppColors.headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.loading ? AppColors.primary.withValues(alpha: 0.4) : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.loading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: _pressed ? 0.2 : 0.45),
                      blurRadius: _pressed ? 8 : 24,
                      offset: Offset(0, _pressed ? 2 : 10),
                      spreadRadius: _pressed ? -2 : 0,
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clean Field
// ─────────────────────────────────────────────────────────────────────────────
class _CleanField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData icon;
  final bool required;
  final bool phone;
  final bool digits;
  final bool numericDecimal;
  final int maxLines;
  final TextInputType? keyboard;
  final TextCapitalization capitalization;

  const _CleanField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.hint,
    this.required = false,
    this.phone = false,
    this.digits = false,
    this.numericDecimal = false,
    this.maxLines = 1,
    this.keyboard,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final inputType = phone
        ? TextInputType.phone
        : (digits
            ? TextInputType.number
            : keyboard ?? (maxLines > 1 ? TextInputType.multiline : null));

    final formatters = phone || digits
        ? [FilteringTextInputFormatter.digitsOnly]
        : numericDecimal
            ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))]
            : null;

    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: inputType,
      textCapitalization: capitalization,
      inputFormatters: formatters,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drop Field
// ─────────────────────────────────────────────────────────────────────────────
class _DropField extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropField({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
      ),
      items: items
          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Two Column Layout
// ─────────────────────────────────────────────────────────────────────────────
class _TwoCol extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _TwoCol({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
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
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yes/No Row
// ─────────────────────────────────────────────────────────────────────────────
class _YesNoRow extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _YesNoRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            children: [
              _ToggleBtn(
                label: 'Sí',
                selected: value == true,
                selectedColor: AppColors.primary,
                onTap: () => onChanged(value == true ? null : true),
              ),
              const SizedBox(width: 6),
              _ToggleBtn(
                label: 'No',
                selected: value == false,
                selectedColor: AppColors.emergency,
                onTap: () => onChanged(value == false ? null : false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? selectedColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Covid Chip
// ─────────────────────────────────────────────────────────────────────────────
class _CovidChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;

  const _CovidChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check_rounded, size: 13, color: AppColors.primary),
              ),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
