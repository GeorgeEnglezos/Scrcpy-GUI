import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:scrcpy_gui_prod/services/app_directories.dart';

/// The layout an existing Linux install has: one folder in $HOME holding the
/// config files, the icon cache, the logs, and the user's own recordings.
Directory _legacyInstall(Directory root) {
  final legacy = Directory(p.join(root.path, 'ScrcpyGui'))
    ..createSync(recursive: true);

  File(p.join(legacy.path, 'scrcpy_gui_settings.json'))
      .writeAsStringSync('{"bootTab":"Home"}');
  File(p.join(legacy.path, 'app_drawer_settings.json'))
      .writeAsStringSync('{"showScripts":true}');
  File(p.join(legacy.path, 'color_presets.json')).writeAsStringSync('{}');
  File(p.join(legacy.path, 'commands.json')).writeAsStringSync('{}');

  Directory(p.join(legacy.path, 'app_icons')).createSync();
  File(p.join(legacy.path, 'app_icons', 'com.example.png'))
      .writeAsStringSync('icon');

  Directory(p.join(legacy.path, 'logs')).createSync();
  File(p.join(legacy.path, 'logs', 'old.log')).writeAsStringSync('log');

  Directory(p.join(legacy.path, 'Recordings')).createSync();
  File(p.join(legacy.path, 'Recordings', 'clip.mp4')).writeAsStringSync('mp4');

  return legacy;
}

AppDirectories _targetIn(Directory root) => AppDirectories(
      config: p.join(root.path, '.config', 'ScrcpyGui'),
      cache: p.join(root.path, '.cache', 'ScrcpyGui'),
      state: p.join(root.path, '.local', 'state', 'ScrcpyGui'),
      recordings: p.join(root.path, 'Videos', 'ScrcpyGui'),
      downloads: p.join(root.path, 'Downloads', 'ScrcpyGui'),
    );

