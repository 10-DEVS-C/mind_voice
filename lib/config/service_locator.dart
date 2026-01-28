import 'package:get_it/get_it.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/register_user.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/providers/settings_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth

  // Provider
  sl.registerFactory(() => AuthProvider(loginUser: sl(), registerUser: sl()));
  sl.registerLazySingleton(() => SettingsProvider());

  // Use cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

  // Data sources - In this simple example we don't have a separate datasource class yet,
  // but usually RepositoryImpl depends on RemoteDataSource.
  // For now AuthRepositoryImpl handles it.

  //! Core
  // Network info, etc.
}
