import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../data/notifications_api_service.dart';
import 'notifications_dropdown.dart';

/// Icono de campana con contador y panel desplegable de notificaciones.
class NotificationBadge extends StatefulWidget {
  const NotificationBadge({super.key});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final _api = NotificationsApiService();
  int _unread = 0;
  OverlayEntry? _overlay;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refreshCount();
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) => _refreshCount());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
      if (mounted) setState(() => _unread = count);
    } catch (_) {}
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
        IconButton(
          icon: const Icon(Icons.notifications_none, size: 28),
          tooltip: 'Notificaciones',
          onPressed: AppSession.isLoggedIn ? _toggleDropdown : null,
        ),
        if (_unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
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
