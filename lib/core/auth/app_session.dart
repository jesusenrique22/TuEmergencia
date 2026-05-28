import '../../features/auth/domain/models/role.dart';
import '../../features/auth/domain/models/user.dart';
import '../../features/patient_profile/data/patient_profile_repository.dart';
import 'session_storage.dart';

class AppSession {
  static Role activeRole = Role.patient;
  static User? currentUser;
  static String? token;

  static bool get isLoggedIn => token != null && currentUser != null;

  static void setSession({required User user, required String tokenValue}) {
    currentUser = user;
    token = tokenValue;
    activeRole = user.role;
    if (user.role == Role.patient) {
      PatientProfileRepository.applyFromUser(user);
    }
    SessionStorage.save(user: user, token: tokenValue);
  }

  static Future<bool> restore() async {
    final saved = await SessionStorage.load();
    if (saved == null) {
      clear(localOnly: true);
      return false;
    }
    currentUser = saved.user;
    token = saved.token;
    activeRole = saved.user.role;
    if (saved.user.role == Role.patient) {
      PatientProfileRepository.applyFromUser(saved.user);
    }
    return true;
  }

  static void setRole(Role role) {
    activeRole = role;
  }

  static void clear({bool localOnly = false}) {
    currentUser = null;
    token = null;
    activeRole = Role.patient;
    PatientProfileRepository.clear();
    if (!localOnly) {
      SessionStorage.clear();
    }
  }
}
