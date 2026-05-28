import '../../auth/domain/models/user.dart';
import '../domain/models/patient_profile.dart';
import 'patient_api_service.dart';

class PatientProfileRepository {
  static PatientProfile? _activeProfile;

  static PatientProfile? get activeProfile => _activeProfile;

  static void save(PatientProfile profile) {
    _activeProfile = profile;
  }

  static void applyFromUser(User user) {
    _activeProfile = PatientProfile.fromUser(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
    );
  }

  static void applyFromJson(Map<String, dynamic> json) {
    _activeProfile = PatientProfile.fromJson(json);
  }

  static Future<void> refreshFromApi() async {
    try {
      final json = await PatientApiService().getProfile();
      applyFromJson(json);
    } catch (_) {
      // Perfil aún no creado en servidor o sin conexión.
    }
  }

  static void clear() {
    _activeProfile = null;
  }
}
