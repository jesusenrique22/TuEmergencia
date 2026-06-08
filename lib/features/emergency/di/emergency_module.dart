import '../../../core/di/service_locator.dart';
import '../../../core/location/device_location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/app_realtime.dart';
import '../../catalog/data/datasources/catalog_remote_datasource.dart';
import '../../catalog/data/repositories/catalog_repository_impl.dart';
import '../../catalog/domain/repositories/catalog_repository.dart';
import '../application/emergency_tracking_controller.dart';
import '../data/datasources/emergency_remote_datasource.dart';
import '../data/realtime/socket_emergency_realtime_client.dart';
import '../data/repositories/emergency_repository_impl.dart';
import '../domain/repositories/emergency_repository.dart';

/// Registro de dependencias del módulo de emergencias, catálogo y mapa.
void registerEmergencyModule() {
  if (sl.isRegistered<CatalogRepository>()) return;

  sl.registerLazySingleton<CatalogRemoteDataSource>(
    () => CatalogRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<CatalogRepository>(
    () => CatalogRepositoryImpl(sl<CatalogRemoteDataSource>()),
  );

  sl.registerLazySingleton<EmergencyRemoteDataSource>(
    () => EmergencyRemoteDataSource(sl<ApiClient>()),
  );
  sl.registerLazySingleton<EmergencyRepository>(
    () => EmergencyRepositoryImpl(sl<EmergencyRemoteDataSource>()),
  );
  sl.registerLazySingleton<EmergencyRealtimeClient>(
    () => SocketEmergencyRealtimeClient(AppRealtime.chatSocket),
  );
  sl.registerLazySingleton<DeviceLocationService>(
    () => GeolocatorDeviceLocationService(),
  );

  sl.registerFactory<EmergencyTrackingController>(
    () => EmergencyTrackingController(
      repository: sl<EmergencyRepository>(),
      realtime: sl<EmergencyRealtimeClient>(),
    ),
  );
  sl.registerFactory<DriverLocationPublisher>(
    () => DriverLocationPublisher(
      repository: sl<EmergencyRepository>(),
      locationService: sl<DeviceLocationService>(),
    ),
  );
}
