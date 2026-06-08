import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/app_notifications.dart';
import '../../data/notifications_api_service.dart';
import '../../domain/models/notification_models.dart';
import 'clinic_invitation_notification_tile.dart';
import 'consultation_closure_notification_tile.dart';

/// Bandeja desplegable de notificaciones (citas, mensajes, etc.).
class NotificationsDropdown extends StatefulWidget {
  final VoidCallback? onClose;

  const NotificationsDropdown({super.key, this.onClose});

  @override
  State<NotificationsDropdown> createState() => _NotificationsDropdownState();
}

class _NotificationsDropdownState extends State<NotificationsDropdown> {
  final _api = NotificationsApiService();
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  StreamSubscription<void>? _refreshSub;

  @override
  void initState() {
    super.initState();
    _load();
    _socketSub = AppRealtime.chatSocket.onNotificationNew.listen((_) {
      if (mounted) _load();
    });
    _refreshSub = AppNotifications.onRefresh.listen((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _refreshSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AppSession.isLoggedIn) {
      setState(() {
        _loading = false;
        _error = 'Inicia sesión para ver avisos';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.list();
      if (!mounted) return;
      setState(() {
        _items = _sortInbox(list);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los avisos';
        _loading = false;
      });
    }
  }

  List<AppNotification> _sortInbox(List<AppNotification> list) {
    int priority(AppNotification n) {
      if (!n.isRead && n.isPendingConsultationClosure) return 0;
      if (!n.isRead) return 1;
      if (n.isPendingConsultationClosure) return 2;
      return 3;
    }

    return [...list]..sort((a, b) {
        final pa = priority(a);
        final pb = priority(b);
        if (pa != pb) return pa.compareTo(pb);
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  Future<void> _markAllRead() async {
    await _api.markAllRead();
    await _load();
  }

  Future<void> _onTap(AppNotification n) async {
    if (n.isPendingConsultationClosure) return;
    if (!n.isRead) {
      await _api.markRead(n.id);
    }
    widget.onClose?.call();
    if (!mounted) return;
    final path = n.relatedPath;
    if (path != null && path.isNotEmpty) {
      if (path == AppRoutes.messages && n.relatedId != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.messages,
          arguments: {'conversationId': n.relatedId},
        );
      } else {
        Navigator.pushNamed(context, path);
      }
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.isRead).length;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notificaciones',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (unread > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text('Marcar leídas'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No tienes avisos',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Aquí verás recordatorios de citas y mensajes de tu médico.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
        itemBuilder: (_, i) {
          final n = _items[i];
          if (n.isPendingClinicInvitation) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClinicInvitationNotificationTile(
                  notification: n,
                  onUpdated: _load,
                ),
                const Divider(height: 1),
              ],
            );
          }
          if (n.isPendingConsultationClosure) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConsultationClosureNotificationTile(
                  notification: n,
                  onUpdated: _load,
                ),
                const Divider(height: 1),
              ],
            );
          }
          return _NotificationTile(
            notification: n,
            onTap: () => _onTap(n),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData _iconFor(AppNotification n) {
    if (n.relatedPath == AppRoutes.messages) {
      return Icons.chat_bubble_outline;
    }
    if (n.relatedPath == AppRoutes.appointments) {
      return Icons.event_rounded;
    }
    return Icons.info_outline;
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.info:
        return AppColors.primary;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final color = _colorFor(n.type);

    return Material(
      color: n.isRead ? Colors.transparent : AppColors.primaryLight.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(n), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight:
                                  n.isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(n.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
