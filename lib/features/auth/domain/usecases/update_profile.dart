import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfile {
  final AuthRepository repository;

  UpdateProfile(this.repository);

  Future<User> call({
    required String username,
    required String email,
    required String name,
  }) async {
    return await repository.updateProfile(
      username: username,
      email: email,
      name: name,
    );
  }
}