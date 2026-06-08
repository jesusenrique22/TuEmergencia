import 'package:flutter/material.dart';

import '../../core/debug/gateway_debug_page.dart';
import '../../features/pages.dart';
import '../../features/auth/domain/models/role.dart';

class AppRouteDestination {
  final String path;
  final String label;
  final IconData icon;
  final Set<Role> roles;

  const AppRouteDestination({
    required this.path,
    required this.label,
    required this.icon,
    this.roles = const {Role.patient},
  });
}

/// Centralized route definitions
class AppRoutes {
  static const String login = '/login';
  static const String patientProfile = '/patient_profile';
  static const String clinicalHistory = '/clinical_history';
  static const String messages = '/messages';
  static const String gatewayDebug = '/debug/gateway';
  static const String dashboard = '/dashboard';
  static const String schedule = '/schedule';
  static const String appointments = '/appointments';
  static const String tracking = '/tracking';
  static const String prescriptions = '/prescriptions';
  static const String videoCall = '/video_call';
  static const String insurance = '/insurance';
  static const String pharmacy = '/pharmacy';
  static const String medicalHistory = '/medical_history';
  static const String patientShareExams = '/patient_share_exams';
  static const String doctorDashboard = '/doctor_dashboard';
  static const String doctorSchedule = '/doctor_schedule';
  static const String doctorProfile = '/doctor_profile';
  static const String ambulanceDashboard = '/ambulance_dashboard';
  static const String ambulanceEmergencyDetail = '/ambulance_emergency_detail';
  static const String ambulanceCrewProfile = '/ambulance_crew_profile';
  static const String pharmacyAdmin = '/pharmacy_admin';
  static const String adminDashboard = '/admin_dashboard';
  static const String superAdminDashboard = '/super_admin_dashboard';
  static const String clinicAdminDashboard = '/clinic_admin_dashboard';
  static const String clinicAssignDoctor = '/clinic_assign_doctor';
  static const String clinicAmbulanceFleet = '/clinic_ambulance_fleet';
  static const String clinicAdminPassword = '/clinic_admin_password';
  static const String adminCreateDoctor = '/admin/create_doctor';
  static const String pharmacyOps = '/pharmacy_ops';
  static const String pharmacyAdminManage = '/pharmacy_admin_manage';
  static const String fullInventory = '/full_inventory';
  static const String ambulanceCheckout = '/ambulance_checkout';
  static const String paramedicDashboard = '/paramedic_dashboard';
  static const String labMarketplace = '/lab_marketplace';
  static const String labTechnician = '/lab_technician';
  static const String labExamsCatalog = '/lab_exams_catalog';
  static const String labRegisterExam = '/lab_register_exam';
  static const String labResults = '/lab_results';
  static const String clinicReception = '/clinic_reception';
  static const String erDashboard = '/er_dashboard';
  static const String clinicNetwork = '/clinic_network';
  static const String medicalNetworkMap = '/medical_network_map';
  static const String insuranceWallet = '/insurance_wallet';
  static const String clinicBilling = '/clinic_billing';
  static const String radiologyMarketplace = '/radiology_marketplace';

  // Backwards-compatible aliases used by older mock notifications.
  static const String erIncomingAlias = '/er_incoming';
  static const String ambulanceDriverAlias = '/ambulance_driver';

