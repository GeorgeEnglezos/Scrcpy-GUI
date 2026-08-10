import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/services/app_icon_cache.dart';
import 'package:scrcpy_gui_prod/services/settings_service.dart';

void main() {
  late Directory from;
  late Directory to;

  /// Writes [name] into the cache folder nested under [location].
  File seedCache(Directory location, String name, String contents) {
    final dir = Directory(AppIconCache.cachePathIn(location.path))
      ..createSync(recursive: true);
    return File(p.join(dir.path, name))..writeAsStringSync(contents);
  }

  setUp(() {
    from = Directory.systemTemp.createTempSync('icon_cache_from');
    to = Directory.systemTemp.createTempSync('icon_cache_to');
  });

  tearDown(() {
    if (from.existsSync()) from.deleteSync(recursive: true);
    if (to.existsSync()) to.deleteSync(recursive: true);
  });

  // The setting names a location to keep the cache in, and the cache always
  // lives in a folder this app creates inside it. That nesting is what keeps
  // clearCache, which deletes recursively, from emptying a folder the user
  // picked for something else.
  group('AppIconCache.cachePathIn', () {
    test('nests a dedicated folder inside the chosen location', () {
      expect(
        AppIconCache.cachePathIn(p.join('C:', 'Users', 'me', 'Documents')),
        p.join('C:', 'Users', 'me', 'Documents', 'app_icons'),
      );
    });

    test('never returns the chosen location itself', () {
      const location = '/home/me/Documents';
      expect(AppIconCache.cachePathIn(location), isNot(location));
    });
  });

  // The bug this guards: clearCache deletes its directory's contents
  // recursively. Once the location became a folder the user picks, resolving
  // the cache to that folder itself turned "Clear Internal Cache" into
  // "recursively empty my Documents".
  group('AppIconCache.clearCache', () {
    tearDown(() => SettingsService.debugSetSettings(null));

    test('empties the cache without touching the chosen location', () async {
      SettingsService.debugSetSettings(
        AppSettings.defaultSettings().copyWith(appIconsDirectory: from.path),
      );
      seedCache(from, 'a.png', 'icon');
      final userFile = File(p.join(from.path, 'my-thesis.docx'))
        ..writeAsStringSync('mine');
      final userFolder = Directory(p.join(from.path, 'Photos'))..createSync();

      await AppIconCache.clearCache();

      expect(userFile.existsSync(), isTrue);
      expect(userFolder.existsSync(), isTrue);
      expect(Directory(AppIconCache.cachePathIn(from.path)).listSync(), isEmpty);
    });
  });

  group('AppIconCache.copyCache', () {
    test('copies icons and the label file to the new cache', () async {
      seedCache(from, 'com.example.app.png', 'icon');
      seedCache(from, '_labels.json', '{"a":"b"}');

      await AppIconCache.copyCache(from.path, to.path);

      final target = AppIconCache.cachePathIn(to.path);
      expect(File(p.join(target, 'com.example.app.png')).existsSync(), isTrue);
      expect(
        File(p.join(target, '_labels.json')).readAsStringSync(),
        '{"a":"b"}',
      );
    });

    // The originals are the user's only copy until they confirm the move
    // worked, so copying must not be a disguised delete.
    test('leaves the originals in place', () async {
      final original = seedCache(from, 'a.png', 'icon');

      await AppIconCache.copyCache(from.path, to.path);

      expect(original.existsSync(), isTrue);
    });

    // Only the cache folder moves. A location the user already keeps their own
    // files in must not have those files duplicated into the new one.
    test('ignores files sitting beside the cache folder', () async {
      seedCache(from, 'a.png', 'icon');
      File(p.join(from.path, 'my-thesis.docx')).writeAsStringSync('mine');

      await AppIconCache.copyCache(from.path, to.path);

      final target = AppIconCache.cachePathIn(to.path);
      expect(File(p.join(target, 'a.png')).existsSync(), isTrue);
      expect(File(p.join(target, 'my-thesis.docx')).existsSync(), isFalse);
      expect(File(p.join(to.path, 'my-thesis.docx')).existsSync(), isFalse);
    });

    test('creates the target cache folder when it does not exist yet', () async {
      seedCache(from, 'a.png', 'icon');

      await AppIconCache.copyCache(from.path, to.path);

      expect(Directory(AppIconCache.cachePathIn(to.path)).existsSync(), isTrue);
    });

    test('does nothing when the source and target are the same', () async {
      seedCache(from, 'a.png', 'icon');

      await AppIconCache.copyCache(from.path, from.path);

      expect(Directory(AppIconCache.cachePathIn(from.path)).listSync().length, 1);
    });

    // Windows spells the same folder several ways. Treating a re-spelling as a
    // move would copy every file onto itself, and each failure is swallowed.
    test('treats a differently spelled path to the same folder as unchanged',
        () async {
      seedCache(from, 'a.png', 'icon');
      final requoted = p.join(from.path, 'sub', '..');

      await AppIconCache.copyCache(from.path, requoted);

      expect(Directory(AppIconCache.cachePathIn(from.path)).listSync().length, 1);
    });

    test('does nothing when the source cache does not exist', () async {
      await AppIconCache.copyCache(from.path, to.path);

      expect(Directory(AppIconCache.cachePathIn(to.path)).existsSync(), isFalse);
    });

    test('skips subdirectories', () async {
      seedCache(from, 'a.png', 'icon');
      Directory(p.join(AppIconCache.cachePathIn(from.path), 'sub'))
          .createSync(recursive: true);

      await AppIconCache.copyCache(from.path, to.path);

      expect(
        Directory(p.join(AppIconCache.cachePathIn(to.path), 'sub')).existsSync(),
        isFalse,
      );
    });
  });
}
