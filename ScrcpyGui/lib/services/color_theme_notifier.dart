import 'package:flutter/foundation.dart';

import '../models/color_preset.dart';

class ColorThemeNotifier extends ChangeNotifier {
  final List<ColorPreset> presets;
  late ColorPreset _current;

  ColorThemeNotifier({
    required this.presets,
    required String selectedName,
  }) {
    _current = presets.firstWhere(
      (p) => p.name == selectedName,
      orElse: () => presets.first,
    );
  }

  ColorPreset get current => _current;

  void setPreset(String name) {
    final next = presets.firstWhere(
      (p) => p.name == name,
      orElse: () => _current,
    );
    if (next.name == _current.name) return;
    _current = next;
    notifyListeners();
  }
}
