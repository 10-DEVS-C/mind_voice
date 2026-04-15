import '../repositories/auth_repository.dart';

class ChangePlan {
  final AuthRepository repository;

  ChangePlan(this.repository);

  Future<String> call(String planKey) {
    return repository.changePlan(planKey);
  }
}
