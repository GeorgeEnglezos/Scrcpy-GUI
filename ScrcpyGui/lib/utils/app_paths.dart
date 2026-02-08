import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Centralized app data directory resolution.
///
/// All services that need to read/write persistent files should use
/// [AppPaths.getBasePath] instead of calling [getApplicationSupportDirectory]
/// directly. The resolved path is cached after the first call.
class AppPaths {
  static String? _basePath;

  /// Returns the base application data directory path and ensures it exists.
  ///
  /// On Windows this resolves to `%APPDATA%\ScrcpyGui`.
  /// The result is cached after the first call.
  static Future<String> getBasePath() async {
    if (_basePath != null) return _basePath!;

    final dir = await getApplicationSupportDirectory();
    _basePath = p.join(dir.path, 'ScrcpyGui');

    final directory = Directory(_basePath!);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return _basePath!;
  }
}
