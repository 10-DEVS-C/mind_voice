import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/shared_prefs_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPrefsService sharedPrefsService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPrefsService,
  });

  @override
  Future<User> login(String email, String password) async {
    try {
      final user = await remoteDataSource.login(email, password);
      if (user.token != null) {
        await sharedPrefsService.saveToken(user.token!);
      }
      return user;
    } on ServerException catch (e) {
      throw Exception(
        e.message,
      ); // Re-throwing as generic Exception for now to match UI expectation of e.toString()
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<User> register(String email, String password) async {
    try {
      return await remoteDataSource.register(email, password);
    } on ServerException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
