/// ADB Scrape Strategy
///
/// TODO: Implement this strategy.
///
/// This strategy fetches icons and labels by:
///   1. Pulling the APK from the device via ADB and extracting the launcher icon
///   2. Querying F-Droid JSON API for icon URL and app name
///   3. Querying Aptoide JSON API for icon URL and app name
///
/// Reference implementation (original logic to port):
///   Branch:  backup/pre-refactor-6258dbc
///   File:    lib/services/app_icon_service.dart
///   Methods: _resolveViaAdb(), _resolveFDroidIconAndLabel(),
///            _resolveAptoideIconAndLabel(), _downloadBytesAdb(),
///            _resolveLabelViaAdb(), _logAdbCandidates(),
///            _fetchHtml(), _downloadBytes(), _createClient()
library;

import 'dart:io';
import '../icon_fetch_strategy.dart';

class AdbScrapeStrategy implements IconFetchStrategy {
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
    // TODO: Implement AdbScrapeStrategy.fetchAll()
    // See reference above for the original logic to migrate.
    throw UnimplementedError('AdbScrapeStrategy.fetchAll() is not yet implemented.');
  }
}
