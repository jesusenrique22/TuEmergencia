import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/services/app_notifications.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/network/api_client.dart' show ApiException;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/profile_ui.dart';
import '../../data/notifications_api_service.dart';
import 'notifications_dropdown.dart';

/// Icono de campana con contador y panel desplegable de notificaciones.
class NotificationBadge extends StatefulWidget {
  /// Fondo oscuro (header con gradiente): icono blanco en círculo semitransparente.
  final bool onDarkBackground;

  const NotificationBadge({super.key, this.onDarkBackground = false});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final _api = NotificationsApiService();
  int _unread = 0;
  OverlayEntry? _overlay;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  StreamSubscription<void>? _refreshSub;
  Duration _pollInterval = const Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    _refreshCount();
    _schedulePoll();
    _socketSub = AppRealtime.chatSocket.onNotificationNew.listen((_) {
      _refreshCount();
    });
    _refreshSub = AppNotifications.onRefresh.listen((_) {
      _refreshCount();
    });
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(_pollInterval, () async {
      await _refreshCount();
      _schedulePoll();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socketSub?.cancel();
    _refreshSub?.cancel();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _refreshCount() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) setState(() => _unread = 0);
      return;
    }
    try {
      final count = await _api.unreadCount();
      if (mounted) {
        setState(() => _unread = count);
        _pollInterval = const Duration(seconds: 45);
      }
    } on ApiException catch (_) {
      _pollInterval = const Duration(seconds: 120);
    } catch (_) {
      _pollInterval = const Duration(seconds: 120);
    }
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _toggleDropdown() {
    if (_overlay != null) {
      _removeOverlay();
      return;
    }

    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final screenW = MediaQuery.of(context).size.width;
    double left = offset.dx + box.size.width - 380;
    if (left < 8) left = 8;
    if (left + 380 > screenW - 8) left = screenW - 388;

    _overlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.black26),
            ),
          ),
          Positioned(
            left: left,
            top: offset.dy + box.size.height + 8,
            child: NotificationsDropdown(
              onClose: () {
                _removeOverlay();
                _refreshCount();
              },
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlay!);
    _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProfileHeaderIconButton(
          onDarkBackground: widget.onDarkBackground,
          tooltip: 'Notificaciones',
          onPressed: AppSession.isLoggedIn ? _toggleDropdown : null,
          icon: _unread > 0
              ? Icons.notifications_rounded
              : Icons.notifications_outlined,
        ),
        if (_unread > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.emergency,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.onDarkBackground ? AppColors.primaryDark : Colors.white,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unread > 9 ? '9+' : '$_unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
