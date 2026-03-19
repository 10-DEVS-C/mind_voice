import 'package:flutter/material.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/entities/user.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final LogoutUser logoutUser;
  final GetCurrentUser getCurrentUser;
  final UpdateProfile updateProfileUseCase;

  AuthProvider({
    required this.loginUser,
    required this.registerUser,
    required this.logoutUser,
    required this.getCurrentUser,
    required this.updateProfileUseCase,
  });

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _normalizeError(Object error) {
    final raw = error.toString();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length);
    }
    return raw;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await loginUser(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _normalizeError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await registerUser(username, email, password, name);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _normalizeError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String username,
    required String email,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await updateProfileUseCase(
        username: username,
        email: email,
        name: name,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _normalizeError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await logoutUser();
    _user = null;
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    try {
      final user = await getCurrentUser();
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Token might be invalid or expired
    }
    return false;
  }
}
