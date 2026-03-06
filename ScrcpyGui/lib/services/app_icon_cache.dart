/// Pure disk cache operations for app icons and labels.
/// No network, no ADB. Safe to call from anywhere.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'settings_service.dart';

class AppIconCache {
  static final SettingsService _settingsService = SettingsService();

  /// Returns the icon cache directory, creating it if necessary.
  static Future<Directory> cacheDir() async {
    final base = await _settingsService.getSettingsDirectory();
    final dir = Directory(p.join(base, 'app_icons'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
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

  /// Returns true if the label cache file exists on disk.
  static Future<bool> hasLabelsCache() async {
    final file = await _labelCacheFile();
    return file.exists();
  }

  /// Deletes the entire app_icons/ directory (icons + labels).
  static Future<void> clearCache() async {
    final dir = await cacheDir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Returns the number of cached PNG icon files.
  static Future<int> cachedIconCount() async {
    final dir = await cacheDir();
    if (!await dir.exists()) return 0;
    return dir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).length;
  }
}
