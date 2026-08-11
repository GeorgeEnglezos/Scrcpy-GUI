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
import 'package:flutter/services.dart';
import '../app_icon_cache.dart';
import '../icon_fetch_strategy.dart';
import '../log_service.dart';
import '../adb_service.dart';
import '../shell_runner.dart';

class HelperApkStrategy implements IconFetchStrategy {
  final bool autoInstall;

  const HelperApkStrategy({this.autoInstall = false});

  static const String _apkPackage = 'com.george.iconhelper';
  static const String _apkName = 'IconHelper-debug.apk';
  // Helper app exports to shared external storage (accessible by ADB)
  static const String _exportDir = '/sdcard/Android/data/com.george.iconhelper/files/iconhelper';
  static const Duration _pollInterval = Duration(milliseconds: 500);
  static const Duration _pollTimeout = Duration(seconds: 300);

  /// Runs a command in the device shell via `adb -s <id> shell <args>`.
  /// argv all the way; the local shell is never involved.
  Future<String> _deviceShell(String deviceId, List<String> deviceArgs) =>
      ShellRunner.runOut(
        AdbService.adbExecutable,
        ['-s', deviceId, 'shell', ...deviceArgs],
      );

  /// Runs `test [testArgs]` on the device and returns true if it passed.
  /// The pipeline is passed as one argument so it executes in the device
  /// shell, never in the local one (stock Windows has no `test`).
  Future<bool> _deviceTest(String deviceId, String testArgs) async {
    final result = await _deviceShell(
      deviceId,
      ['test $testArgs && echo OK || echo MISSING'],
    );
    return result.trim() == 'OK';
  }

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
    void Function(int current, int total, String status)? onProgress,
  }) async {
    LogService.info('HelperApkStrategy', 'Starting fetch for device=${LogService.sanitizeDevice(deviceId)} packages=${packages.length}');
    final n = packages.length;

    // Step 1: Check APK is installed; auto-install if requested
    onProgress?.call(0, n, 'Checking helper APK...');
    final isInstalled = await _isApkInstalled(deviceId);
    if (!isInstalled) {
      if (autoInstall) {
        LogService.info('HelperApkStrategy', 'APK not installed, installing via ADB on device=${LogService.sanitizeDevice(deviceId)}');
        onProgress?.call(0, n, 'Installing helper APK...');
        await _installApk(deviceId);
        LogService.info('HelperApkStrategy', 'APK installed successfully on device=${LogService.sanitizeDevice(deviceId)}');
      } else {
        LogService.warning('HelperApkStrategy', 'APK not installed on device=${LogService.sanitizeDevice(deviceId)} and auto-install is off');
        throw Exception(
          'Helper APK is not installed on device $deviceId. Enable "Auto-install via ADB" to install it automatically.',
        );
      }
    } else {
      LogService.debug('HelperApkStrategy', 'APK already installed on device=${LogService.sanitizeDevice(deviceId)}');
    }

    // Step 2: Check if an export is already mid-flight (dir exists but no
    // labels.json yet). If so, just poll, don't re-trigger and interrupt it.
    // Otherwise always trigger a fresh export so the desktop never relies on
    // stale on-device files.
    onProgress?.call(0, n, 'Checking export state...');
    final labelsDone = await _deviceTest(deviceId, '-f $_exportDir/labels.json');

    bool exportInProgress = false;
    if (!labelsDone) {
      exportInProgress = await _deviceTest(deviceId, '-d $_exportDir');
    }

    if (exportInProgress) {
      // Another fetch is already running, don't interrupt it, just wait.
      LogService.info('HelperApkStrategy',
          'Export already in progress on device=${LogService.sanitizeDevice(deviceId)}, skipping trigger');
      onProgress?.call(0, n, 'Waiting for mobile app to finish exporting icons...');
      final success = await _pollForExportCompletion(deviceId);
      if (!success) {
        LogService.error('HelperApkStrategy', 'Export timed out after ${_pollTimeout.inSeconds}s on device=${LogService.sanitizeDevice(deviceId)}');
        throw Exception('Export timed out after ${_pollTimeout.inSeconds}s');
      }
      LogService.info('HelperApkStrategy', 'Export completed on device=${LogService.sanitizeDevice(deviceId)}');
    } else {
      // Step 3: Trigger a fresh export.
      // Force-stop first so am start always goes through onCreate regardless
      // of whether the Activity is already alive in the foreground/background.
      onProgress?.call(0, n, 'Launching helper app on device...');
      LogService.info('HelperApkStrategy', 'Triggering export on device=${LogService.sanitizeDevice(deviceId)}');
      await _triggerExport(deviceId);

      onProgress?.call(0, n, 'Waiting for mobile app to export icons...');
      final success = await _pollForExportCompletion(deviceId);
      if (!success) {
        LogService.error('HelperApkStrategy', 'Export timed out after ${_pollTimeout.inSeconds}s on device=${LogService.sanitizeDevice(deviceId)}');
        throw Exception('Export timed out after ${_pollTimeout.inSeconds}s');
      }
      LogService.info('HelperApkStrategy', 'Export completed on device=${LogService.sanitizeDevice(deviceId)}');
    }

    // Step 4: Pull files from device
    onProgress?.call(0, n, 'Pulling icons from mobile to desktop...');
    LogService.info('HelperApkStrategy', 'Pulling export files from device=${LogService.sanitizeDevice(deviceId)}');
    final tempDir = await _createTempDirectory();
    await _pullExportFiles(deviceId, tempDir);

    // Step 5: Parse labels.json
    onProgress?.call(0, n, 'Processing app data...');
    final labelsJson = await _parseLabelsJson(tempDir);
    LogService.info('HelperApkStrategy', 'Parsed ${labelsJson.length} labels from device=${LogService.sanitizeDevice(deviceId)}');
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
    final categoriesFile = File('${tempDir.path}/categories.json');
    if (await categoriesFile.exists()) {
      try {
        final catContent = await categoriesFile.readAsString();
        final catJson = jsonDecode(catContent) as Map<String, dynamic>;
        final categories = catJson.cast<String, String>();
        onCategoriesLoaded?.call(categories);
      } catch (e) {
        LogService.debug('HelperApkStrategy', 'Failed to parse categories.json: $e');
      }
    }

    // Step 6: Load icons in batches
    final iconDir = Directory('${tempDir.path}/icons');
    if (await iconDir.exists()) {
      final iconFiles = await iconDir.list().toList();
      LogService.info('HelperApkStrategy', 'Loading ${iconFiles.length} icons from device=${LogService.sanitizeDevice(deviceId)}');
      var loaded = 0;

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
              loaded++;
            }
          }
        }

        onBatchDone(batchResults);
        onProgress?.call(loaded, iconFiles.length, 'Loading icons...');
      }
    }

    // Step 7: Clean up device and temp directory
    await _cleanupExportDirectory(deviceId);
    await tempDir.delete(recursive: true);
    LogService.info('HelperApkStrategy', 'Fetch complete for device=${LogService.sanitizeDevice(deviceId)}');
  }

  Future<bool> _isApkInstalled(String deviceId) async {
    try {
      // Filter in Dart; piping to grep would run in the LOCAL shell,
      // which doesn't exist on stock Windows.
      final result = await _deviceShell(
        deviceId,
        ['pm', 'list', 'packages', _apkPackage],
      );
      return result.contains(_apkPackage);
    } catch (e) {
      return false;
    }
  }

  Future<void> _installApk(String deviceId) async {
    // Extract the bundled APK asset to a temp file, then install via ADB.
    final data = await rootBundle.load('assets/$_apkName');
    final tempFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}$_apkName',
    );
    await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    try {
      final result = await AdbService.runAdbProcess(['-s', deviceId, 'install', tempFile.path]);
      final out = result.stdout.toString();
      final err = result.stderr.toString();
      // adb install prints "Success" on success; any non-zero exit or stderr indicates failure.
      if (result.exitCode != 0 || (!out.contains('Success') && err.isNotEmpty)) {
        throw Exception(
          'adb install failed (exit ${result.exitCode}): ${err.isNotEmpty ? err : out}',
        );
      }
    } finally {
      await tempFile.delete();
    }
  }

  Future<void> _triggerExport(String deviceId) async {
    // Force-stop first so am start always hits onCreate even if the Activity
    // is currently alive in the foreground or background.
    await _deviceShell(deviceId, ['am', 'force-stop', _apkPackage]);
    await _deviceShell(deviceId, [
      'am',
      'start',
      '-n',
      '$_apkPackage/.MainActivity',
      '--ez',
      'auto_export',
      'true',
    ]);
    // Give the app a moment to launch and start exporting
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<bool> _pollForExportCompletion(String deviceId) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < _pollTimeout) {
      try {
        if (await _deviceTest(deviceId, '-f $_exportDir/labels.json')) {
          return true;
        }
      } catch (e) {
        LogService.debug('HelperApkStrategy', 'Export poll failed: $e');
      }

      await Future.delayed(_pollInterval);
    }

    return false;
  }

  Future<Directory> _createTempDirectory() async {
    // In a Flatpak sandbox /tmp is a private container tmpfs. Host processes
    // spawned via flatpak-spawn --host write to the HOST /tmp, which is a
    // different namespace, so adb pull fails to find the destination dir.
    // XDG_CACHE_HOME resolves to a real on-disk path (~/.var/app/<id>/cache)
    // that is visible at the same absolute path from both container and host.
    final xdgCache = Platform.environment['XDG_CACHE_HOME'];
    final base = (xdgCache != null && xdgCache.isNotEmpty)
        ? Directory(xdgCache)
        : Directory.systemTemp;
    if (!base.existsSync()) await base.create(recursive: true);
    final tempDir = base.createTempSync('iconhelper_');
    return tempDir;
  }

  Future<void> _pullExportFiles(String deviceId, Directory tempDir) async {
    // Pull each item by explicit name so we get a flat layout in tempDir
    // regardless of how different adb versions handle directory pulls.
    for (final item in ['labels.json', 'categories.json', 'icons']) {
      final r = await AdbService.runAdbProcess([
        '-s',
        deviceId,
        'pull',
        '$_exportDir/$item',
        '${tempDir.path}/$item',
      ]);
      LogService.debug(
        'HelperApkStrategy',
        'pull $item exitCode=${r.exitCode} '
        'stderr="${r.stderr.toString().trim()}"',
      );
    }
  }

  Future<Map<String, String>> _parseLabelsJson(Directory tempDir) async {
    try {
      final labelsFile = File('${tempDir.path}/labels.json');
      if (!await labelsFile.exists()) {
        LogService.debug('HelperApkStrategy', 'labels.json not found at ${labelsFile.path}');
        return {};
      }
      final content = await labelsFile.readAsString();
      LogService.debug('HelperApkStrategy', 'labels.json ${content.length} chars');
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json.cast<String, String>();
    } catch (e) {
      LogService.error('HelperApkStrategy', 'Failed to parse labels.json: $e');
      return {};
    }
  }

  Future<void> _cleanupExportDirectory(String deviceId) async {
    try {
      await _deviceShell(deviceId, ['rm', '-rf', _exportDir]);
    } catch (e) {
      LogService.debug('HelperApkStrategy', 'Export dir cleanup failed: $e');
    }
  }
}
