import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../data/auth_api_service.dart';
import '../../data/role_mapper.dart';
import '../../domain/models/role.dart';
import '../../../patient_profile/data/patient_profile_repository.dart';
import '../../../patient_profile/presentation/widgets/medical_history_prompt_dialog.dart';

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
    try {
      final response = await _authApi.login(email: email, password: password);
      _onAuthSuccess(response);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(
        'No se pudo conectar al servidor (${ApiConfig.baseUrl}). Ejecuta: cd backend && pnpm run dev',
      );
      debugPrint('Login error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onAuthSuccess(AuthResponse response) async {
    AppSession.setSession(user: response.user, tokenValue: response.token);
    if (response.user.role == Role.patient) {
      await PatientProfileRepository.refreshFromApi();
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppNavigation.homeRouteForRole(response.user.role),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _showRegisterDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear cuenta de paciente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Registrarse'),
          ),
        ],
      ),
    );

    if (created != true || !mounted) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
      confirmController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;
    final phone = phoneController.text.trim();

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Completa nombre, correo y contraseña');
      return;
    }
    if (password != confirm) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    if (password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await _authApi.register(
        email: email,
        password: password,
        name: name,
        roleApi: RoleMapper.toApi(Role.patient),
        phone: phone.isEmpty ? null : phone,
      );
      AppSession.setSession(user: response.user, tokenValue: response.token);
      await PatientProfileRepository.refreshFromApi();
      if (!mounted) return;
      final fillHistory = await showMedicalHistoryPrompt(context);
      if (!mounted) return;
      if (fillHistory == true) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.clinicalHistory,
          arguments: {'onboarding': true},
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('No se pudo conectar al servidor. Inicia el backend (pnpm run dev).');
      debugPrint('Register error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemoCredentials(String email) {
    _emailController.text = email;
    _passwordController.text = 'password';
  }

  Future<void> _loginAsDemo(String email) async {
    _fillDemoCredentials(email);
    await _submitLogin();
  }

  void _enterMockRole(Role role, String route) {
    AppSession.clear();
    AppSession.setRole(role);
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      hideNavigation: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AppPage(
            maxWidth: 1120,
            padding: const EdgeInsets.all(28),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;

                final form = AppPanel(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Accede a tu cuenta',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión con tu cuenta o regístrate como paciente.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        enabled: !_loading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        enabled: !_loading,
                        obscureText: _obscureText,
                        onSubmitted: (_) => _submitLogin(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () =>
                                setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Recuperación de contraseña próximamente',
                                      ),
                                    ),
                                  );
                                },
                          child: const Text('Olvidé mi contraseña'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _loading ? null : _submitLogin,
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(_loading ? 'Entrando...' : 'Iniciar sesión'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _showRegisterDialog,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Crear cuenta de paciente'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cuentas de prueba (contraseña: password)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildDemoButton(
                            'Paciente',
                            Icons.person_rounded,
                            () => _loginAsDemo('juan@patient.com'),
                          ),
                          _buildDemoButton(
                            'Médico',
                            Icons.health_and_safety_rounded,
                            () => _loginAsDemo('maria@doctor.com'),
                          ),
                          _buildDemoButton(
                            'Jefe app',
                            Icons.admin_panel_settings_rounded,
                            () => _loginAsDemo('admin@vita.com'),
                          ),
                          _buildDemoButton(
                            'Admin clínica',
                            Icons.local_hospital_rounded,
                            () => _loginAsDemo('clinic.admin@vita.com'),
                          ),
                          _buildDemoButton(
                            'Admin farmacia',
                            Icons.local_pharmacy_rounded,
                            () => _loginAsDemo('pharmacy.admin@vita.com'),
                          ),
                          _buildDemoButton(
                            'Farmacéutico',
                            Icons.science_outlined,
                            () => _loginAsDemo('farmacista@vita.com'),
                          ),
                          _buildDemoButton(
                            'Ambulancia',
                            Icons.emergency_rounded,
                            () => _enterMockRole(
                              Role.driver,
                              AppRoutes.ambulanceDashboard,
                            ),
                          ),
                          _buildDemoButton(
                            'Farmacia',
                            Icons.inventory_2_rounded,
                            () => _enterMockRole(
                              Role.pharmacy,
                              AppRoutes.pharmacyAdmin,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final hero = AppHeroPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'VITA OS',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 44,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pacientes, médicos y administradores conectados a la base de datos.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AppStatusPill(label: 'Citas', color: Colors.white),
                          AppStatusPill(label: 'Emergencias', color: Colors.white),
                          AppStatusPill(label: 'Resultados', color: Colors.white),
                          AppStatusPill(label: 'Seguros', color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                );

                if (!isWide) {
                  return Column(children: [hero, const SizedBox(height: 20), form]);
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: hero),
                    const SizedBox(width: 24),
                    SizedBox(width: 430, child: form),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