  static const List<AppRouteDestination> destinations = [
    AppRouteDestination(
      path: dashboard,
      label: 'Inicio',
      icon: Icons.home_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: patientProfile,
      label: 'Perfil',
      icon: Icons.assignment_ind_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: schedule,
      label: 'Agendar',
      icon: Icons.calendar_month_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: appointments,
      label: 'Citas',
      icon: Icons.event_note_rounded,
      roles: {Role.patient, Role.doctor},
    ),
    AppRouteDestination(
      path: ambulanceCheckout,
      label: 'Ambulancia',
      icon: Icons.local_shipping_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: pharmacy,
      label: 'Farmacias',
      icon: Icons.local_pharmacy_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: prescriptions,
      label: 'Recetas',
      icon: Icons.receipt_long_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: labMarketplace,
      label: 'Laboratorios',
      icon: Icons.science_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: labResults,
      label: 'Resultados',
      icon: Icons.assignment_turned_in_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: clinicNetwork,
      label: 'Clínicas',
      icon: Icons.business_rounded,
      roles: {Role.patient, Role.clinicStaff},
    ),
    AppRouteDestination(
      path: insuranceWallet,
      label: 'Seguros',
      icon: Icons.shield_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: radiologyMarketplace,
      label: 'Radiología',
      icon: Icons.image_search_rounded,
      roles: {Role.patient, Role.radiologyTech},
    ),
    AppRouteDestination(
      path: medicalHistory,
      label: 'Historial',
      icon: Icons.history_edu_rounded,
      roles: {Role.patient, Role.doctor},
    ),
    AppRouteDestination(
      path: patientShareExams,
      label: 'Exámenes',
      icon: Icons.upload_file_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: messages,
      label: 'Mensajes',
      icon: Icons.chat_rounded,
      roles: {Role.patient, Role.doctor},
    ),
    AppRouteDestination(
      path: doctorDashboard,
      label: 'Inicio',
      icon: Icons.home_rounded,
      roles: {Role.doctor},
    ),
    AppRouteDestination(
      path: doctorSchedule,
      label: 'Agenda',
      icon: Icons.calendar_view_week_rounded,
      roles: {Role.doctor},
    ),
    AppRouteDestination(
      path: doctorProfile,
      label: 'Perfil',
      icon: Icons.person_rounded,
      roles: {Role.doctor},
    ),
    AppRouteDestination(
      path: ambulanceDashboard,
      label: 'Emergencias',
      icon: Icons.emergency_rounded,
      roles: {Role.driver, Role.paramedic, Role.ambulanceNurse},
    ),
    AppRouteDestination(
      path: ambulanceCrewProfile,
      label: 'Perfil',
      icon: Icons.person_rounded,
      roles: {Role.driver, Role.paramedic, Role.ambulanceNurse},
    ),
    AppRouteDestination(
      path: paramedicDashboard,
      label: 'Traslado',
      icon: Icons.airport_shuttle_rounded,
      roles: {Role.driver},
    ),
    AppRouteDestination(
      path: pharmacyAdmin,
      label: 'Farmacia Admin',
      icon: Icons.inventory_2_rounded,
      roles: {Role.pharmacy},
    ),
    AppRouteDestination(
      path: fullInventory,
      label: 'Inventario',
      icon: Icons.warehouse_rounded,
      roles: {Role.pharmacy},
    ),
    AppRouteDestination(
      path: labTechnician,
      label: 'Inicio',
      icon: Icons.home_rounded,
      roles: {Role.labTech},
    ),
    AppRouteDestination(
      path: labExamsCatalog,
      label: 'Exámenes',
      icon: Icons.science_rounded,
      roles: {Role.labTech},
    ),
    AppRouteDestination(
      path: clinicReception,
      label: 'Recepción',
      icon: Icons.local_hospital_rounded,
      roles: {Role.clinicStaff},
    ),
    AppRouteDestination(
      path: erDashboard,
      label: 'Emergencias ER',
      icon: Icons.emergency_share_rounded,
      roles: {Role.clinicStaff},
    ),
    AppRouteDestination(
      path: clinicBilling,
      label: 'Facturación',
      icon: Icons.request_quote_rounded,
      roles: {Role.clinicStaff},
    ),
    AppRouteDestination(
      path: superAdminDashboard,
      label: 'Admin global',
      icon: Icons.admin_panel_settings_rounded,
      roles: {Role.superAdmin, Role.admin},
    ),
    AppRouteDestination(
      path: clinicAdminDashboard,
      label: 'Inicio',
      icon: Icons.local_hospital_rounded,
      roles: {Role.clinicAdmin},
    ),
    AppRouteDestination(
      path: adminCreateDoctor,
      label: 'Crear médico',
      icon: Icons.person_add_alt_1_rounded,
      roles: {Role.clinicAdmin, Role.superAdmin, Role.admin},
    ),
    AppRouteDestination(
      path: clinicAdminPassword,
      label: 'Cuenta',
      icon: Icons.manage_accounts_rounded,
      roles: {Role.clinicAdmin},
    ),
    AppRouteDestination(
      path: pharmacyOps,
      label: 'Farmacia',
      icon: Icons.local_pharmacy_rounded,
      roles: {Role.pharmacyAdmin, Role.pharmacist, Role.pharmacyCashier},
    ),
    AppRouteDestination(
      path: pharmacyAdminManage,
      label: 'Gestión',
      icon: Icons.settings_rounded,
      roles: {Role.pharmacyAdmin, Role.pharmacy},
    ),
  ];

