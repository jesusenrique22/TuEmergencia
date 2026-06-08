import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/database/data/mongo_service.dart';
import 'core/auth/app_session.dart';
import 'features/auth/domain/models/role.dart';
import 'features/patient_profile/data/patient_profile_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_navigation.dart';
import 'core/navigation/app_routes.dart';
import 'core/config/api_config.dart';
import 'core/di/service_locator.dart';
import 'core/services/app_realtime.dart';
import 'core/connectivity/service_connectivity.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Calienta el proxy/API en segundo plano (no bloquea la UI).
void _warmDevStackInBackground() {
  if (!kIsWeb || !ApiConfig.openedViaDevTunnel) return;
  unawaited(
    ServiceConnectivity.instance.isApiReachable(
      timeout: const Duration(seconds: 2),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Ignorar errores de carga en web u otros entornos donde .env no esté disponible
    debugPrint('Warning: No se pudo cargar .env - $e');
  }
  setupServiceLocator();
  _warmDevStackInBackground();
  if (!kIsWeb && dotenv.isInitialized && dotenv.env['MONGODB_URI']?.isNotEmpty == true) {
    try {
      await MongoService().init();
      debugPrint('MongoDB conectado');
    } catch (e) {
      // Backend principal usa PostgreSQL; Mongo solo para migración legacy.
      debugPrint('MongoDB no disponible (opcional): $e');
    }
  }
  final hasSession = await AppSession.restore();
  AppSession.onSessionEnded = AppRealtime.disconnect;
  if (hasSession && AppSession.currentUser?.role == Role.patient) {
    unawaited(PatientProfileRepository.refreshFromApi());
  }
  AppRealtime.bindNavigator(appNavigatorKey);
  if (kIsWeb) {
    // Visible en release (DevTools → Console) al depurar túneles.
    debugPrint('[ApiConfig] web origin=${ApiConfig.webOriginLabel}');
    debugPrint('[ApiConfig] API=${ApiConfig.baseUrl} SOCKET=${ApiConfig.socketUrl}');
  }
  if (kDebugMode) {
    ApiConfig.logResolvedEndpoints();
  }
  runApp(VitaOSApp(hasSession: hasSession));
}

class VitaOSApp extends StatefulWidget {
  final bool hasSession;

  const VitaOSApp({super.key, this.hasSession = false});

  @override
  State<VitaOSApp> createState() => _VitaOSAppState();
}

class _VitaOSAppState extends State<VitaOSApp> {
  String get _bootRoute {
    if (widget.hasSession && AppSession.currentUser != null) {
      return AppNavigation.homeRouteForRole(AppSession.currentUser!.role);
    }
    return AppRoutes.login;
  }

  @override
  Widget build(BuildContext context) {
    final bootRoute = _bootRoute;
    final bootBuilder =
        AppRoutes.routes[bootRoute] ?? AppRoutes.routes[AppRoutes.login]!;

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Smart Medic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(
          settings: RouteSettings(name: bootRoute),
          builder: bootBuilder,
        ),
      ],
      routes: AppRoutes.routes,
      onUnknownRoute: (_) {
        final fallback = AppNavigation.homeRouteForRole(AppSession.activeRole);
        final builder =
            AppRoutes.routes[fallback] ?? AppRoutes.routes[AppRoutes.login]!;
        return MaterialPageRoute(
          settings: RouteSettings(name: fallback),
          builder: builder,
        );
      },
    );
  }
}
