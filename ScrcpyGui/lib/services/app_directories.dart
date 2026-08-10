/// Where the app keeps its files on each platform.
///
/// Windows and macOS keep everything in the single folder they always used.
/// Linux follows the XDG Base Directory spec instead, so config, cache and
/// logs each land in their own home rather than in a visible `ScrcpyGui`
/// folder in `$HOME`. Following XDG also makes the app work unchanged inside a
/// Flatpak, where the runtime points those variables at the sandbox.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'log_service.dart';

/// Folder name appended to every base directory. The same on all platforms so
/// there is only ever one name to migrate.
const String _appFolderName = 'ScrcpyGui';

/// Files the old single-folder Linux layout held that must survive the move.
const List<String> _legacyConfigFiles = [
  'scrcpy_gui_settings.json',
  'app_drawer_settings.json',
  'color_presets.json',
  'commands.json',
];

class AppDirectories {
  /// Settings, app drawer state, colour presets and saved commands.
  final String config;

  /// Holds the app icon cache folder. Regenerable, so it is safe to lose.
  final String cache;

  /// Log files.
  final String state;

  /// Default target for screen recordings.
  final String recordings;

  /// Default target for files pulled off the device.
  final String downloads;

  const AppDirectories({
    required this.config,
    required this.cache,
    required this.state,
    required this.recordings,
    required this.downloads,
  });

  static Future<AppDirectories>? _resolving;

  /// Resolves the directories, creating them and running the one-off Linux
  /// migration on the way. Runs once per process; later calls await the same
  /// future, so the migration cannot be started twice.
  static Future<AppDirectories> resolve() => _resolving ??= _resolveOnce();

