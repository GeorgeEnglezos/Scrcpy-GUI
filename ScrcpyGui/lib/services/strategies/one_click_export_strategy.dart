/// One-Click Export Strategy
///
/// TODO: Implement this strategy.
///
/// This strategy is a future fetch method where the user triggers
/// a one-click export on the Android device to send icons and labels
/// to the desktop app.
///
/// This is a net-new implementation — no reference code exists yet.
library;

import 'dart:io';
import '../icon_fetch_strategy.dart';

class OneClickExportStrategy implements IconFetchStrategy {
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
    // TODO: Implement OneClickExportStrategy.fetchAll()
    throw UnimplementedError('OneClickExportStrategy.fetchAll() is not yet implemented.');
  }
}
