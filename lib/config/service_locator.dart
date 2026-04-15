import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/shared_prefs_service.dart';
import 'package:http/http.dart' as http;
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/register_user.dart';
import '../features/auth/domain/usecases/logout_user.dart';
import '../features/auth/domain/usecases/get_current_user.dart';
import '../features/auth/domain/usecases/update_profile.dart';
import '../features/auth/domain/usecases/change_plan.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/audio_recorder/data/repositories/audio_recorder_repository_impl.dart';
import '../features/audio_recorder/domain/repositories/audio_recorder_repository.dart';
import '../features/audio_recorder/domain/usecases/audio_usecases.dart';
import '../features/audio_recorder/presentation/providers/audio_recorder_provider.dart';
import '../core/providers/settings_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth

  // Provider
  sl.registerFactory(
    () => AuthProvider(
      loginUser: sl(),
      registerUser: sl(),
      logoutUser: sl(),
      getCurrentUser: sl(),
      updateProfileUseCase: sl(),
      changePlanUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => SettingsProvider());

  // Use cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => ChangePlan(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), sharedPrefsService: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetRecordingsUseCase(sl()));
  sl.registerLazySingleton(() => SaveRecordingUseCase(sl()));
  sl.registerLazySingleton(() => DeleteRecordingUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRecordingUseCase(sl()));

  // Feature - Audio Recorder
  // Provider
  sl.registerFactory(
    () => AudioRecorderProvider(
      getRecordingsUseCase: sl(),
      saveRecordingUseCase: sl(),
      deleteRecordingUseCase: sl(),
      updateRecordingUseCase: sl(),
      sharedPrefsService: sl(),
      httpClient: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AudioRecorderRepository>(
    () => AudioRecorderRepositoryImpl(sl()),
  );

  //! Core
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => SharedPrefsService(sharedPrefs));
  sl.registerLazySingleton(() => http.Client());
}
