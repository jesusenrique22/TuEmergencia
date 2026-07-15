import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/branding/app_branding.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/experience/animated_blobs.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/promo/promo_carousel.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../data/auth_api_service.dart';

import '../../domain/models/role.dart';
import '../../../patient_profile/data/patient_profile_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApi = AuthApiService();
  bool _obscureText = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Ingresa correo y contraseña');
      return;
    }

    setState(() => _loading = true);
    var navigatedAway = false;
    try {
      final response = await _authApi.login(email: email, password: password);
      navigatedAway = await _onAuthSuccess(response);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(
        kReleaseMode
            ? 'No se pudo conectar al servidor. Verifica tu Internet e intenta de nuevo.'
            : 'No se pudo conectar al servidor (${ApiConfig.baseUrl}). Ejecuta: cd backend && pnpm run dev',
      );
      debugPrint('Login error: $e');
    } finally {
      if (mounted && !navigatedAway) setState(() => _loading = false);
    }
  }

  Future<bool> _onAuthSuccess(AuthResponse response) async {
    AppSession.setSession(user: response.user, tokenValue: response.token);
    AppRealtime.reconnectAfterAuth();
    if (response.user.role == Role.patient) {
      await PatientProfileRepository.refreshFromApi();
    }
    if (!mounted) return false;

    if (response.user.role == Role.patient) {
      final completed = PatientProfileRepository.activeProfile?.medicalHistoryCompleted ?? false;
      if (!completed) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.clinicalHistory,
          arguments: {'onboarding': true},
        );
        return true;
      }
    }

    Navigator.pushReplacementNamed(
      context,
      AppNavigation.homeRouteForRole(response.user.role),
    );
    return true;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.emergency,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.border == Colors.black ? 8 : 12),
        ),
      ),
    );
  }

  void _goToRegister() {
    Navigator.pushNamed(context, AppRoutes.register);
  }

  void _fillDemoCredentials(String email) {
    _emailController.text = email;
    _passwordController.text = 'password';
  }

  Future<void> _loginAsDemo(String email) async {
    _fillDemoCredentials(email);
    await _submitLogin();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return ResponsiveScaffold(
      hideNavigation: true,
      hideAppBar: true,
      body: AnimatedBlobsBackground(
        child: SafeArea(
          child: isWide
              ? _buildWideLayout(context)
              : _buildMobileLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: Column(
        children: [
          FadeSlideIn(child: _buildLogo()),
          const SizedBox(height: AppSpacing.xl),
          FadeSlideIn(
            index: 1,
            child: PromoCarousel(offers: PromoMockData.loginSlides),
          ),
          const SizedBox(height: AppSpacing.xl),
          FadeSlideIn(index: 2, child: _buildFormCard(context, isCompact: true)),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: FadeSlideIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo(maxWidth: 480),
                        const SizedBox(height: AppSpacing.xxl),
                        PromoCarousel(offers: PromoMockData.loginSlides),
                        const SizedBox(height: AppSpacing.xxl),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: const [
                            _FeatureChip(
                                label: 'Citas',
                                icon: Icons.calendar_month_rounded),
                            _FeatureChip(
                                label: 'Emergencias',
                                icon: Icons.emergency_rounded),
                            _FeatureChip(
                                label: 'Farmacia',
                                icon: Icons.local_pharmacy_rounded),
                            _FeatureChip(
                                label: 'Seguros', icon: Icons.shield_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                SizedBox(
                  width: 430,
                  child: FadeSlideIn(
                    index: 2,
                    offset: const Offset(0.08, 0),
                    child: _buildFormCard(context, isCompact: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo({double maxWidth = 320}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const aspect = 1071 / 233;
        final width = (constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width)
            .clamp(0.0, maxWidth);
        return Image.asset(
          AppBranding.loginLogo,
          width: width,
          height: width / aspect,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
      },
    );
  }

  Widget _buildFormCard(BuildContext context, {required bool isCompact}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(isCompact ? 24 : 36),
          child: _buildFormFields(context, isCompact: isCompact),
        ),
      ),
    );
  }

  Widget _buildFormFields(BuildContext context, {required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header de la tarjeta
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.headerGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.health_and_safety_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido de vuelta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                          fontSize: 20,
                        ),
                  ),
                  Text(
                    'Inicia sesión en tu cuenta',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 22 : 30),

        // Campo de correo
        _PremiumTextField(
          controller: _emailController,
          enabled: !_loading,
          label: 'Correo electrónico',
          hint: 'nombre@ejemplo.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),

        // Campo de contraseña
        _PremiumTextField(
          controller: _passwordController,
          enabled: !_loading,
          label: 'Contraseña',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureText,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitLogin(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
        ),

        // Olvidé contraseña
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recuperación de contraseña próximamente'),
                      ),
                    ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            ),
            child: const Text(
              'Olvidé mi contraseña',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Botón principal
        _GradientButton(
          label: 'Iniciar sesión',
          loading: _loading,
          onPressed: _submitLogin,
        ),
        const SizedBox(height: 12),

        // Divisor
        Row(
          children: [
            Expanded(
              child: Divider(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'o',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: AppColors.border.withValues(alpha: 0.7)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Crear cuenta
        OutlinedButton.icon(
          onPressed: _loading ? null : _goToRegister,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('Crear cuenta de paciente'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(height: isCompact ? 16 : 20),
        _buildDemoSection(context, isCompact: isCompact),
      ],
    );
  }

  Widget _buildDemoSection(BuildContext context, {required bool isCompact}) {
    final demos = [
      _DemoEntry(
          'Paciente', Icons.person_rounded, () => _loginAsDemo('juan@patient.com')),
      _DemoEntry('Médico', Icons.health_and_safety_rounded,
          () => _loginAsDemo('maria@doctor.com')),
      _DemoEntry('Admin', Icons.admin_panel_settings_rounded,
          () => _loginAsDemo('admin@vita.com')),
      _DemoEntry('Clínica', Icons.local_hospital_rounded,
          () => _loginAsDemo('clinic.admin@vita.com')),
      _DemoEntry('Farmacia', Icons.local_pharmacy_rounded,
          () => _loginAsDemo('pharmacy.admin@vita.com')),
      _DemoEntry(
          'Lab', Icons.biotech_rounded, () => _loginAsDemo('lab@tech.com')),
      _DemoEntry(
          'Ambulancia',
          Icons.emergency_rounded,
          () => _loginAsDemo('conductor@vita.com')),
    ];

    final chips = Wrap(
      spacing: 7,
      runSpacing: 7,
      children: demos
          .map(
            (d) => ActionChip(
              avatar: Icon(d.icon, size: 14),
              label: Text(d.label),
              onPressed: _loading ? null : d.onPressed,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
              backgroundColor: AppColors.surfaceSoft,
            ),
          )
          .toList(),
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Cuentas de prueba',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
            ),
          ],
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(left: 14),
          child: Text(
            'Contraseña: password',
            style: TextStyle(
                fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ),
        children: [
          const SizedBox(height: 8),
          chips,
        ],
      ),
    );
  }
}

/// ── Campo de texto premium ──────────────────────────────────────────────────
class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _PremiumTextField({
    required this.controller,
    required this.enabled,
    required this.label,
    this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
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
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.8),
        ),
      ),
    );
  }
}

/// ── Feature chip para layout wide ──────────────────────────────────────────
class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FeatureChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Botón gradiente principal ────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.loading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.loading
                ? null
                : LinearGradient(
                    colors: _pressed
                        ? [
                            const Color(0xFF047857),
                            const Color(0xFF059669),
                          ]
                        : AppColors.headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.loading
                ? AppColors.primary.withValues(alpha: 0.5)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.loading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: _pressed ? 0.2 : 0.4),
                      blurRadius: _pressed ? 8 : 20,
                      offset: Offset(0, _pressed ? 2 : 8),
                      spreadRadius: _pressed ? -2 : 0,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoEntry {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _DemoEntry(this.label, this.icon, this.onPressed);
}

// Old _RegisterPatientForm and _RegisterPatientDialog removed.
// Registration is now handled by the full RegisterPage wizard.



