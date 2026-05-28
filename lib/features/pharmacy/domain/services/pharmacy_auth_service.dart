import '../../domain/models/pharmacy.dart';
import '../../domain/models/pharmacy_employee.dart';
import '../../domain/models/pharmacy_data_mock.dart';

class PharmacyAuthService {
  static final PharmacyAuthService _instance = PharmacyAuthService._internal();
  factory PharmacyAuthService() => _instance;
  PharmacyAuthService._internal();

  PharmacyEmployee? _currentEmployee;
  Pharmacy? _currentPharmacy;

  PharmacyEmployee? get currentEmployee => _currentEmployee;
  Pharmacy? get currentPharmacy => _currentPharmacy;

  // Simulación de login: buscamos un empleado por ID en nuestros mocks
  void login(String employeeId) {
    _currentEmployee = PharmacyDataMock.employees.firstWhere(
      (emp) => emp.id == employeeId,
    );

    _currentPharmacy = PharmacyDataMock.pharmacies.firstWhere(
      (ph) => ph.id == _currentEmployee?.pharmacyId,
    );
  }

  void logout() {
    _currentEmployee = null;
    _currentPharmacy = null;
  }

  bool get isAdmin => _currentEmployee?.role == PharmacyRole.admin;
  bool get isInventory => _currentEmployee?.role == PharmacyRole.inventory;
  bool get isCashier => _currentEmployee?.role == PharmacyRole.cashier;
}
