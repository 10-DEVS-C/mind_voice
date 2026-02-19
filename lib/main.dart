import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/service_locator.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/settings_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/audio_recorder/presentation/providers/audio_recorder_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
// import 'features/home/presentation/pages/home_page.dart'; // Can import this if I change the home in MaterialApp

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MindVoiceApp());
}

class MindVoiceApp extends StatelessWidget {
  const MindVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<SettingsProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<AudioRecorderProvider>()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Mind Voice',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: const [Locale('en', ''), Locale('es', '')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home:
                const LoginPage(), // Currently set to LoginPage, user might navigate to HomePage after login.
          );
        },
      ),
    );
  }
}
