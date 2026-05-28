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
    }
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
