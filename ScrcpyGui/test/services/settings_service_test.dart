import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/services/app_icon_cache.dart';
import 'package:scrcpy_gui_prod/services/settings_service.dart';

void main() {
  group('SettingsService.withDirectoryDefaults', () {
    test('fills every unset directory from the settings directory', () {
      final filled = SettingsService.withDirectoryDefaults(
        AppSettings.defaultSettings(),
        '/cfg',
      );

      expect(filled.recordingsDirectory, '/cfg/Recordings');
      expect(filled.downloadsDirectory, '/cfg/Downloads');
      expect(filled.batDirectory, '/cfg/Downloads');
      // The location that holds the cache folder, not the folder itself, so
      // AppIconCache still resolves the historical <settingsDir>/app_icons.
      expect(filled.appIconsDirectory, '/cfg');
      expect(AppIconCache.cachePathIn(filled.appIconsDirectory), endsWith('app_icons'));
    });

    test('leaves directories the user already chose alone', () {
      final chosen = AppSettings.defaultSettings().copyWith(
        recordingsDirectory: '/my/rec',
        downloadsDirectory: '/my/dl',
        batDirectory: '/my/scripts',
        appIconsDirectory: '/my/icons',
      );

      final filled = SettingsService.withDirectoryDefaults(chosen, '/cfg');

      expect(filled.recordingsDirectory, '/my/rec');
      expect(filled.downloadsDirectory, '/my/dl');
      expect(filled.batDirectory, '/my/scripts');
      expect(filled.appIconsDirectory, '/my/icons');
    });

    // Scripts follow Downloads rather than the settings directory, so a user
    // who moved Downloads does not end up with the two split apart.
    test('points an unset scripts directory at the chosen downloads one', () {
      final chosen = AppSettings.defaultSettings().copyWith(
        downloadsDirectory: '/my/dl',
      );

      expect(
        SettingsService.withDirectoryDefaults(chosen, '/cfg').batDirectory,
        '/my/dl',
      );
    });

    test('does not mutate the settings it was given', () {
      final original = AppSettings.defaultSettings();

      SettingsService.withDirectoryDefaults(original, '/cfg');

      expect(original.downloadsDirectory, isEmpty);
    });
  });
}
