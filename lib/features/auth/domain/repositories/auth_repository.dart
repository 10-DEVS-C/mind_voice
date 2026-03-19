import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<User> register(String username, String email, String password, String name);
  Future<User> updateProfile({
    required String username,
    required String email,
    required String name,
  });
  Future<void> logout();
  Future<User?> getCurrentUser();
}