  static List<AppRouteDestination> _destinationsForPaths(List<String> paths) {
    return paths
        .map(
          (path) => destinations.firstWhere(
            (destination) => destination.path == path,
          ),
        )
        .toList(growable: false);
  }

  static const List<AppRouteDestination> mobileDestinations = [
    AppRouteDestination(
      path: dashboard,
      label: 'Inicio',
      icon: Icons.home_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: schedule,
      label: 'Agendar',
      icon: Icons.calendar_month_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: appointments,
      label: 'Citas',
      icon: Icons.event_note_rounded,
      roles: {Role.patient, Role.doctor},
    ),
    AppRouteDestination(
      path: ambulanceCheckout,
      label: 'Ambulancia',
      icon: Icons.local_shipping_rounded,
      roles: {Role.patient},
    ),
    AppRouteDestination(
      path: pharmacy,
      label: 'Farmacia',
      icon: Icons.local_pharmacy_rounded,
      roles: {Role.patient},
    ),
  ];

  static List<AppRouteDestination> destinationsForRole(Role role) {
    if (role == Role.admin) return destinations;
    final roleDestinations = destinations
        .where((destination) => destination.roles.contains(role))
        .toList(growable: false);

    if (role == Role.patient) {
      const essentialPatientRoutes = [
        dashboard,
        messages,
        schedule,
        appointments,
        patientShareExams,
        patientProfile,
        ambulanceCheckout,
        medicalHistory,
      ];

      return essentialPatientRoutes
          .map(
            (route) => roleDestinations.firstWhere(
              (destination) => destination.path == route,
            ),
          )
          .toList(growable: false);
    }

    return roleDestinations;
  }

  static List<AppRouteDestination> mobileDestinationsForRole(Role role) {
    if (role == Role.patient) {
      return const [
        AppRouteDestination(
          path: dashboard,
          label: 'Inicio',
          icon: Icons.home_rounded,
          roles: {Role.patient},
        ),
        AppRouteDestination(
          path: messages,
          label: 'Mensajes',
          icon: Icons.chat_rounded,
          roles: {Role.patient, Role.doctor},
        ),
        AppRouteDestination(
          path: appointments,
          label: 'Citas',
          icon: Icons.event_note_rounded,
          roles: {Role.patient, Role.doctor},
        ),
        AppRouteDestination(
          path: patientShareExams,
          label: 'Exámenes',
          icon: Icons.upload_file_rounded,
          roles: {Role.patient},
        ),
        AppRouteDestination(
          path: patientProfile,
          label: 'Perfil',
          icon: Icons.assignment_ind_rounded,
          roles: {Role.patient},
        ),
      ];
    }
    if (role == Role.clinicAdmin) {
      return _destinationsForPaths([
        clinicAdminDashboard,
        adminCreateDoctor,
        clinicAdminPassword,
      ]);
    }
    if (role == Role.doctor) {
      return _destinationsForPaths([
        doctorDashboard,
        messages,
        appointments,
        doctorProfile,
      ]);
    }
    if (role == Role.pharmacyAdmin ||
        role == Role.pharmacist ||
        role == Role.pharmacyCashier) {
      return _destinationsForPaths([pharmacyOps, pharmacyAdminManage]);
    }
    if (role == Role.driver) {
      return _destinationsForPaths([
        ambulanceDashboard,
        ambulanceCrewProfile,
      ]);
    }
    if (role == Role.paramedic || role == Role.ambulanceNurse) {
      return _destinationsForPaths([
        ambulanceDashboard,
        ambulanceCrewProfile,
      ]);
    }
    if (role == Role.clinicStaff) {
      return _destinationsForPaths([
        clinicReception,
        erDashboard,
        clinicBilling,
      ]);
    }
    if (role == Role.labTech) {
      return _destinationsForPaths([labTechnician, labExamsCatalog]);
    }

    final roleDestinations = destinationsForRole(role);
    return roleDestinations.length >= 2
        ? roleDestinations.take(5).toList(growable: false)
        : roleDestinations;
  }

