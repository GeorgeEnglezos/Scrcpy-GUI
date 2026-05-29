library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/color_theme_notifier.dart';

extension AppThemeColors on BuildContext {
  bool get isDarkTheme =>
      watch<ColorThemeNotifier>().current.brightness == 'dark';

  Color get appPrimary =>
      watch<ColorThemeNotifier>().current.primary;

  Color get appBackground =>
      watch<ColorThemeNotifier>().current.background;

  Color get appSurface =>
      watch<ColorThemeNotifier>().current.surface;

  Color get appInputFill =>
      watch<ColorThemeNotifier>().current.inputFill;

  Color get appDivider =>
      watch<ColorThemeNotifier>().current.divider;

  Color get appTextPrimary =>
      watch<ColorThemeNotifier>().current.textPrimary;

  Color get appTextSecondary =>
      watch<ColorThemeNotifier>().current.textSecondary;

  Color get appHover =>
      watch<ColorThemeNotifier>().current.hover;

  Color get appFocus =>
      watch<ColorThemeNotifier>().current.focus;

  Color get appCommandSurface =>
      watch<ColorThemeNotifier>().current.commandSurface;

  Color get appOnPrimary =>
      appPrimary.computeLuminance() > 0.35 ? Colors.black : Colors.white;
}
