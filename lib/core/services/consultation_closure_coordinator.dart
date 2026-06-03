import 'package:flutter/material.dart';

import '../../features/appointments/domain/models/appointment.dart';
import '../../features/appointments/presentation/pages/consultation_closure_page.dart';
import '../../main.dart';
import '../auth/app_session.dart';
import '../../features/auth/domain/models/role.dart';

/// Abre el formulario de cierre cuando una cita terminó y falta el informe.
class ConsultationClosureCoordinator {
  static String? _pendingShownForAppointmentId;

  static void resetSession() {
    _pendingShownForAppointmentId = null;
  }

  static Appointment? findNextPending(List<Appointment> appointments) {
    if (AppSession.activeRole != Role.doctor) return null;
    final pending = appointments.where((a) => a.needsClosure).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return pending.isEmpty ? null : pending.first;
  }

  static Future<void> openIfNeeded(
    List<Appointment> appointments, {
    bool force = false,
  }) async {
    final appt = findNextPending(appointments);
    if (appt == null) return;
    if (!force && _pendingShownForAppointmentId == appt.id) return;

    final ctx = appNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    _pendingShownForAppointmentId = appt.id;
    await Navigator.of(ctx).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ConsultationClosurePage(appointment: appt),
      ),
    );
    _pendingShownForAppointmentId = null;
  }

  static Future<bool?> openFor(Appointment appointment) async {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return false;
    return Navigator.of(ctx).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ConsultationClosurePage(appointment: appointment),
      ),
    );
  }
}
