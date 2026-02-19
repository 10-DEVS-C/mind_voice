import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/shared_prefs_service.dart';
import 'package:http/http.dart' as http;
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
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), sharedPrefsService: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );

  //! Core
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => SharedPrefsService(sharedPrefs));
  sl.registerLazySingleton(() => http.Client());
}
