import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/shared_prefs_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPrefsService sharedPrefsService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPrefsService,
  });

  @override
  Future<User> login(String username, String password) async {
    try {
      final user = await remoteDataSource.login(username, password);
      if (user.token != null) {
        await sharedPrefsService.saveToken(user.token!);
      }
      await sharedPrefsService.saveUserData(
        id: user.id,
        email: user.email,
        username: user.username,
        name: user.name,
        plan: user.plan,
      );
      return user;
    } on ServerException catch (e) {
      throw Exception(
        e.message,
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<User> register(String username, String email, String password, String name) async {
    try {
      final user = await remoteDataSource.register(username, email, password, name);
      if (user.token != null) {
        await sharedPrefsService.saveToken(user.token!);
      }
      await sharedPrefsService.saveUserData(
        id: user.id,
        email: user.email,
        username: user.username,
        name: user.name,
        plan: user.plan,
      );
      return user;
    } on ServerException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<User> updateProfile({
    required String username,
    required String email,
    required String name,
  }) async {
    final token = sharedPrefsService.getToken();
    final userData = sharedPrefsService.getUserData();
    final userId = userData['id'];
    final currentPlan = userData['plan'] ?? 'basic';

    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      throw Exception('Sesion invalida');
    }

    final updated = await remoteDataSource.updateProfile(
      token: token,
      userId: userId,
      username: username,
      email: email,
      name: name,
      plan: currentPlan,
    );

    await sharedPrefsService.saveUserData(
      id: updated.id,
      email: updated.email,
      username: updated.username,
      name: updated.name,
      plan: updated.plan,
    );

    return updated;
  }

  @override
  Future<void> logout() async {
    await sharedPrefsService.removeToken();
    await sharedPrefsService.clearUserData();
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = sharedPrefsService.getToken();
    if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
      final local = sharedPrefsService.getUserData();
      final decodedToken = JwtDecoder.decode(token);
      final role = (decodedToken['role'] ?? local['plan'] ?? 'basic')
          .toString()
          .toLowerCase();
      final mappedPlan = role == 'admin' || role == 'premium' || role == 'pro'
          ? 'premium'
          : 'basic';

      return User(
        id:
            local['id'] ??
            decodedToken['sub'] ??
            decodedToken['id'] ??
            'unknown_id',
        email:
            local['email'] ??
            decodedToken['email'] ??
            decodedToken['username'] ??
            '',
        username: local['username'] ?? decodedToken['username'] ?? '',
        name: local['name'] ?? decodedToken['name'] ?? '',
        plan: local['plan'] ?? mappedPlan,
      );
    }
    return null;
  }
}