  /// Rutas que no aparecen en el menú lateral pero sí están permitidas por rol.
  static const Map<String, Set<Role>> _secondaryRouteRoles = {
    adminCreateDoctor: {Role.clinicAdmin},
    clinicAssignDoctor: {Role.clinicAdmin},
    clinicAdminPassword: {Role.clinicAdmin},
    clinicAmbulanceFleet: {Role.clinicAdmin},
    ambulanceEmergencyDetail: {
      Role.driver,
      Role.paramedic,
      Role.ambulanceNurse,
    },
    pharmacyAdminManage: {Role.pharmacyAdmin, Role.pharmacy},
    doctorSchedule: {Role.doctor},
    doctorProfile: {Role.doctor},
    clinicalHistory: {Role.patient},
    messages: {Role.patient, Role.doctor},
    videoCall: {Role.patient, Role.doctor},
    labRegisterExam: {Role.labTech},
  };

  static bool isAllowedForRole(String? route, Role role) {
    if (role == Role.superAdmin || role == Role.admin) return true;
    final normalizedRoute = normalize(route);
    final secondary = _secondaryRouteRoles[normalizedRoute];
    if (secondary != null && secondary.contains(role)) return true;
    return destinations.any(
      (destination) =>
          destination.path == normalizedRoute &&
          destination.roles.contains(role),
    );
  }

  static String normalize(String? route) {
    switch (route) {
      case erIncomingAlias:
        return erDashboard;
      case ambulanceDriverAlias:
        return ambulanceDashboard;
      case tracking:
        return ambulanceCheckout;
      case videoCall:
        return videoCall;
      case insurance:
        return insuranceWallet;
      case '/':
      case null:
        return dashboard;
      default:
        return route;
    }
  }

  static AppRouteDestination? destinationFor(String? route) {
    final normalizedRoute = normalize(route);
    for (final destination in destinations) {
      if (destination.path == normalizedRoute) return destination;
    }
    return null;
  }

