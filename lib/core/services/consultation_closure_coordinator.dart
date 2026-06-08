import 'package:flutter/material.dart';

import '../../features/appointments/data/appointment_api_service.dart';
import '../../features/appointments/domain/models/appointment.dart';
import '../../features/appointments/presentation/pages/consultation_closure_page.dart';
import '../../main.dart';
import '../auth/app_session.dart';
import '../../features/auth/domain/models/role.dart';

/// Navega al formulario de cierre cuando el médico lo elige (no se abre solo).
class ConsultationClosureCoordinator {
  static void resetSession() {}

  static List<Appointment> listPending(List<Appointment> appointments) {
    if (AppSession.activeRole != Role.doctor) return const [];
    final pending = appointments.where((a) => a.needsClosure).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return pending;
  }

  static Appointment? findNextPending(List<Appointment> appointments) {
    final pending = listPending(appointments);
    return pending.isEmpty ? null : pending.first;
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

  static Future<bool?> openForId(String appointmentId) async {
    try {
      final list = await AppointmentApiService().getDoctorAppointments();
      final appt = list.cast<Appointment?>().firstWhere(
            (a) => a?.id == appointmentId,
            orElse: () => null,
          );
      if (appt == null) return false;
      return openFor(appt);
    } catch (_) {
      return false;
    }
  }
}
