import 'package:flutter/material.dart';

import '../auth/app_session.dart';
import '../../features/auth/domain/models/role.dart';
import 'app_routes.dart';

class AppNavigation {
  const AppNavigation._();

  static String homeRouteForRole(Role role) {
    switch (role) {
      case Role.patient:
        return AppRoutes.dashboard;
      case Role.doctor:
        return AppRoutes.doctorDashboard;
      case Role.superAdmin:
      case Role.admin:
        return AppRoutes.superAdminDashboard;
      case Role.clinicAdmin:
        return AppRoutes.clinicAdminDashboard;
      case Role.pharmacyAdmin:
      case Role.pharmacist:
      case Role.pharmacyCashier:
        return AppRoutes.pharmacyOps;
      case Role.pharmacy:
        return AppRoutes.pharmacyAdminManage;
      case Role.clinicStaff:
        return AppRoutes.clinicReception;
      case Role.labTech:
        return AppRoutes.labTechnician;
      case Role.radiologyTech:
        return AppRoutes.radiologyMarketplace;
      case Role.driver:
        return AppRoutes.ambulanceDashboard;
      case Role.paramedic:
      case Role.ambulanceNurse:
        return AppRoutes.ambulanceDashboard;
    }
  }

  /// Las videollamadas requieren una conversación activa (Mensajes).
  static void openTelemedicineViaMessages(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Abre Mensajes, elige un chat con tu médico o paciente y usa el botón de llamada.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
    Navigator.pushNamed(context, AppRoutes.messages);
  }

  static void safeBack(BuildContext context, {String? fallbackRoute}) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(
      fallbackRoute ?? homeRouteForRole(AppSession.activeRole),
    );
  }
}
