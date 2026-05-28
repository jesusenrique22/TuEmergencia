import 'role.dart';

class User {
  final String id;
  final String name;
  final String email;
  final Role role;
  final String avatarUrl;
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarUrl,
    this.phone,
  });
}
