import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Light and dark [ThemeData] for the native shell (splash, loading, error,
/// and settings screens). The WebView itself is left to render the
/// website's own styling -- this theme intentionally never attempts to
/// restyle web content.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryGold,
      brightness: brightness,
      primary: AppConstants.primaryGold,
      error: AppConstants.errorRed,
      surface: isDark ? AppConstants.primaryBlack : AppConstants.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? AppConstants.primaryBlack
          : AppConstants.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppConstants.primaryBlack
            : AppConstants.white,
        foregroundColor: isDark
            ? AppConstants.white
            : AppConstants.primaryBlack,
        elevation: 0,
        centerTitle: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppConstants.primaryGold,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryGold,
          foregroundColor: AppConstants.primaryBlack,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? AppConstants.primaryGold
              : AppConstants.deepGold,
          minimumSize: const Size(64, 48),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? AppConstants.primaryGold : AppConstants.deepGold,
      ),
    );
  }
}
