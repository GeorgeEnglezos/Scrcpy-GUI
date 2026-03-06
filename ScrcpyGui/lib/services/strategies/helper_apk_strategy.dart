/// Helper APK Strategy
///
/// TODO: Implement this strategy.
///
/// This strategy fetches icons and labels by:
///   1. Installing the helper APK (com.george.iconhelper) on the device if missing
///   2. Triggering ExtractService via ADB intent
///   3. Polling for the DONE sentinel file
///   4. Pulling all extracted PNGs and labels.json from the device cache
///
/// Reference implementation (original logic to port):
///   Branch:  backup/pre-refactor-6258dbc
///   File:    lib/services/app_icon_service.dart
///   Methods: syncWithHelper(), _ensureHelperInstalled(),
///            _triggerHelperExtraction(), _pullIconsFromHelper()
///
/// The helper APK source lives in: android_helper/
/// Build instructions:             android_helper/README.md
library;

import 'dart:io';
import '../icon_fetch_strategy.dart';

class HelperApkStrategy implements IconFetchStrategy {
  @override
  Future<void> fetchAll({
    required List<String> packages,
    required Map<String, String> labels,
    required int batchSize,
    required bool forceUpdate,
    required bool Function() isCancelled,
    required void Function(String pkg, String label) onLabelDiscovered,
    required void Function(Map<String, File?> partial) onBatchDone,
  }) async {
    // TODO: Implement HelperApkStrategy.fetchAll()
    // See reference above for the original logic to migrate.
    throw UnimplementedError('HelperApkStrategy.fetchAll() is not yet implemented.');
  }
}
