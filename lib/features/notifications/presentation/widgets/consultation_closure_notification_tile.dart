import 'package:flutter/material.dart';

import '../../../../core/services/consultation_closure_coordinator.dart';
import '../../../../core/services/app_notifications.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/notification_models.dart';

/// Aviso en bandeja: informe de consulta pendiente (solo médico).
class ConsultationClosureNotificationTile extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onUpdated;

  const ConsultationClosureNotificationTile({
    super.key,
    required this.notification,
    required this.onUpdated,
  });

  @override
  State<ConsultationClosureNotificationTile> createState() =>
      _ConsultationClosureNotificationTileState();
}

class _ConsultationClosureNotificationTileState
    extends State<ConsultationClosureNotificationTile> {
  bool _opening = false;

  Future<void> _openClosure() async {
    final id = widget.notification.relatedId;
    if (id == null || id.isEmpty || _opening) return;
    setState(() => _opening = true);
    try {
      final done = await ConsultationClosureCoordinator.openForId(id);
      if (done == true) {
        AppNotifications.requestRefresh();
      }
      widget.onUpdated();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;

    return Material(
      color: AppColors.warning.withValues(alpha: 0.08),
      child: InkWell(
        onTap: _opening ? null : _openClosure,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: _opening
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.assignment_late_rounded,
                        color: Colors.orange,
                        size: 22,
                      ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
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
                    const SizedBox(height: 6),
                    Text(
                      'Toca para completar el informe',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
