/// ADB Scrape Strategy
library;

import 'dart:io';
import '../icon_fetch_strategy.dart';

class AdbScrapeStrategy implements IconFetchStrategy {
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
    throw UnimplementedError(
      'AdbScrapeStrategy.fetchAll() is not yet implemented.',
    );
  }
}
