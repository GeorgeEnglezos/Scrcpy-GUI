/// Application theme configuration.
///
/// This file defines the Material Design theme for the application,
/// configuring colors, text styles, and component themes.
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Provides the application's Material Design theme configuration.
///
/// The [AppTheme] class contains the complete dark theme configuration
/// using Material 3 design principles with custom color overrides from
/// [AppColors].
class AppTheme {
  static const _lightBackground = Color(0xFFECEEF6);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightDivider = Color(0xFFC5C9D6);
  static const _lightTextPrimary = Color(0xFF161A23);
  static const _lightTextSecondary = Color(0xFF484F61);

  /// Builds the dark theme with [primary] as the accent color.
  ///
  /// Themes are functions of the primary color (not statics) because
  /// component themes (buttons, inputs) capture colors at construction —
  /// a later `copyWith(colorScheme: ...)` would leave them stale.
  static ThemeData dark(Color primary) =>
      ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        dividerColor: AppColors.divider,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: _elevatedButtonTheme(primary),
        inputDecorationTheme: _inputDecorationTheme(primary, AppColors.divider),
      );

  /// Builds the light theme with [primary] as the accent color.
  static ThemeData light(Color primary) =>
      ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: _lightBackground,
        cardColor: _lightSurface,
        dividerColor: _lightDivider,
        colorScheme: const ColorScheme.light().copyWith(
          primary: primary,
          secondary: AppColors.secondary,
          surface: _lightSurface,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSurface: _lightTextPrimary,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _lightTextPrimary, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: _lightTextSecondary, fontWeight: FontWeight.w500),
        ),
        elevatedButtonTheme: _elevatedButtonTheme(primary),
        inputDecorationTheme: _inputDecorationTheme(primary, _lightDivider),
      );

  /// App-wide default elevated-button look (the style repeated across
  /// pages before theming): primary background, white text, 8px radius.
  static ElevatedButtonThemeData _elevatedButtonTheme(Color primary) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  /// App-wide default text-input look: 8px outline, divider-colored border,
  /// primary-colored focus border.
  static InputDecorationTheme _inputDecorationTheme(
    Color primary,
    Color divider,
  ) =>
      InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary),
        ),
      );
}
