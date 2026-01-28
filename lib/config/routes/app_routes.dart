import 'package:flutter/material.dart';
import 'package:mind_voice/features/audio_recorder/presentation/pages/audio_recorder_page.dart';

class AppRoutes {
  static const String initial = '/';
  static const String audioRecorder = '/audio_recorder';
  static const String login = '/login';
  static const String home = '/home';
  static const String details = '/details';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      initial: (context) => const AudioRecorderPage(),
      audioRecorder: (context) => const AudioRecorderPage(),
      // login: (context) => const LoginPage(), // Commented out missing pages
      // home: (context) => const HomePage(),
    };
  }
}
