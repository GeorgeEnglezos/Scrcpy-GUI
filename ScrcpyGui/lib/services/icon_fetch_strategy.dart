/// Abstract strategy interface for fetching app icons and labels.
/// All concrete implementations live in lib/services/strategies/.
library;

import 'dart:io';

/// The user-selectable fetch method.
/// Stored as a string in AppSettings JSON.
enum IconFetchMethod {
  adbScrape,       // ADB guesswork + F-Droid + Aptoide (default)
  helperApk,       // Install helper APK, trigger service, pull results
  oneClickExport,  // Future: one-click export app
}

/// Parses [value] to [IconFetchMethod], defaulting to [IconFetchMethod.adbScrape].
IconFetchMethod iconFetchMethodFromString(String? value) {
  return IconFetchMethod.values.firstWhere(
    (e) => e.name == value,
    orElse: () => IconFetchMethod.adbScrape,
  );
}

abstract class IconFetchStrategy {
  /// Fetches icons and labels for [packages], writing results to the cache
  /// and calling the provided callbacks for live UI updates.
  ///
  /// [packages]            — full list to process
  /// [labels]              — mutable map, updated in place as labels are found
  /// [batchSize]           — how many packages to process concurrently
  /// [forceUpdate]         — if true, re-fetch even if already cached
  /// [isCancelled]         — return true to abort mid-run
  /// [onLabelDiscovered]   — called when a new label is scraped
  /// [onBatchDone]         — called after each batch with partial icon results
  Future<void> fetchAll({
    required List<String> packages,
    required Map<String, String> labels,
    required int batchSize,
    required bool forceUpdate,
    required bool Function() isCancelled,
    required void Function(String pkg, String label) onLabelDiscovered,
    required void Function(Map<String, File?> partial) onBatchDone,
  });
}
