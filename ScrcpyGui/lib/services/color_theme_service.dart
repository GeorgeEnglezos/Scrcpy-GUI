import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/color_preset.dart';
import 'settings_service.dart';

class ColorThemeService {
  static const _fileName = 'color_presets.json';

  static Future<String> _filePath() async {
    final dir = await SettingsService().getSettingsDirectory();
    return p.join(dir, _fileName);
  }

  static Future<List<ColorPreset>> loadPresets() async {
    final path = await _filePath();
    final file = File(path);

    if (!await file.exists()) {
      final defaults = _defaultPresets();
      await _writeFile(file, defaults);
      return defaults;
    }

    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final list = (json['presets'] as List<dynamic>)
          .map((e) => ColorPreset.fromJson(e as Map<String, dynamic>))
          .toList();
      return list.isNotEmpty ? list : _defaultPresets();
    } catch (_) {
      return _defaultPresets();
    }
  }

  static Future<void> _writeFile(File file, List<ColorPreset> presets) async {
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert({'presets': presets.map((p) => p.toJson()).toList()}),
    );
  }

  static List<ColorPreset> _defaultPresets() => const [
    // ── Dark themes ──────────────────────────────────────────────────────────
    ColorPreset(
      name: 'Dark',
      brightness: 'dark',
      primary: Color(0xFF8B5CF6),
      background: Color(0xFF0E0E0E),
      surface: Color(0xFF161616),
      inputFill: Color(0xFF0E0E0E),
      divider: Color(0xFF1F1F1F),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFB3B3B3),
      hover: Color(0xFF2A2A2A),
      focus: Color(0xFF3B3B3B),
      commandSurface: Color(0xFF1F1F1F),
    ),
    ColorPreset(
      name: 'GitHub',
      brightness: 'dark',
      primary: Color(0xFF58A6FF),
      background: Color(0xFF0D1117),
      surface: Color(0xFF161B22),
      inputFill: Color(0xFF0D1117),
      divider: Color(0xFF30363D),
      textPrimary: Color(0xFFE6EDF3),
      textSecondary: Color(0xFF8B949E),
      hover: Color(0xFF1C2128),
      focus: Color(0xFF21262D),
      commandSurface: Color(0xFF161B22),
    ),
    ColorPreset(
      name: 'Lavender Dark',
      brightness: 'dark',
      primary: Color(0xFFA78BFA),
      background: Color(0xFF110F1E),
      surface: Color(0xFF1A1729),
      inputFill: Color(0xFF110F1E),
      divider: Color(0xFF2C2840),
      textPrimary: Color(0xFFEDE8FF),
      textSecondary: Color(0xFF9B90C2),
      hover: Color(0xFF221F33),
      focus: Color(0xFF2D2A42),
      commandSurface: Color(0xFF1A1729),
    ),
    ColorPreset(
      name: 'Monochrome',
      brightness: 'dark',
      primary: Color(0xFFFFFFFF),
      background: Color(0xFF000000),
      surface: Color(0xFF0C0C0C),
      inputFill: Color(0xFF000000),
      divider: Color(0xFF2A2A2A),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFAAAAAA),
      hover: Color(0xFF141414),
      focus: Color(0xFF1E1E1E),
      commandSurface: Color(0xFF0C0C0C),
    ),
    // ── Light themes ─────────────────────────────────────────────────────────
    ColorPreset(
      name: 'Light',
      brightness: 'light',
      primary: Color(0xFF7C3AED),
      background: Color(0xFFECEEF6),
      surface: Color(0xFFFFFFFF),
      inputFill: Color(0xFFE6E9F4),
      divider: Color(0xFFC5C9D6),
      textPrimary: Color(0xFF161A23),
      textSecondary: Color(0xFF484F61),
      hover: Color(0xFFD9DEF0),
      focus: Color(0xFFD0D8EE),
      commandSurface: Color(0xFFE4E8F5),
    ),
    ColorPreset(
      name: 'Lavender Light',
      brightness: 'light',
      primary: Color(0xFF6D28D9),
      background: Color(0xFFEDEAF7),
      surface: Color(0xFFFAFAFF),
      inputFill: Color(0xFFE5E0F5),
      divider: Color(0xFFC2BAE0),
      textPrimary: Color(0xFF1C1836),
      textSecondary: Color(0xFF6B5F92),
      hover: Color(0xFFD8D0EF),
      focus: Color(0xFFCEC5EC),
      commandSurface: Color(0xFFE8E2F5),
    ),
    ColorPreset(
      name: 'Slate',
      brightness: 'light',
      primary: Color(0xFF64748B),
      background: Color(0xFFE8E8E8),
      surface: Color(0xFFF0F0F0),
      inputFill: Color(0xFFE2E2E2),
      divider: Color(0xFFC8C8C8),
      textPrimary: Color(0xFF1A1A1A),
      textSecondary: Color(0xFF5A5A5A),
      hover: Color(0xFFD8D8D8),
      focus: Color(0xFFCCCCCC),
      commandSurface: Color(0xFFE5E5E5),
    ),
    ColorPreset(
      name: 'Monochrome Light',
      brightness: 'light',
      primary: Color(0xFF000000),
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFF5F5F5),
      inputFill: Color(0xFFEEEEEE),
      divider: Color(0xFFD5D5D5),
      textPrimary: Color(0xFF000000),
      textSecondary: Color(0xFF555555),
      hover: Color(0xFFE5E5E5),
      focus: Color(0xFFDDDDDD),
      commandSurface: Color(0xFFEEEEEE),
    ),
  ];
}
