import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;

  RegisterUser(this.repository);

  Future<User> call(String username, String email, String password, String name) async {
    return await repository.register(username, email, password, name);
  }
}
