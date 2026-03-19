import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.lightSurface,
      background: AppColors.lightBackground,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headlineMedium,
      iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: AppTextStyles.headlineMedium,
      bodyMedium: AppTextStyles.bodyMedium,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground, // Transparent feel
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.headlineMedium,
      iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    textTheme:
        const TextTheme(
          headlineMedium: AppTextStyles.headlineMedium,
          bodyMedium: AppTextStyles.bodyMedium,
        ).apply(
          bodyColor: AppColors.textPrimaryDark,
          displayColor: AppColors.textPrimaryDark,
        ),
  );
}
