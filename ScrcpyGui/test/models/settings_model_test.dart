import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/models/settings_model.dart';

void main() {
  group('AppSettings.uiScale', () {
    test('defaults to 1.0 for settings files written before it existed', () {
      expect(AppSettings.fromJsonString('{}').uiScale, 1.0);
    });

    // The settings file is hand-editable. A value like 0.05 would render the
    // UI unreadable, including the settings page needed to undo it.
    test('clamps a hand-edited value below the minimum', () {
      final settings = AppSettings.fromJsonString('{"uiScale": 0.05}');
      expect(settings.uiScale, kMinUiScale);
    });

    test('clamps a hand-edited value above the maximum', () {
      final settings = AppSettings.fromJsonString('{"uiScale": 3.0}');
      expect(settings.uiScale, kMaxUiScale);
    });

    test('keeps a zoomed-in value, which used to be clamped away', () {
      expect(AppSettings.fromJsonString('{"uiScale": 1.1}').uiScale, 1.1);
    });

    test('keeps a value inside the range', () {
      expect(AppSettings.fromJsonString('{"uiScale": 0.85}').uiScale, 0.85);
    });

    test('survives a json round-trip', () {
      final original = AppSettings.defaultSettings().copyWith(uiScale: 0.9);
      final restored = AppSettings.fromJsonString(original.toJsonString());
      expect(restored.uiScale, 0.9);
    });
  });
}
