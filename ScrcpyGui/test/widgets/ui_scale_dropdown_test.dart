import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/widgets/ui_scale_dropdown.dart';

void main() {
  group('uiScaleLabel', () {
    // The stored value is a double that has been through JSON, so an exact
    // match would leave the dropdown blank on a value that is right.
    test('matches a value that is off by a rounding error', () {
      expect(uiScaleLabel(0.9000004), '90%');
    });

    // Falling back to the first entry would silently show the largest zoom,
    // which is the one setting a confused user is least likely to want.
    test('falls back to the default rather than the first entry', () {
      expect(uiScaleLabel(7.0), kUiScaleDefaultLabel);
      expect(uiScaleLabel(7.0), isNot(kUiScaleOptions.keys.first));
    });

    test('round-trips every offered option', () {
      for (final entry in kUiScaleOptions.entries) {
        expect(uiScaleLabel(entry.value), entry.key);
      }
    });
  });

  // Cross-file: AppSettings.fromJson clamps to these bounds, so an option
  // outside them would be saved, clamped on reload, and snap the dropdown back
  // to a different value than the one the user picked.
  test('every offered scale survives the clamp in AppSettings', () {
    for (final entry in kUiScaleOptions.entries) {
      final restored = AppSettings.fromJsonString('{"uiScale": ${entry.value}}');
      expect(
        restored.uiScale,
        entry.value,
        reason: '${entry.key} is outside [$kMinUiScale, $kMaxUiScale]',
      );
    }
  });
}
