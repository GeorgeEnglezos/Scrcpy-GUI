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
  static ThemeData darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
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
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    ),
  );
}