  static Future<AppDirectories> _resolveOnce() async {
    final dirs = _forPlatform();

    // A set because Windows and macOS point all three at the same folder.
    for (final path in {dirs.config, dirs.cache, dirs.state}) {
      await Directory(path).create(recursive: true);
    }

    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        await migrateLegacyLayout(
          legacy: Directory(p.join(home, _appFolderName)),
          target: dirs,
        );
      }
    }

    return dirs;
  }

  static AppDirectories _forPlatform() {
    final env = Platform.environment;

    if (Platform.isWindows) {
      return singleFolder(p.join(env['APPDATA'] ?? '.', _appFolderName));
    }
    if (Platform.isMacOS) {
      return singleFolder(
        p.join(
          env['HOME'] ?? '.',
          'Library',
          'Application Support',
          _appFolderName,
        ),
      );
    }
    return linuxFrom(env, _readUserDirs(env));
  }

  /// The historical layout: one folder holding everything, with recordings and
  /// downloads nested inside it.
  @visibleForTesting
  static AppDirectories singleFolder(String base) => AppDirectories(
        config: base,
        cache: base,
        state: base,
        recordings: p.join(base, 'Recordings'),
        downloads: p.join(base, 'Downloads'),
      );

  /// The XDG layout, resolved from [env] and the contents of `user-dirs.dirs`.
  /// Pure, so the whole mapping is testable without touching a real `$HOME`.
  ///
  /// Built with posix rules rather than the host's, because these are Linux
  /// paths whichever machine works them out.
  @visibleForTesting
  static AppDirectories linuxFrom(Map<String, String> env, String? userDirs) {
    final home = env['HOME'] ?? '.';

    // The spec says a variable that is unset, empty, or relative must be
    // treated as if it were unset.
    String? absolute(String? value) =>
        (value != null && value.isNotEmpty && p.posix.isAbsolute(value))
            ? value
            : null;

    String base(String variable, List<String> fallback) => p.posix.joinAll([
          absolute(env[variable]) ?? p.posix.joinAll([home, ...fallback]),
          _appFolderName,
        ]);

    // The user's own Videos and Downloads folders, which xdg-user-dirs may
    // have named in their language.
    String userDir(String variable, String fallback) => p.posix.join(
          absolute(env[variable]) ??
              _userDirValue(userDirs, variable, home) ??
              p.posix.join(home, fallback),
          _appFolderName,
        );

    return AppDirectories(
      config: base('XDG_CONFIG_HOME', ['.config']),
      cache: base('XDG_CACHE_HOME', ['.cache']),
      state: base('XDG_STATE_HOME', ['.local', 'state']),
      recordings: userDir('XDG_VIDEOS_DIR', 'Videos'),
      downloads: userDir('XDG_DOWNLOAD_DIR', 'Downloads'),
    );
  }

  /// Reads one entry out of the contents of `user-dirs.dirs`, whose lines look
  /// like `XDG_VIDEOS_DIR="$HOME/Videos"`. Returns null when the key is absent
  /// or does not resolve to an absolute path.
  static String? _userDirValue(String? contents, String key, String home) {
    if (contents == null) return null;

    for (final line in contents.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#') || !trimmed.startsWith('$key=')) continue;

      var value = trimmed.substring(key.length + 1).trim();
      if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      if (value.startsWith(r'$HOME')) {
        final rest = value.substring(5).replaceFirst(RegExp(r'^/+'), '');
        value = rest.isEmpty ? home : p.posix.join(home, rest);
      }
      return p.posix.isAbsolute(value) ? value : null;
    }
    return null;
  }

  /// Contents of the user's `user-dirs.dirs`, or null when it is unreadable.
  ///
  /// ponytail: read synchronously because this runs once before the first
  /// frame and the file is a few hundred bytes.
  static String? _readUserDirs(Map<String, String> env) {
    final home = env['HOME'];
    if (home == null || home.isEmpty) return null;

    final configHome = env['XDG_CONFIG_HOME'];
    final base = (configHome != null &&
            configHome.isNotEmpty &&
            p.isAbsolute(configHome))
        ? configHome
        : p.join(home, '.config');

    try {
      final file = File(p.join(base, 'user-dirs.dirs'));
      return file.existsSync() ? file.readAsStringSync() : null;
    } catch (_) {
      return null;
    }
  }

  // Everything below is the pre-1.7.5 Linux move; delete it in 1.9.0.

  /// Moves an old `$HOME/ScrcpyGui` layout into the XDG directories.
  ///
  /// Idempotent: anything already at the destination is left alone, so a run
  /// that died halfway simply resumes. [legacy] itself is never deleted,
  /// because it also holds the user's Recordings and Downloads, whose absolute
  /// paths are already written into the settings file.
  ///
  /// Never throws: a failed migration must not stop the app from starting.
  @visibleForTesting
  static Future<void> migrateLegacyLayout({
    required Directory legacy,
    required AppDirectories target,
  }) async {
    if (p.equals(legacy.path, target.config)) return;
    if (!await legacy.exists()) return;

    for (final name in _legacyConfigFiles) {
      await _moveFile(
        File(p.join(legacy.path, name)),
        p.join(target.config, name),
      );
    }

    await _moveRegenerableDirectory(
      Directory(p.join(legacy.path, 'app_icons')),
      p.join(target.cache, 'app_icons'),
    );
    await _moveRegenerableDirectory(
      Directory(p.join(legacy.path, 'logs')),
      p.join(target.state, 'logs'),
    );
  }

  /// Moves [source] onto [destination], preferring a rename and falling back to
  /// a copy. The original is only deleted once the copy is on disk, so a
  /// failure anywhere leaves the settings readable where they already are.
  static Future<void> _moveFile(File source, String destination) async {
    try {
      if (!await source.exists()) return;
      if (await File(destination).exists()) return;

      await Directory(p.dirname(destination)).create(recursive: true);
      try {
        await source.rename(destination);
      } on FileSystemException {
        // rename cannot cross filesystems, and XDG_CONFIG_HOME can name one.
        await source.copy(destination);
        await source.delete();
      }
    } catch (e) {
      _reportFailure('Could not move ${source.path}; it stays where it is', e);
    }
  }

  /// Moves a directory whose contents can be rebuilt from scratch. No copy
  /// fallback: refetching icons or losing old logs costs less than the code to
  /// walk the tree by hand.
  static Future<void> _moveRegenerableDirectory(
    Directory source,
    String destination,
  ) async {
    try {
      if (!await source.exists()) return;
      if (await Directory(destination).exists()) return;

      await Directory(p.dirname(destination)).create(recursive: true);
      await source.rename(destination);
    } catch (e) {
      _reportFailure(
        'Could not move ${source.path}; leaving it, the contents rebuild',
        e,
      );
    }
  }

  /// Migration runs before [LogService.init], and the log file only opens after
  /// that, so a failure here would otherwise leave no trace anywhere. stderr is
  /// the only channel already listening this early.
  static void _reportFailure(String message, Object error) {
    LogService.error('AppDirectories/migrate', message, err: error);
    debugPrint('AppDirectories: $message ($error)');
  }
}
