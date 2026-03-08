/// Helper APK Strategy
///
/// Fetches icons and labels by:
///   1. Installing the helper APK (com.george.iconhelper) on the device if missing
///   2. Triggering export via ADB intent
///   3. Polling for labels.json to appear (DONE sentinel)
///   4. Pulling all extracted PNGs and labels.json from the device cache
///   5. Loading results into the cache and returning to caller
///
/// The helper APK source lives in: android_helper/
/// Build instructions:             android_helper/README.md
library;

import 'dart:convert';
import 'dart:io';
import '../icon_fetch_strategy.dart';
import '../terminal_service.dart';
import '../app_icon_cache.dart';

class HelperApkStrategy implements IconFetchStrategy {
  static const String _apkPackage = 'com.george.iconhelper';
  static const String _apkName = 'IconHelper-debug.apk';
  // Helper app exports to shared external storage (accessible by ADB)
  static const String _exportDir = '/sdcard/iconhelper';
  static const Duration _pollInterval = Duration(milliseconds: 500);
  static const Duration _pollTimeout = Duration(seconds: 120);

  String _adbFor(String deviceId) =>
      '${TerminalService.adbExecutable} -s $deviceId';

  void _ignoreError() {}

  @override
  Future<void> fetchAll({
    required String deviceId,
    required List<String> packages,
    required Map<String, String> labels,
    required int batchSize,
    required bool forceUpdate,
    required bool Function() isCancelled,
    required void Function(String pkg, String label) onLabelDiscovered,
    required void Function(Map<String, File?> partial) onBatchDone,
    void Function(Map<String, String> categories)? onCategoriesLoaded,
  }) async {
    try {
      // Step 1: Ensure APK is installed
      final isInstalled = await _isApkInstalled(deviceId);
      if (!isInstalled) {
        await _installApk(deviceId);
      }

      // Step 2: Trigger export on device
      await _triggerExport(deviceId);

      // Step 3: Wait for export to complete (poll for labels.json)
      final success = await _pollForExportCompletion(deviceId);
      if (!success) {
        throw Exception('Export timed out after ${_pollTimeout.inSeconds}s');
      }

      // Step 4: Pull files from device
      final tempDir = await _createTempDirectory();
      await _pullExportFiles(deviceId, tempDir);

      // Step 5: Parse labels.json
      final labelsJson = await _parseLabelsJson(tempDir);
      for (final entry in labelsJson.entries) {
        final pkg = entry.key;
        final label = entry.value;
        // Only update packages that are in our ADB package list
        if (labels.containsKey(pkg) &&
            (labels[pkg] == null || labels[pkg] == pkg)) {
          labels[pkg] = label;
          onLabelDiscovered(pkg, label);
        }
      }

      // Step 5b: Parse categories.json (if present)
      final categoriesFile = File('${tempDir.path}/iconhelper/categories.json');
      if (await categoriesFile.exists()) {
        try {
          final catContent = await categoriesFile.readAsString();
          final catJson = jsonDecode(catContent) as Map<String, dynamic>;
          final categories = catJson.cast<String, String>();
          onCategoriesLoaded?.call(categories);
        } catch (_) {
          _ignoreError();
        }
      }

      // Step 6: Load icons in batches
      final iconDir = Directory('${tempDir.path}/iconhelper/icons');
      if (await iconDir.exists()) {
        final iconFiles = await iconDir.list().toList();

        for (var i = 0; i < iconFiles.length; i += batchSize) {
          if (isCancelled()) {
            break;
          }

          final batch = iconFiles.skip(i).take(batchSize).toList();
          final batchResults = <String, File?>{};

          for (final file in batch) {
            if (file is File) {
              final fileName = file.path.split(Platform.pathSeparator).last;
              final pkg = fileName.replaceAll('.png', '');

              if (labels.containsKey(pkg)) {
                final cacheFile = await AppIconCache.cacheFile(pkg);
                await file.copy(cacheFile.path);
                batchResults[pkg] = cacheFile;
              }
            }
          }

          onBatchDone(batchResults);
        }
      }

      // Step 7: Clean up device and temp directory
      await _cleanupExportDirectory(deviceId);
      await tempDir.delete(recursive: true);
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> _isApkInstalled(String deviceId) async {
    try {
      final result = await TerminalService.runCommand(
        '${_adbFor(deviceId)} shell pm list packages | grep $_apkPackage',
      );
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _installApk(String deviceId) async {
    // APK is in android_helper/build/outputs/apk/debug/ (sibling directory to ScrcpyGui)
    final apkPath = '../android_helper/build/outputs/apk/debug/$_apkName';
    if (!await File(apkPath).exists()) {
      throw Exception(
        'Helper APK not found at $apkPath. Build android_helper first: cd ../android_helper && ./gradlew build',
      );
    }
    await TerminalService.runCommand('${_adbFor(deviceId)} install "$apkPath"');
  }

  Future<void> _triggerExport(String deviceId) async {
    await TerminalService.runCommand(
      '${_adbFor(deviceId)} shell am start -n $_apkPackage/.MainActivity',
    );
    // Give the app a moment to launch
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<bool> _pollForExportCompletion(String deviceId) async {
    final stopwatch = Stopwatch()..start();

    // Check if app is running (best-effort).
    try {
      await TerminalService.runCommand(
        '${_adbFor(deviceId)} shell ps | grep com.george.iconhelper',
      );
    } catch (_) {
      _ignoreError();
    }

    while (stopwatch.elapsed < _pollTimeout) {
      try {
        // Method 1: Check if labels.json exists
        final result1 = await TerminalService.runCommand(
          '${_adbFor(deviceId)} shell test -f $_exportDir/labels.json && echo "FOUND" || echo "NOT_FOUND"',
        );
        final trimmedResult = result1.trim();

        // Check for exact match, not substring (NOT_FOUND contains FOUND)
        if (trimmedResult.contains('FOUND') &&
            !trimmedResult.contains('NOT_FOUND')) {
          return true;
        }

        // Method 2: Try to list the directory to see if it exists
        if (stopwatch.elapsed.inSeconds % 10 == 0) {
          await TerminalService.runCommand(
            '${_adbFor(deviceId)} shell ls -la $_exportDir 2>&1',
          );
        }
      } catch (_) {
        _ignoreError();
      }

      await Future.delayed(_pollInterval);
    }

    return false;
  }

  Future<Directory> _createTempDirectory() async {
    final tempDir = Directory.systemTemp.createTempSync('iconhelper_');
    return tempDir;
  }

  Future<void> _pullExportFiles(String deviceId, Directory tempDir) async {
    await TerminalService.runCommand(
      '${_adbFor(deviceId)} pull $_exportDir ${tempDir.path}/',
    );
  }

  Future<Map<String, String>> _parseLabelsJson(Directory tempDir) async {
    try {
      final labelsFile = File('${tempDir.path}/iconhelper/labels.json');
      if (!await labelsFile.exists()) {
        return {};
      }

      final content = await labelsFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json.cast<String, String>();
    } catch (_) {
      return {};
    }
  }

  Future<void> _cleanupExportDirectory(String deviceId) async {
    try {
      await TerminalService.runCommand(
        '${_adbFor(deviceId)} shell rm -rf $_exportDir',
      );
    } catch (_) {
      _ignoreError();
    }
  }
}
