import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../data/consultation_follow_up_api_service.dart';

class ConsultationFollowUpSection extends StatelessWidget {
  final List<ConsultationFollowUpItem> items;
  final bool isDoctor;
  final VoidCallback? onScheduleTap;

  const ConsultationFollowUpSection({
    super.key,
    required this.items,
    required this.isDoctor,
    this.onScheduleTap,
  });

  String _statusLabel(FollowUpStatus status) {
    return switch (status) {
      FollowUpStatus.overdue => 'Vencido',
      FollowUpStatus.dueToday => 'Hoy',
      FollowUpStatus.upcoming => 'Próximo',
    };
  }

  Color _statusColor(FollowUpStatus status) {
    return switch (status) {
      FollowUpStatus.overdue => Colors.red.shade700,
      FollowUpStatus.dueToday => Colors.orange.shade800,
      FollowUpStatus.upcoming => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final urgent = items.where((i) => i.isUrgent).length;
    final dateFmt = DateFormat('d MMM yyyy', 'es');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.event_repeat_rounded,
                color: urgent > 0 ? Colors.orange.shade800 : AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isDoctor
                    ? 'Seguimientos de consultas'
                    : 'Controles programados por tu médico',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (isDoctor && urgent > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$urgent urgente${urgent == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
          ],
        ),
        if (!isDoctor) ...[
          const SizedBox(height: 6),
          Text(
            'Tu médico indicó estas fechas al cerrar la consulta. Si necesitas adelantar la cita, usa Agendar cita.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 10),
        ...items.take(4).map((item) {
          final name = isDoctor ? item.patientName : item.doctorName;
          final avatar = isDoctor ? item.patientAvatar : item.doctorAvatar;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: item.isUrgent
                    ? Colors.orange.shade200
                    : AppColors.primaryLight,
              ),
            ),
            child: ListTile(
              leading: SafeAvatar(radius: 20, imageUrl: avatar),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                [
                  'Control: ${dateFmt.format(item.followUpDate.toLocal())}',
                  if (item.followUpNote != null && item.followUpNote!.isNotEmpty)
                    item.followUpNote!,
                ].join('\n'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: isDoctor
                  ? Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(item.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(item.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(item.status),
                        ),
                      ),
                    )
                  : Icon(Icons.info_outline_rounded,
                      color: AppColors.primary.withValues(alpha: 0.7)),
              onTap: () => Navigator.pushNamed(context, AppRoutes.appointments),
            ),
          );
        }),
        if (!isDoctor && onScheduleTap != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onScheduleTap,
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Agendar cita (opcional)'),
            ),
          ),
      ],
    );
  }
}
