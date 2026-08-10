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

  group('AppSettings.appIconsDirectory', () {
    // The whole point of the field is that the user can move the icon cache.
    // Omitting it from toJson would send every chosen path back to the derived
    // default on the next load, silently and without an error anywhere.
    test('survives a json round-trip', () {
      final original = AppSettings.defaultSettings().copyWith(
        appIconsDirectory: '/my/icons',
      );
      final restored = AppSettings.fromJsonString(original.toJsonString());
      expect(restored.appIconsDirectory, '/my/icons');
    });

    test('is empty for a settings file written before the key existed', () {
      expect(AppSettings.fromJsonString('{}').appIconsDirectory, isEmpty);
    });
  });

  group('AppSettings.setupCompleted', () {
    test('is false for a brand new install', () {
      expect(AppSettings.defaultSettings().setupCompleted, isFalse);
    });

    // An existing settings file with no such key belongs to someone who
    // upgraded, not to a new install. Defaulting this to false like every
    // other field in fromJson would show the wizard to the entire existing
    // userbase the first time they run the new version.
    test('is true for a settings file written before the key existed', () {
      expect(AppSettings.fromJsonString('{}').setupCompleted, isTrue);
    });

    // toJson must always write the key. If it were omitted, a fresh install's
    // defaults would be saved without it and read back as true, so the wizard
    // would never open at all.
    test('stays false through a json round-trip', () {
      final original = AppSettings.defaultSettings();
      final restored = AppSettings.fromJsonString(original.toJsonString());
      expect(restored.setupCompleted, isFalse);
    });

    test('can be flipped through copyWith', () {
      final done = AppSettings.defaultSettings().copyWith(setupCompleted: true);
      expect(done.setupCompleted, isTrue);
    });
  });
}
