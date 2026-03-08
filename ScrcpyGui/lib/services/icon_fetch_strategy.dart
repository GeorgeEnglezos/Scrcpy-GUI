/// Abstract strategy interface for fetching app icons and labels.
/// All concrete implementations live in lib/services/strategies/.
library;

import 'dart:io';

/// The user-selectable fetch method.
/// Stored as a string in AppSettings JSON.
enum IconFetchMethod { adbScrape, helperApk, oneClickExport }

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
  });
}
