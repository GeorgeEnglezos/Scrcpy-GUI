import 'package:flutter/material.dart';

class ColorPreset {
  final String name;
  final String brightness; // 'dark' or 'light'
  final Color primary;
  final Color background;
  final Color surface;
  final Color inputFill;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color hover;
  final Color focus;
  final Color commandSurface;

  const ColorPreset({
    required this.name,
    required this.brightness,
    required this.primary,
    required this.background,
    required this.surface,
    required this.inputFill,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.hover,
    required this.focus,
    required this.commandSurface,
  });

  factory ColorPreset.fromJson(Map<String, dynamic> json) => ColorPreset(
    name: json['name'] as String,
    brightness: json['brightness'] as String? ?? 'dark',
    primary: _hex(json['primary'] as String? ?? '#8B5CF6'),
    background: _hex(json['background'] as String? ?? '#0E0E0E'),
    surface: _hex(json['surface'] as String? ?? '#161616'),
    inputFill: _hex(json['inputFill'] as String? ?? '#0E0E0E'),
    divider: _hex(json['divider'] as String? ?? '#1F1F1F'),
    textPrimary: _hex(json['textPrimary'] as String? ?? '#FFFFFF'),
    textSecondary: _hex(json['textSecondary'] as String? ?? '#B3B3B3'),
    hover: _hex(json['hover'] as String? ?? '#2A2A2A'),
    focus: _hex(json['focus'] as String? ?? '#3B3B3B'),
    commandSurface: _hex(json['commandSurface'] as String? ?? '#1F1F1F'),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'brightness': brightness,
    'primary': _toHex(primary),
    'background': _toHex(background),
    'surface': _toHex(surface),
    'inputFill': _toHex(inputFill),
    'divider': _toHex(divider),
    'textPrimary': _toHex(textPrimary),
    'textSecondary': _toHex(textSecondary),
    'hover': _toHex(hover),
    'focus': _toHex(focus),
    'commandSurface': _toHex(commandSurface),
  };

  static Color _hex(String hex) =>
      Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

  static String _toHex(Color color) =>
      '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
