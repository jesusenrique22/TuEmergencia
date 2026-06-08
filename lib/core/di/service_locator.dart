import 'package:get_it/get_it.dart';

import '../connectivity/service_connectivity.dart';
import '../network/api_client.dart';
import '../../features/emergency/di/emergency_module.dart';

final GetIt sl = GetIt.instance;

/// Registro único de clientes de red (escalable: mocks, entornos, tests).
void setupServiceLocator() {
  if (sl.isRegistered<ApiClient>()) return;
  sl.registerSingleton<ApiClient>(ApiClient.instance);
  sl.registerLazySingleton<ServiceConnectivity>(
    () => ServiceConnectivity.instance,
  );
  registerEmergencyModule();
}
