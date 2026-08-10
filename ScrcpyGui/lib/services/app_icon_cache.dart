/// Pure disk cache operations for app icons and labels.
/// No network, no ADB. Safe to call from anywhere.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'settings_service.dart';

class AppIconCache {
  static final SettingsService _settingsService = SettingsService();

  /// Folder created inside the configured location to hold the cache.
  ///
  /// Never skipped, even when the user picked the location themselves:
  /// [clearCache] empties this directory recursively, so it has to be one this
  /// app created. Pointing the setting at Documents must clear
  /// `Documents/app_icons`, never Documents itself.
  static const String _cacheFolderName = 'app_icons';

  /// The cache directory held inside [location].
  static String cachePathIn(String location) =>
      p.join(location, _cacheFolderName);

  /// Returns the icon cache directory, creating it if necessary.
  ///
  /// The configured location wins; the settings directory is the fallback for
  /// settings written before it was configurable, and for the window before
  /// settings finish loading.
  ///
  /// ponytail: read live on every call, so changing the location mid-fetch
  /// splits that run across both folders. Icons are regenerable, so the cost
  /// is a few refetches; take a snapshot per run if that ever stops being true.
  static Future<Directory> cacheDir() async {
    final configured = SettingsService.currentSettings?.appIconsDirectory;
    final location = configured == null || configured.isEmpty
        ? await _settingsService.getSettingsDirectory()
        : configured;
    final dir = Directory(cachePathIn(location));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies the cached icons and labels from the cache under [fromLocation] to
  /// the one under [toLocation].
  ///
  /// Best effort by design: a file that fails to copy is skipped, and the
  /// originals are left where they are. Nothing here is irreplaceable, a lost
  /// icon is refetched, so a partial copy is not worth guarding with a
  /// rollback.
  static Future<void> copyCache(
    String fromLocation,
    String toLocation,
  ) async {
    // p.equals, not ==: on Windows the same folder has several spellings, and
    // copying a file onto itself fails for every entry.
    if (p.equals(fromLocation, toLocation)) return;

    final source = Directory(cachePathIn(fromLocation));
    if (!await source.exists()) return;

    final targetPath = cachePathIn(toLocation);
    final target = Directory(targetPath);
    if (!await target.exists()) await target.create(recursive: true);

    await for (final entity in source.list()) {
      if (entity is! File) continue;
      try {
        await entity.copy(p.join(targetPath, p.basename(entity.path)));
      } catch (_) {
        // Skip this one; the rest of the cache still moves.
      }
    }
  }

  /// Returns the cache file path for [packageName].
  static Future<File> cacheFile(String packageName) async {
    final dir = await cacheDir();
    return File(p.join(dir.path, '$packageName.png'));
  }

  /// Returns the cached [File] for [packageName] if it exists on disk.
  /// Returns null if not cached. Does NOT fetch anything.
  static Future<File?> getCachedIconIfExists(String packageName) async {
    final file = await cacheFile(packageName);
    return await file.exists() ? file : null;
  }

  static Future<File> _labelCacheFile() async {
    final dir = await cacheDir();
    return File(p.join(dir.path, '_labels.json'));
  }

  /// Loads the persisted label map from disk. Returns {} if none exists.
  static Future<Map<String, String>> loadCachedLabels() async {
    try {
      final file = await _labelCacheFile();
      if (!await file.exists()) return {};
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  /// Merges [newLabels] into the persisted label map and writes to disk.
  static Future<void> saveLabels(Map<String, String> newLabels) async {
    try {
      final file = await _labelCacheFile();
      final existing = await loadCachedLabels();
      existing.addAll(newLabels);
      await file.writeAsString(jsonEncode(existing));
    } catch (_) {}
  }

  /// Deletes the cache contents (icons + labels) but keeps the folder.
  ///
  /// Safe against a user-chosen location only because [cacheDir] always nests
  /// [_cacheFolderName] inside it; this recurses.
  static Future<void> clearCache() async {
    final dir = await cacheDir();
    if (!await dir.exists()) return;
    for (final entity in dir.listSync()) {
      await entity.delete(recursive: true);
    }
  }
}
