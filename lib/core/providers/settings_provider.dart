import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale(
    'es',
  ); // Default to Spanish as per user context usually

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  void updateThemeMode(ThemeMode? newMode) {
    if (newMode == null) return;
    if (_themeMode == newMode) return;
    _themeMode = newMode;
    notifyListeners();
  }

  void updateLocale(Locale? newLocale) {
    if (newLocale == null) return;
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
  }
}
