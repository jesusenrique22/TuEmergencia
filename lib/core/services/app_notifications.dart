import 'dart:async';

/// Refresco global de la bandeja de notificaciones (campana).
class AppNotifications {
  static final _refreshController = StreamController<void>.broadcast();

  static Stream<void> get onRefresh => _refreshController.stream;

  static void requestRefresh() {
    if (!_refreshController.isClosed) {
      _refreshController.add(null);
    }
  }
}
