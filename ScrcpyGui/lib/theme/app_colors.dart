/// App color palette - dark theme with purple accents
library;

import 'package:flutter/material.dart';

class AppColors {
  // Base
  static const background = Color(0xFF0E0E0E);
  static const surface = Color(0xFF161616);
  static const divider = Color(0xFF1F1F1F);
  static const commandGrey = Color.fromARGB(255, 31, 31, 31);

  // Primary (Purple)
  static const primary = Color(0xFF8B5CF6);
  static const primaryLight = Color(0xFFB794F4);
  static const primaryDark = Color(0xFF6D28D9);

  // Secondary
  static const secondary = Color(0xFF6366F1);
  static const accent = Color(0xFF9333EA);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB3B3B3);

  // States
  static const success = Color(0xFF22C55E);

  /// Warning state color (yellow)
  static const warning = Color(0xFFFACC15);

  /// Error state color (red)
  static const error = Color(0xFFEF4444);

  // Hover and focus
  /// Hover state background color
  static const hover = Color(0xFF2A2A2A);

  /// Focus state background color
  static const focus = Color(0xFF3B3B3B);

  // Button colors
  /// Favorite button color (red)
  static const favoriteRed = Color(0xFFEF4444);

  /// Run/Start button color (green)
  static const runGreen = Color(0xFF22C55E);

  /// Connect button color (green)
  static const connectGreen = Color(0xFF22C55E);

  /// Stop button color (red)
  static const stopRed = Color(0xFFEF4444);

  // Recording theme (Red)
  /// Primary color for recording panel
  static const recordingPrimary = Color(0xFFEF4444);

  /// Secondary color for recording panel
  static const recordingSecondary = Color(0xFFDC2626);

  // Virtual Display theme (Blue)
  /// Primary color for virtual display panel
  static const virtualDisplayPrimary = Color(0xFF3B82F6);

  /// Secondary color for virtual display panel
  static const virtualDisplaySecondary = Color(0xFF2563EB);

  // General theme (Orange)
  /// Primary color for general commands panel
  static const generalPrimary = Color(0xFFF97316);

  /// Secondary color for general commands panel
  static const generalSecondary = Color(0xFFEA580C);

  // Audio theme (Green)
  /// Primary color for audio commands panel
  static const audioPrimary = Color(0xFF10B981);

  /// Secondary color for audio commands panel
  static const audioSecondary = Color(0xFF059669);

  // Package Selector theme (Amber)
  /// Primary color for package selector panel
  static const packagePrimary = Color(0xFFF59E0B);

  /// Secondary color for package selector panel
  static const packageSecondary = Color(0xFFD97706);
}
