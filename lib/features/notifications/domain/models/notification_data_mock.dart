import 'notification_models.dart';
import '../../../../core/navigation/app_routes.dart';

class NotificationDataMock {
  static List<AppNotification> notifications = [
    // --- Notificaciones del Paciente (pat-123) ---
    AppNotification(
      id: 'not-001',
      userId: 'pat-123',
      title: 'Póliza Validada',
      message:
          'Tu seguro "Salud Vital" ha cubierto \$150.00 del traslado en ambulancia.',
      type: NotificationType.success,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      relatedPath: AppRoutes.insuranceWallet,
    ),
    AppNotification(
      id: 'not-002',
      userId: 'pat-123',
      title: 'Resultados Listos',
      message:
          'Tus resultados de "Perfil 20" ya están disponibles para su descarga.',
      type: NotificationType.info,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      relatedPath: AppRoutes.labResults,
    ),

    // --- Notificaciones de la Clínica (clinic-001) ---
    AppNotification(
      id: 'not-003',
      userId: 'clinic-001',
      title: 'Emergencia en Camino',
      message:
          'La ambulancia AMB-001 está a 5 minutos. Paciente: Juan Pérez. Código: ROJO.',
      type: NotificationType.alert,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: false,
      relatedPath: AppRoutes.erDashboard,
    ),
    AppNotification(
      id: 'not-004',
      userId: 'clinic-001',
      title: 'Factura Procesada',
      message: 'La aseguradora ha procesado el pago de la factura INV-8801.',
      type: NotificationType.success,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      relatedPath: AppRoutes.clinicBilling,
    ),

    // --- Notificaciones del Conductor (driver-001) ---
    AppNotification(
      id: 'not-005',
      userId: 'driver-001',
      title: 'Nueva Ruta Asignada',
      message:
          'Se ha asignado un traslado de emergencia. Dirígete a la ubicación del paciente.',
      type: NotificationType.warning,
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      isRead: false,
      relatedPath: AppRoutes.ambulanceDashboard,
    ),
  ];

  static List<AppNotification> getUnreadForUser(String userId) {
    return notifications.where((n) => n.userId == userId && !n.isRead).toList();
  }

  static List<AppNotification> getAllForUser(String userId) {
    var userNotifs = notifications.where((n) => n.userId == userId).toList();
    userNotifs.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    ); // Más recientes primero
    return userNotifs;
  }

  static void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index].isRead = true;
    }
  }

  static void markAllAsRead(String userId) {
    for (var n in notifications.where((n) => n.userId == userId)) {
      n.isRead = true;
    }
  }
}
