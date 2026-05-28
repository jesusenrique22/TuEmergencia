import 'package:flutter/material.dart';
import 'dart:async';

import '../../data/mocks/user_data_mock.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();

  User? get currentUser => _currentUser;
  Stream<User?> get authChanges => _authController.stream;

  /// Simple mock login. Password must be "password".
  Future<User?> login(String email, String password) async {
    final user = UserDataMock.validate(email, password);
    if (user != null) {
      _currentUser = user;
      _authController.add(_currentUser);
      notifyListeners();
    }
    return user;
  }

  void logout() {
    _currentUser = null;
    _authController.add(null);
    notifyListeners();
  }

  @override
  void dispose() {
    _authController.close();
    super.dispose();
  }
}
