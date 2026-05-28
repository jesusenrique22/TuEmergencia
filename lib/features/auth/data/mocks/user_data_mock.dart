import '../../domain/models/role.dart';
import '../../domain/models/user.dart';

class UserDataMock {
  static final List<User> users = [
    User(
      id: 'u-pat-001',
      name: 'Juan Pérez',
      email: 'juan@patient.com',
      role: Role.patient,
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
    ),
    User(
      id: 'u-doc-001',
      name: 'Dra. María Gómez',
      email: 'maria@doctor.com',
      role: Role.doctor,
      avatarUrl: 'https://i.pravatar.cc/150?img=2',
    ),
    User(
      id: 'u-admin-001',
      name: 'Admin VITA',
      email: 'admin@vita.com',
      role: Role.superAdmin,
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
    ),
    User(
      id: 'u-pharm-001',
      name: 'Farmacia Central',
      email: 'pharmacy@vita.com',
      role: Role.pharmacy,
      avatarUrl: 'https://i.pravatar.cc/150?img=8',
    ),
    User(
      id: 'u-clinic-001',
      name: 'Clínica Méndez',
      email: 'clinic@med.com',
      role: Role.clinicStaff,
      avatarUrl: 'https://i.pravatar.cc/150?img=4',
    ),
    User(
      id: 'u-lab-001',
      name: 'Lab Tech',
      email: 'lab@tech.com',
      role: Role.labTech,
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
    ),
    User(
      id: 'u-rad-001',
      name: 'Radiology Tech',
      email: 'rad@tech.com',
      role: Role.radiologyTech,
      avatarUrl: 'https://i.pravatar.cc/150?img=6',
    ),
    User(
      id: 'u-driver-001',
      name: 'Conductor Ambulancia',
      email: 'driver@ambulance.com',
      role: Role.driver,
      avatarUrl: 'https://i.pravatar.cc/150?img=7',
    ),
  ];

  /// Simple mock validation: password is always "password"
  static User? validate(String email, String password) {
    if (password != 'password') return null;
    try {
      return users.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }
}