  static String titleFor(String? route) {
    final normalized = normalize(route);
    switch (normalized) {
      case adminCreateDoctor:
        return 'Registrar médico';
      case clinicAssignDoctor:
        return 'Gestionar médicos';
      case clinicAdminPassword:
        return 'Cambiar contraseña';
      case clinicAmbulanceFleet:
        return 'Movilización sanitaria';
      case pharmacyAdminManage:
        return 'Gestión de farmacia';
      case labExamsCatalog:
        return 'Catálogo de exámenes';
      case labRegisterExam:
        return 'Registrar examen';
      case patientShareExams:
        return 'Compartir exámenes';
      default:
        return destinationFor(route)?.label ?? 'VITA OS';
    }
  }

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginPage(),
    dashboard: (_) => const PatientDashboard(),
    patientProfile: (_) => const PatientProfilePage(),
    clinicalHistory: (_) => const ClinicalHistoryFormPage(),
    messages: (_) => const MessagesPage(),
    gatewayDebug: (_) => const GatewayDebugPage(),
    schedule: (_) => const ScheduleAppointmentPage(),
    appointments: (_) => const MyAppointmentsPage(),
    tracking: (context) {
      final raw = ModalRoute.of(context)?.settings.arguments;
      final Map<String, dynamic>? args = raw is Map<String, dynamic>
          ? raw
          : raw is Map
              ? Map<String, dynamic>.from(raw)
              : null;
      final emergencyId = args?['emergencyId']?.toString() ?? '';
      return AmbulanceTracking(emergencyId: emergencyId);
    },
    prescriptions: (_) => const PrescriptionsPage(),
    videoCall: (context) {
      final raw = ModalRoute.of(context)?.settings.arguments;
      final Map<String, dynamic>? args = raw is Map<String, dynamic>
          ? raw
          : raw is Map
              ? Map<String, dynamic>.from(raw)
              : null;
      return WebRtcCallPage(initialArgs: args);
    },
    insurance: (_) => const InsurancePage(),
    pharmacy: (_) => const PharmacyPage(),
    medicalHistory: (_) => const MedicalHistoryPage(),
    patientShareExams: (_) => const PatientShareExamsPage(),
    doctorDashboard: (_) => const DoctorDashboard(),
    doctorSchedule: (_) => const DoctorSchedulePage(),
    doctorProfile: (_) => const DoctorProfilePage(),
    ambulanceDashboard: (_) => const AmbulanceCrewDashboard(),
    pharmacyAdmin: (_) => const PharmacyAdminDashboard(),
    adminDashboard: (_) => const SuperAdminDashboard(),
    superAdminDashboard: (_) => const SuperAdminDashboard(),
    clinicAdminDashboard: (_) => const ClinicAdminDashboard(),
    clinicAssignDoctor: (_) => const ClinicAssignDoctorPage(),
    clinicAmbulanceFleet: (_) => const ClinicAmbulanceFleetPage(),
    clinicAdminPassword: (_) => const ClinicAdminPasswordPage(),
    adminCreateDoctor: (_) => const CreateDoctorPage(),
    pharmacyOps: (_) => const PharmacyOpsDashboard(),
    pharmacyAdminManage: (_) => const PharmacyAdminManagePage(),
    fullInventory: (_) => const FullInventoryPage(),
    ambulanceCheckout: (_) => const AmbulanceCheckoutScreen(),
    paramedicDashboard: (_) => const AmbulanceCrewDashboard(),
    ambulanceEmergencyDetail: (context) {
      final raw = ModalRoute.of(context)?.settings.arguments;
      final Map<String, dynamic>? args = raw is Map<String, dynamic>
          ? raw
          : raw is Map
              ? Map<String, dynamic>.from(raw)
              : null;
      final emergencyId = args?['emergencyId']?.toString() ?? '';
      return AmbulanceEmergencyDetailScreen(emergencyId: emergencyId);
    },
    ambulanceCrewProfile: (_) => const AmbulanceCrewProfilePage(),
    labMarketplace: (_) => const LabMarketplaceScreen(),
    labTechnician: (_) => const LabTechnicianDashboard(),
    labExamsCatalog: (_) => const LabExamsCatalogPage(),
    labRegisterExam: (_) => const LabRegisterExamPage(),
    labResults: (_) => const PatientResultsScreen(),
    clinicReception: (_) => const ClinicReceptionScreen(),
    erDashboard: (_) => const ERIncomingDashboard(),
    clinicNetwork: (_) => const ClinicNetworkScreen(),
    medicalNetworkMap: (_) => const MedicalNetworkMapScreen(),
    insuranceWallet: (_) => const InsuranceWalletScreen(),
    clinicBilling: (_) => const ClinicBillingDashboard(),
    radiologyMarketplace: (_) => const RadiologyMarketplaceScreen(),
    erIncomingAlias: (_) => const ERIncomingDashboard(),
    ambulanceDriverAlias: (_) => const AmbulanceCrewDashboard(),
  };
}
