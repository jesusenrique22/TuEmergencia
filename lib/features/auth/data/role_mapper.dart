import '../domain/models/role.dart';

class RoleMapper {
  static Role fromApi(String apiRole) {
    switch (apiRole.toUpperCase()) {
      case 'PATIENT':
        return Role.patient;
      case 'DOCTOR':
        return Role.doctor;
      case 'SUPER_ADMIN':
      case 'ADMIN':
        return Role.superAdmin;
      case 'CLINIC_ADMIN':
        return Role.clinicAdmin;
      case 'PHARMACY_ADMIN':
        return Role.pharmacyAdmin;
      case 'PHARMACIST':
        return Role.pharmacist;
      case 'PHARMACY_CASHIER':
        return Role.pharmacyCashier;
      default:
        return Role.patient;
    }
  }

  static String toApi(Role role) {
    switch (role) {
      case Role.patient:
        return 'PATIENT';
      case Role.doctor:
        return 'DOCTOR';
      case Role.superAdmin:
      case Role.admin:
        return 'SUPER_ADMIN';
      case Role.clinicAdmin:
        return 'CLINIC_ADMIN';
      case Role.pharmacyAdmin:
        return 'PHARMACY_ADMIN';
      case Role.pharmacist:
        return 'PHARMACIST';
      case Role.pharmacyCashier:
        return 'PHARMACY_CASHIER';
      default:
        throw ArgumentError('Rol no soportado en el API: $role');
    }
  }

  static bool supportsApiLogin(Role role) {
    return role == Role.patient ||
        role == Role.doctor ||
        role == Role.superAdmin ||
        role == Role.admin ||
        role == Role.clinicAdmin ||
        role == Role.pharmacyAdmin ||
        role == Role.pharmacist ||
        role == Role.pharmacyCashier;
  }
}
