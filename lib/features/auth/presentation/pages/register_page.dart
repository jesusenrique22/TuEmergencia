import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/experience/animated_blobs.dart';
import '../../data/auth_api_service.dart';
import '../../data/role_mapper.dart';
import '../../domain/models/role.dart';
import '../../../patient_profile/data/patient_profile_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────
  int _step = 0; // 0, 1, 2
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  final _authApi = AuthApiService();

  static const _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  String? _validateStep0() {
    if (_nameController.text.trim().isEmpty) return 'Ingresa tu nombre completo';
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Ingresa tu correo';
    if (RegExp(r'[áéíóúÁÉÍÓÚüÜñÑ]').hasMatch(email)) {
      return 'El correo no debe contener tildes ni eñes (ej: usa "u" en vez de "ú")';
    }
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Correo inválido (ejemplo: usuario@correo.com)';
    }
    return null;
  }

  String? _validateStep2() {
    if (_passwordController.text.isEmpty) return 'Ingresa una contraseña';
    if (_passwordController.text.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    if (_passwordController.text != _confirmController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  void _nextStep() {
    setState(() => _error = null);
    if (_step == 0) {
      final err = _validateStep0();
      if (err != null) {
        setState(() => _error = err);
        return;
      }
    }
    if (_step == 2) {
      final err = _validateStep2();
      if (err != null) {
        setState(() => _error = err);
        return;
      }
      _submit();
      return;
    }
    _animateTo(_step + 1);
  }

  void _prevStep() {
    if (_step == 0) {
      AppNavigation.safeBack(context);
      return;
    }
    _animateTo(_step - 1);
  }

  void _animateTo(int target) {
    _slideCtrl.reset();
    setState(() => _step = target);
    _slideCtrl.forward();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _authApi.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        roleApi: RoleMapper.toApi(Role.patient),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
      );
      AppSession.setSession(user: response.user, tokenValue: response.token);
      AppRealtime.reconnectAfterAuth();
      await PatientProfileRepository.refreshFromApi();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.clinicalHistory,
        arguments: {'onboarding': true},
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error =
            'No se pudo conectar al servidor. Verifica tu Internet e intenta de nuevo.';
        _loading = false;
      });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBlobsBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20, top > 0 ? 8 : 16, 20, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: _prevStep),
                    const SizedBox(width: 16),
                    Expanded(child: _StepProgress(current: _step, total: _totalSteps)),
                    const SizedBox(width: 52),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottom),
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StepHeader(step: _step),
                          const SizedBox(height: 28),
                          _buildCurrentStep(),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: _error!),
                          ],
                          const SizedBox(height: 28),
                          _NextButton(
                            step: _step,
                            total: _totalSteps,
                            loading: _loading,
                            onTap: _nextStep,
                          ),
                          const SizedBox(height: 16),
                          if (_step == 0)
                            Center(
                              child: TextButton(
                                onPressed: () => AppNavigation.safeBack(context),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontFamily: 'Outfit',
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '¿Ya tienes cuenta? ',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: 'Inicia sesión',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _Step0(
          nameCtrl: _nameController,
          emailCtrl: _emailController,
          phoneCtrl: _phoneController,
          onNext: _nextStep,
        );
      case 1:
        return _Step1(
          addressCtrl: _addressController,
          emergencyNameCtrl: _emergencyNameController,
          emergencyPhoneCtrl: _emergencyPhoneController,
          onNext: _nextStep,
        );
      case 2:
        return _Step2(
          passCtrl: _passwordController,
          confirmCtrl: _confirmController,
          obscurePass: _obscurePass,
          obscureConfirm: _obscureConfirm,
          onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
          onToggleConfirm: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onSubmit: _nextStep,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Step Header
// ────────────────────────────────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final int step;
  const _StepHeader({required this.step});

  static const _titles = [
    '¡Bienvenido!',
    'Contacto de emergencia',
    'Crea tu contraseña',
  ];

  static const _subtitles = [
    'Cuéntanos sobre ti para crear tu cuenta',
    'Alguien que podamos contactar en caso de emergencia',
    'Tu cuenta ya casi está lista 🎉',
  ];

  static const _icons = [
    Icons.waving_hand_rounded,
    Icons.favorite_border_rounded,
    Icons.lock_person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(_icons[step], color: Colors.white, size: 30),
        ),
        const SizedBox(height: 20),
        Text(
          _titles[step],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _subtitles[step],
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Step Progress Bar
// ────────────────────────────────────────────────────────────────────────────
class _StepProgress extends StatelessWidget {
  final int current;
  final int total;
  const _StepProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(total, (i) {
            final done = i <= current;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: 5,
                margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: done
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Paso ${current + 1} de $total',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Back Button
// ────────────────────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Next / Submit Button
// ────────────────────────────────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  final int step;
  final int total;
  final bool loading;
  final VoidCallback onTap;
  const _NextButton({
    required this.step,
    required this.total,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == total - 1;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.headerGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLast ? 'Crear mi cuenta' : 'Continuar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Error Banner
// ────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emergency, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.emergency, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.emergency,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Shared premium field
// ────────────────────────────────────────────────────────────────────────────
class _RegField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final TextInputAction? action;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? formatters;

  const _RegField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.action,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        textInputAction: action,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        inputFormatters: formatters,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          labelStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          suffixIcon: suffixIcon,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Info Card
// ────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoCard({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// STEP 0 — Datos personales
// ────────────────────────────────────────────────────────────────────────────
class _Step0 extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final VoidCallback onNext;

  const _Step0({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RegField(
          controller: nameCtrl,
          label: 'Nombre completo',
          hint: 'Ej. María García López',
          icon: Icons.badge_outlined,
          capitalization: TextCapitalization.words,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _RegField(
          controller: emailCtrl,
          label: 'Correo electrónico',
          hint: 'tu@correo.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _RegField(
          controller: phoneCtrl,
          label: 'Teléfono celular',
          hint: 'Opcional — 04xx-xxx-xxxx',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          action: TextInputAction.done,
          onSubmitted: (_) => onNext(),
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\-+() ]'))],
        ),
        const SizedBox(height: 20),
        const _InfoCard(
          icon: Icons.lock_outline_rounded,
          text: 'Tu información está protegida. Nunca compartimos tus datos con terceros.',
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// STEP 1 — Dirección y emergencia
// ────────────────────────────────────────────────────────────────────────────
class _Step1 extends StatelessWidget {
  final TextEditingController addressCtrl;
  final TextEditingController emergencyNameCtrl;
  final TextEditingController emergencyPhoneCtrl;
  final VoidCallback onNext;

  const _Step1({
    required this.addressCtrl,
    required this.emergencyNameCtrl,
    required this.emergencyPhoneCtrl,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RegField(
          controller: addressCtrl,
          label: 'Dirección de residencia',
          hint: 'Calle, sector, ciudad...',
          icon: Icons.home_outlined,
          capitalization: TextCapitalization.sentences,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        // ── Emergency section header ──────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.emergency.withValues(alpha: 0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.emergency.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.emergency.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emergency_rounded, color: AppColors.emergency, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacto de emergencia',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Un familiar o persona de confianza',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RegField(
          controller: emergencyNameCtrl,
          label: 'Nombre del contacto',
          hint: 'Ej. Juan García (padre)',
          icon: Icons.person_outline_rounded,
          capitalization: TextCapitalization.words,
          action: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _RegField(
          controller: emergencyPhoneCtrl,
          label: 'Teléfono del contacto',
          hint: '04xx-xxx-xxxx',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          action: TextInputAction.done,
          onSubmitted: (_) => onNext(),
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\-+() ]'))],
        ),
        const SizedBox(height: 16),
        const _InfoCard(
          icon: Icons.info_outline_rounded,
          text: 'Este paso es opcional pero recomendado para casos de emergencia médica.',
          color: AppColors.info,
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// STEP 2 — Contraseña
// ────────────────────────────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  const _Step2({
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RegField(
          controller: passCtrl,
          label: 'Contraseña',
          hint: 'Mínimo 6 caracteres',
          icon: Icons.lock_outline_rounded,
          obscureText: obscurePass,
          action: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: onTogglePass,
          ),
        ),
        const SizedBox(height: 14),
        _RegField(
          controller: confirmCtrl,
          label: 'Confirmar contraseña',
          hint: 'Repite tu contraseña',
          icon: Icons.lock_person_rounded,
          obscureText: obscureConfirm,
          action: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          suffixIcon: IconButton(
            icon: Icon(
              obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: onToggleConfirm,
          ),
        ),
        const SizedBox(height: 20),
        // ── Password hints ──────────────────────────────────────────────
        _PasswordHint(controller: passCtrl),
        const SizedBox(height: 16),
        const _InfoCard(
          icon: Icons.shield_rounded,
          text: 'Usa al menos 6 caracteres. Combina letras y números para mayor seguridad.',
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Password strength hint
// ────────────────────────────────────────────────────────────────────────────
class _PasswordHint extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordHint({required this.controller});

  @override
  State<_PasswordHint> createState() => _PasswordHintState();
}

class _PasswordHintState extends State<_PasswordHint> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pass = widget.controller.text;
    if (pass.isEmpty) return const SizedBox.shrink();

    final rules = [
      (pass.length >= 6, 'Mínimo 6 caracteres'),
      (RegExp(r'[A-Z]').hasMatch(pass), 'Una letra mayúscula'),
      (RegExp(r'[0-9]').hasMatch(pass), 'Un número'),
    ];

    return Column(
      children: rules.map((r) {
        final ok = r.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ok
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: ok
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(
                  ok ? Icons.check_rounded : Icons.close_rounded,
                  size: 11,
                  color: ok ? Colors.white : Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                r.$2,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: ok ? Colors.white : Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
