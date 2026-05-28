import '../../../../core/network/api_client.dart';
import '../domain/models/user.dart';
import 'role_mapper.dart';

class AuthResponse {
  final User user;
  final String token;

  const AuthResponse({required this.user, required this.token});
}

class AuthApiService {
  final ApiClient _client = ApiClient();

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    return _parseAuthResponse(data);
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String roleApi,
    String? phone,
  }) async {
    final data = await _client.post('/api/auth/register', {
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      'role': roleApi,
      if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
    });
    return _parseAuthResponse(data);
  }

  AuthResponse _parseAuthResponse(Map<String, dynamic> data) {
    final userJson = data['user'] as Map<String, dynamic>;
    final token = data['token'] as String;
    return AuthResponse(user: _userFromJson(userJson), token: token);
  }

  User _userFromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['_id']?.toString() ?? '';
    final roleStr = json['role'] as String? ?? 'PATIENT';
    return User(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: RoleMapper.fromApi(roleStr),
      avatarUrl: json['profilePic'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}
