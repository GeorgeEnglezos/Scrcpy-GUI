import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../utils/app_paths.dart';

/// Service for persisting and loading scrcpy option state to/from disk.
///
/// Stores all 10 option objects as a single JSON file so that user
/// configuration survives tab switches and app restarts.
class OptionsStateService {
  static const String _fileName = 'scrcpy_options_state.json';

  /// Cached resolved file path (set after first resolution).
  static String? _cachedFilePath;

  Future<String> get _filePath async {
    if (_cachedFilePath != null) return _cachedFilePath!;
    final basePath = await AppPaths.getBasePath();
    _cachedFilePath = p.join(basePath, _fileName);
    return _cachedFilePath!;
  }

  Future<Map<String, dynamic>?> loadOptionsState() async {
    try {
      final path = await _filePath;
      final file = File(path);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading options state: $e');
    }
    return null;
  }

  Future<void> saveOptionsState(Map<String, dynamic> state) async {
    try {
      final path = await _filePath;
      final file = File(path);
      await file.writeAsString(jsonEncode(state));
    } catch (e) {
      debugPrint('Error saving options state: $e');
    }
  }
}
