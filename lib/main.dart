import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/database/data/mongo_service.dart';
import 'core/auth/app_session.dart';
import 'features/auth/domain/models/role.dart';
import 'features/patient_profile/data/patient_profile_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_navigation.dart';
import 'core/navigation/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Ignorar errores de carga en web u otros entornos donde .env no esté disponible
    debugPrint('Warning: No se pudo cargar .env - $e');
  }
  if (!kIsWeb && dotenv.env['MONGODB_URI']?.isNotEmpty == true) {
    try {
      await MongoService().init();
      debugPrint('MongoDB conectado');
    } catch (e) {
      debugPrint('MongoDB no disponible: $e');
    }
  }
  final hasSession = await AppSession.restore();
  if (hasSession && AppSession.currentUser?.role == Role.patient) {
    await PatientProfileRepository.refreshFromApi();
  }
  runApp(VitaOSApp(hasSession: hasSession));
}

class VitaOSApp extends StatelessWidget {
  final bool hasSession;

  const VitaOSApp({super.key, this.hasSession = false});

  @override
  Widget build(BuildContext context) {
    final initialRoute = hasSession && AppSession.currentUser != null
        ? AppNavigation.homeRouteForRole(AppSession.currentUser!.role)
        : AppRoutes.login;

    return MaterialApp(
      title: 'VITA OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: AppRoutes
            .routes[AppNavigation.homeRouteForRole(AppSession.activeRole)]!,
      ),
    );
  }
}
