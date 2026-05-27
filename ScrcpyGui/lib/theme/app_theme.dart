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

  /// The dark theme for the application using Material 3 design.
  ///
  /// This theme configures:
  /// - Dark background and surface colors
  /// - Purple primary color scheme
  /// - Text styles for primary and secondary content
  /// - Card and divider colors
  /// - Error states
  ///
  /// Applied globally through the MaterialApp widget.
  static final ThemeData darkTheme = ThemeData.dark(useMaterial3: true)
      .copyWith(
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        dividerColor: AppColors.divider,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      );

  /// The light theme for the application using Material 3 design.
  static final ThemeData lightTheme = ThemeData.light(useMaterial3: true)
      .copyWith(
        scaffoldBackgroundColor: _lightBackground,
        cardColor: _lightSurface,
        dividerColor: _lightDivider,
        colorScheme: const ColorScheme.light().copyWith(
          primary: AppColors.primary,
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
      );

}
