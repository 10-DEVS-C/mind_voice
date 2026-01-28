import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'test@test.com' && password == '123456') {
      return UserModel(id: '1', email: email);
    } else {
      throw Exception('Invalid credentials');
    }
  }

  @override
  Future<User> register(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    return UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
    );
  }
}
