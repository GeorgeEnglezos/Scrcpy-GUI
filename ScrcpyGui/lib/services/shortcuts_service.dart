/// Service for fetching and caching scrcpy keyboard shortcuts documentation.
///
/// Downloads the official shortcuts markdown from the scrcpy repository
/// and caches it locally for offline access. On each app launch, the first
/// access attempts a background refresh from the remote source.
library;

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ShortcutsService {
  static const _remoteUrl =
      'https://raw.githubusercontent.com/Genymobile/scrcpy/refs/heads/master/doc/shortcuts.md';
  static const _cacheFileName = 'shortcuts_cache.md';

  static ShortcutsService? _instance;
  factory ShortcutsService() => _instance ??= ShortcutsService._();
  ShortcutsService._();

  String? _cachedMarkdown;
  bool _hasRefreshedThisSession = false;

  /// Returns the cached markdown content, loading from disk if needed.
  Future<String?> getCachedMarkdown() async {
    if (_cachedMarkdown != null) return _cachedMarkdown;
    final file = await _cacheFile;
    if (await file.exists()) {
      _cachedMarkdown = await file.readAsString();
      return _cachedMarkdown;
    }
    return null;
  }

  /// Fetches the latest markdown from the remote URL and updates the cache.
  /// Returns the new content on success, or null on failure.
  Future<String?> fetchAndCache() async {
    try {
      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final content = response.body;
        final file = await _cacheFile;
        await file.writeAsString(content);
        _cachedMarkdown = content;
        return content;
      }
    } catch (_) {
      // Network error — caller should fall back to cache
    }
    return null;
  }

  /// Attempts a background refresh once per app session.
  /// Returns true if a refresh was performed (regardless of success).
  bool get hasRefreshedThisSession => _hasRefreshedThisSession;
  void markRefreshed() => _hasRefreshedThisSession = true;

  Future<File> get _cacheFile async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _cacheFileName));
  }
}
