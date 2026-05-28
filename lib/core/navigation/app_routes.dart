import 'package:flutter/material.dart';
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
  static const String dashboard = '/dashboard';
  static const String schedule = '/schedule';
  static const String appointments = '/appointments';
  static const String tracking = '/tracking';
  static const String prescriptions = '/prescriptions';
  static const String videoCall = '/video_call';
  static const String insurance = '/insurance';
  static const String pharmacy = '/pharmacy';
  static const String medicalHistory = '/medical_history';
  static const String doctorDashboard = '/doctor_dashboard';
  static const String doctorSchedule = '/doctor_schedule';
  static const String doctorProfile = '/doctor_profile';
  static const String ambulanceDashboard = '/ambulance_dashboard';
  static const String pharmacyAdmin = '/pharmacy_admin';
  static const String adminDashboard = '/admin_dashboard';
  static const String superAdminDashboard = '/super_admin_dashboard';
  static const String clinicAdminDashboard = '/clinic_admin_dashboard';
  static const String clinicAssignDoctor = '/clinic_assign_doctor';
  static const String clinicAdminPassword = '/clinic_admin_password';
  static const String adminCreateDoctor = '/admin/create_doctor';
  static const String pharmacyOps = '/pharmacy_ops';
  static const String pharmacyAdminManage = '/pharmacy_admin_manage';
  static const String fullInventory = '/full_inventory';
  static const String ambulanceCheckout = '/ambulance_checkout';
  static const String paramedicDashboard = '/paramedic_dashboard';
  static const String labMarketplace = '/lab_marketplace';
  static const String labTechnician = '/lab_technician';
  static const String labResults = '/lab_results';
  static const String clinicReception = '/clinic_reception';
  static const String erDashboard = '/er_dashboard';
  static const String clinicNetwork = '/clinic_network';
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
      path: doctorDashboard,
      label: 'Médico',
      icon: Icons.health_and_safety_rounded,
      roles: {Role.doctor},
    ),
    AppRouteDestination(
      path: doctorSchedule,
      label: 'Agenda médica',
      icon: Icons.calendar_view_week_rounded,
      roles: {Role.doctor},
    ),
    AppRouteDestination(
      path: ambulanceDashboard,
      label: 'Conductor',
      icon: Icons.emergency_rounded,
      roles: {Role.driver},
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
      label: 'Laboratorio',
      icon: Icons.biotech_rounded,
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
      label: 'Admin clínica',
      icon: Icons.local_hospital_rounded,
      roles: {Role.clinicAdmin},
    ),
    AppRouteDestination(
      path: pharmacyOps,
      label: 'Farmacia',
      icon: Icons.local_pharmacy_rounded,
      roles: {Role.pharmacyAdmin, Role.pharmacist, Role.pharmacyCashier},
    ),
  ];

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
        patientProfile,
        schedule,
        appointments,
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
    final roleDestinations = destinationsForRole(role);
    if (role == Role.patient) {
      return const [
        AppRouteDestination(
          path: dashboard,
          label: 'Inicio',
          icon: Icons.home_rounded,
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
          label: 'Emergencia',
          icon: Icons.emergency_rounded,
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
    return roleDestinations.take(5).toList(growable: false);
  }

  /// Rutas que no aparecen en el menú lateral pero sí están permitidas por rol.
  static const Map<String, Set<Role>> _secondaryRouteRoles = {
    adminCreateDoctor: {Role.clinicAdmin},
    clinicAssignDoctor: {Role.clinicAdmin},
    clinicAdminPassword: {Role.clinicAdmin},
    pharmacyAdminManage: {Role.pharmacyAdmin, Role.pharmacy},
    doctorSchedule: {Role.doctor},
    doctorProfile: {Role.doctor},
    clinicalHistory: {Role.patient},
    messages: {Role.patient, Role.doctor},
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
        return appointments;
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
        return 'Invitar médico existente';
      case clinicAdminPassword:
        return 'Cambiar contraseña';
      case pharmacyAdminManage:
        return 'Gestión de farmacia';
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
    schedule: (_) => const ScheduleAppointmentPage(),
    appointments: (_) => const MyAppointmentsPage(),
    tracking: (_) => const AmbulanceTracking(),
    prescriptions: (_) => const PrescriptionsPage(),
    videoCall: (_) => const VideoCallPage(),
    insurance: (_) => const InsurancePage(),
    pharmacy: (_) => const PharmacyPage(),
    medicalHistory: (_) => const MedicalHistoryPage(),
    doctorDashboard: (_) => const DoctorDashboard(),
    doctorSchedule: (_) => const DoctorSchedulePage(),
    doctorProfile: (_) => const DoctorProfilePage(),
    ambulanceDashboard: (_) => const AmbulanceDriverDashboard(),
    pharmacyAdmin: (_) => const PharmacyAdminDashboard(),
    adminDashboard: (_) => const SuperAdminDashboard(),
    superAdminDashboard: (_) => const SuperAdminDashboard(),
    clinicAdminDashboard: (_) => const ClinicAdminDashboard(),
    clinicAssignDoctor: (_) => const ClinicAssignDoctorPage(),
    clinicAdminPassword: (_) => const ClinicAdminPasswordPage(),
    adminCreateDoctor: (_) => const CreateDoctorPage(),
    pharmacyOps: (_) => const PharmacyOpsDashboard(),
    pharmacyAdminManage: (_) => const PharmacyAdminManagePage(),
    fullInventory: (_) => const FullInventoryPage(),
    ambulanceCheckout: (_) => const AmbulanceCheckoutScreen(),
    paramedicDashboard: (_) => const ParamedicTransitScreen(),
    labMarketplace: (_) => const LabMarketplaceScreen(),
    labTechnician: (_) => const LabTechnicianDashboard(),
    labResults: (_) => const PatientResultsScreen(),
    clinicReception: (_) => const ClinicReceptionScreen(),
    erDashboard: (_) => const ERIncomingDashboard(),
    clinicNetwork: (_) => const ClinicNetworkScreen(),
    insuranceWallet: (_) => const InsuranceWalletScreen(),
    clinicBilling: (_) => const ClinicBillingDashboard(),
    radiologyMarketplace: (_) => const RadiologyMarketplaceScreen(),
    erIncomingAlias: (_) => const ERIncomingDashboard(),
    ambulanceDriverAlias: (_) => const AmbulanceDriverDashboard(),
  };
}
