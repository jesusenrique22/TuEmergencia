import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/appointment_datetime.dart';
import '../../domain/models/appointment.dart';

enum _ReminderPhase { approaching, started }

class _ReminderPayload {
  final Appointment appointment;
  final _ReminderPhase phase;
  final String title;
  final String subtitle;
  final String showKey;

  const _ReminderPayload({
    required this.appointment,
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.showKey,
  });
}

/// Aviso flotante cuando una cita se acerca o comienza (informes pendientes → bandeja 🔔).
class AppointmentReminderHost extends StatefulWidget {
  final Widget child;
  final Future<List<Appointment>> Function() loadAppointments;

  const AppointmentReminderHost({
    super.key,
    required this.child,
    required this.loadAppointments,
  });

  @override
  State<AppointmentReminderHost> createState() => _AppointmentReminderHostState();
}

class _AppointmentReminderHostState extends State<AppointmentReminderHost>
    with SingleTickerProviderStateMixin {
  static const _approachWindow = Duration(minutes: 20);
  static const _startedGrace = Duration(minutes: 8);
  static const _displayDuration = Duration(seconds: 7);

  Timer? _pollTimer;
  Timer? _hideTimer;
  Duration _pollInterval = const Duration(seconds: 15);
  final Set<String> _shownKeys = {};
  _ReminderPayload? _active;
  late final AnimationController _anim;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    if (AppSession.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
      _schedulePoll();
    }
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(_pollInterval, () async {
      await _evaluate();
      _schedulePoll();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _hideTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _playAlert() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  String _otherPartyName(Appointment a) {
    final userId = AppSession.currentUser?.id;
    if (userId != null && a.doctorId == userId) {
      return a.patientName;
    }
    return a.doctorName;
  }

  int? _approachMilestone(Duration untilStart) {
    if (untilStart <= Duration.zero) return null;
    final mins = untilStart.inMinutes;
    if (mins >= 19) return 20;
    if (mins >= 9) return 10;
    if (mins >= 4) return 5;
    if (mins >= 1) return 1;
    return 0;
  }

  _ReminderPayload? _pickReminder(List<Appointment> appointments) {
    final now = DateTime.now();
    _ReminderPayload? best;
    int bestPriority = -1;

    for (final appt in appointments) {
      if (appt.status == AppointmentStatus.cancelled ||
          appt.status == AppointmentStatus.completed ||
          appt.needsClosure) {
        for (final m in [20, 10, 5, 1, 0]) {
          _shownKeys.remove('${appt.id}-approach-$m');
        }
        _shownKeys.remove('${appt.id}-started');
        continue;
      }

      final start = appointmentDisplayLocal(appt.dateTime);
      final end = appt.endTime != null
          ? appointmentDisplayLocal(appt.endTime!)
          : start.add(Duration(minutes: appt.durationMinutes));
      final untilStart = start.difference(now);
      final sinceStart = now.difference(start);
      final other = _otherPartyName(appt);
      final when = formatAppointmentDateTime(appt.dateTime);

      if (now.isAfter(end) && sinceStart > _startedGrace) continue;

      if (sinceStart >= Duration.zero &&
          sinceStart <= _startedGrace &&
          now.isBefore(end)) {
        final key = '${appt.id}-started';
        if (!_shownKeys.contains(key)) {
          const priority = 3;
          if (priority > bestPriority) {
            bestPriority = priority;
            best = _ReminderPayload(
              appointment: appt,
              phase: _ReminderPhase.started,
              showKey: key,
              title: '¡Tu cita ya comenzó!',
              subtitle: 'Con $other · $when',
            );
          }
        }
        continue;
      }

      if (untilStart > Duration.zero && untilStart <= _approachWindow) {
        final milestone = _approachMilestone(untilStart);
        if (milestone == null) continue;
        final key = '${appt.id}-approach-$milestone';
        if (_shownKeys.contains(key)) continue;

        final mins = untilStart.inMinutes.clamp(0, 999);
        final priority = milestone == 0 ? 2 : 1;
        if (priority <= bestPriority) continue;

        bestPriority = priority;
        final title = switch (milestone) {
          20 => 'Cita en 20 minutos',
          10 => 'Cita en 10 minutos',
          5 => 'Cita en 5 minutos',
          1 => 'Cita en 1 minuto',
          _ => mins <= 0 ? '¡Tu cita es ahora!' : 'Tu cita se acerca',
        };
        final subtitle = milestone == 0
            ? 'Con $other · $when'
            : 'Con $other en $mins min · $when';

        best = _ReminderPayload(
          appointment: appt,
          phase: _ReminderPhase.approaching,
          showKey: key,
          title: title,
          subtitle: subtitle,
        );
      }
    }

    return best;
  }

  Future<void> _evaluate() async {
    if (!AppSession.isLoggedIn || !mounted) return;
    try {
      final list = await widget.loadAppointments();
      if (!mounted) return;

      final next = _pickReminder(list);
      if (next == null) return;
      if (_active != null) {
        if (_active!.showKey == next.showKey) return;
        _hideTimer?.cancel();
        _anim.reverse().then((_) {
          if (mounted) _show(next);
        });
        return;
      }
      _show(next);
      _pollInterval = const Duration(seconds: 15);
    } on ApiException catch (_) {
      _pollInterval = const Duration(seconds: 60);
    } catch (_) {
      _pollInterval = const Duration(seconds: 60);
    }
  }

  void _show(_ReminderPayload payload) {
    _shownKeys.add(payload.showKey);
    _hideTimer?.cancel();
    _playAlert();
    setState(() => _active = payload);
    _anim.forward(from: 0);
    _hideTimer = Timer(_displayDuration, _dismiss);
  }

  void _dismiss() {
    if (_active == null) return;
    _anim.reverse().then((_) {
      if (mounted) setState(() => _active = null);
    });
  }

  void _openAppointments() {
    _dismiss();
    Navigator.pushNamed(context, AppRoutes.appointments);
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        widget.child,
        if (active != null)
          Positioned(
            left: 12,
            right: 12,
            top: top + 8,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: _AppointmentReminderBanner(
                  payload: active,
                  onTap: _openAppointments,
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AppointmentReminderBanner extends StatelessWidget {
  final _ReminderPayload payload;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _AppointmentReminderBanner({
    required this.payload,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isStarted = payload.phase == _ReminderPhase.started;
    final colors = isStarted
        ? [const Color(0xFF059669), const Color(0xFF047857)]
        : [AppColors.warning, const Color(0xFFD97706)];
    final icon = isStarted
        ? Icons.play_circle_filled_rounded
        : Icons.schedule_rounded;

    return Material(
      elevation: 16,
      shadowColor: colors.first.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payload.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payload.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