void main() {
  group('AppDirectories.linuxFrom', () {
    test('falls back to the XDG defaults when nothing is set', () {
      final dirs = AppDirectories.linuxFrom({'HOME': '/home/gg'}, null);

      expect(dirs.config, '/home/gg/.config/ScrcpyGui');
      expect(dirs.cache, '/home/gg/.cache/ScrcpyGui');
      expect(dirs.state, '/home/gg/.local/state/ScrcpyGui');
      expect(dirs.recordings, '/home/gg/Videos/ScrcpyGui');
      expect(dirs.downloads, '/home/gg/Downloads/ScrcpyGui');
    });

    test('honours the XDG base variables', () {
      final dirs = AppDirectories.linuxFrom({
        'HOME': '/home/gg',
        'XDG_CONFIG_HOME': '/mnt/cfg',
        'XDG_CACHE_HOME': '/mnt/cache',
        'XDG_STATE_HOME': '/mnt/state',
      }, null);

      expect(dirs.config, '/mnt/cfg/ScrcpyGui');
      expect(dirs.cache, '/mnt/cache/ScrcpyGui');
      expect(dirs.state, '/mnt/state/ScrcpyGui');
    });

    // The spec says a relative or empty value must be treated as unset.
    test('ignores a relative or empty XDG value', () {
      final dirs = AppDirectories.linuxFrom({
        'HOME': '/home/gg',
        'XDG_CONFIG_HOME': 'relative/path',
        'XDG_CACHE_HOME': '',
      }, null);

      expect(dirs.config, '/home/gg/.config/ScrcpyGui');
      expect(dirs.cache, '/home/gg/.cache/ScrcpyGui');
    });

    test('reads the localised folder names out of user-dirs.dirs', () {
      const userDirs = '''
# This file is written by xdg-user-dirs-update
XDG_DOWNLOAD_DIR="\$HOME/Lampsyxeis"
XDG_VIDEOS_DIR="\$HOME/Vinteo"
''';

      final dirs = AppDirectories.linuxFrom({'HOME': '/home/gg'}, userDirs);

      expect(dirs.recordings, '/home/gg/Vinteo/ScrcpyGui');
      expect(dirs.downloads, '/home/gg/Lampsyxeis/ScrcpyGui');
    });

    test('an absolute env var beats the user-dirs.dirs entry', () {
      final dirs = AppDirectories.linuxFrom(
        {'HOME': '/home/gg', 'XDG_VIDEOS_DIR': '/mnt/media'},
        'XDG_VIDEOS_DIR="\$HOME/Videos"',
      );

      expect(dirs.recordings, '/mnt/media/ScrcpyGui');
    });

    test('falls back when user-dirs.dirs points somewhere relative', () {
      final dirs = AppDirectories.linuxFrom(
        {'HOME': '/home/gg'},
        'XDG_VIDEOS_DIR="Videos"',
      );

      expect(dirs.recordings, '/home/gg/Videos/ScrcpyGui');
    });
  });

  group('AppDirectories.migrateLegacyLayout', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('scrcpygui_home'));
    tearDown(() => root.deleteSync(recursive: true));

    test('moves config, cache and logs into their new homes', () async {
      final legacy = _legacyInstall(root);
      final target = _targetIn(root);

      await AppDirectories.migrateLegacyLayout(legacy: legacy, target: target);

      expect(
        File(p.join(target.config, 'scrcpy_gui_settings.json')).readAsStringSync(),
        '{"bootTab":"Home"}',
      );
      expect(
        File(p.join(target.config, 'app_drawer_settings.json')).existsSync(),
        isTrue,
      );
      expect(File(p.join(target.config, 'color_presets.json')).existsSync(), isTrue);
      expect(File(p.join(target.config, 'commands.json')).existsSync(), isTrue);
      expect(
        File(p.join(target.cache, 'app_icons', 'com.example.png')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(target.state, 'logs', 'old.log')).existsSync(),
        isTrue,
      );
    });

    test('leaves the old folder and the recordings inside it in place', () async {
      final legacy = _legacyInstall(root);

      await AppDirectories.migrateLegacyLayout(
        legacy: legacy,
        target: _targetIn(root),
      );

      // The settings file already holds this absolute path, so moving the
      // user's own videos would break it.
      expect(
        File(p.join(legacy.path, 'Recordings', 'clip.mp4')).existsSync(),
        isTrue,
      );
      expect(legacy.existsSync(), isTrue);
      expect(
        File(p.join(legacy.path, 'scrcpy_gui_settings.json')).existsSync(),
        isFalse,
      );
    });

    test('never overwrites settings already at the destination', () async {
      final legacy = _legacyInstall(root);
      final target = _targetIn(root);

      Directory(target.config).createSync(recursive: true);
      File(p.join(target.config, 'scrcpy_gui_settings.json'))
          .writeAsStringSync('{"bootTab":"Favorites"}');

      await AppDirectories.migrateLegacyLayout(legacy: legacy, target: target);

      expect(
        File(p.join(target.config, 'scrcpy_gui_settings.json')).readAsStringSync(),
        '{"bootTab":"Favorites"}',
      );
      // The loser stays put rather than being deleted.
      expect(
        File(p.join(legacy.path, 'scrcpy_gui_settings.json')).existsSync(),
        isTrue,
      );
    });

    test('is safe to run twice', () async {
      final legacy = _legacyInstall(root);
      final target = _targetIn(root);

      await AppDirectories.migrateLegacyLayout(legacy: legacy, target: target);
      await AppDirectories.migrateLegacyLayout(legacy: legacy, target: target);

      expect(
        File(p.join(target.config, 'scrcpy_gui_settings.json')).readAsStringSync(),
        '{"bootTab":"Home"}',
      );
      expect(
        File(p.join(target.cache, 'app_icons', 'com.example.png')).existsSync(),
        isTrue,
      );
    });

    test('does nothing when there is no old install', () async {
      final target = _targetIn(root);

      await AppDirectories.migrateLegacyLayout(
        legacy: Directory(p.join(root.path, 'ScrcpyGui')),
        target: target,
      );

      expect(Directory(target.config).existsSync(), isFalse);
    });

    // Windows and macOS keep the one folder, so the legacy path and the config
    // path are the same directory and there is nothing to move.
    test('does nothing when the old folder is already the config folder', () async {
      final legacy = _legacyInstall(root);
      final target = AppDirectories.singleFolder(legacy.path);

      await AppDirectories.migrateLegacyLayout(legacy: legacy, target: target);

      expect(
        File(p.join(legacy.path, 'scrcpy_gui_settings.json')).existsSync(),
        isTrue,
      );
      expect(Directory(p.join(legacy.path, 'app_icons')).existsSync(), isTrue);
    });
  });
}
