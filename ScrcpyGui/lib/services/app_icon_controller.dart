/// App Icon Controller
///
/// ChangeNotifier that owns all icon/label state for the App Drawer and
/// Settings page. Single source of truth — no page calls AppIconCache or
/// strategies directly.
///
/// Load order in loadForDevice():
///   1. AppIconCache.loadCachedLabels()  → populate labels from _labels.json
///   2. AppIconCache.getCachedIconIfExists() ×N (parallel) → populate icons from disk
///   3. notifyListeners() → UI renders cache hits immediately
///   4. If uncached packages remain → delegate to active strategy (TODO: stubs)
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/package_names.dart';
import 'app_icon_cache.dart';
import 'icon_fetch_strategy.dart';
import 'strategies/adb_scrape_strategy.dart';
import 'strategies/helper_apk_strategy.dart';
import 'strategies/one_click_export_strategy.dart';

class AppIconController extends ChangeNotifier {
  // ── State ────────────────────────────────────────────────────────────────

  /// Icons keyed by package name.
  /// null  = not yet attempted
  /// File('') = sentinel — attempted, no icon found
  /// File(path) = cached icon on disk
  final Map<String, File?> icons = {};

  /// Human-readable labels keyed by package name.
  /// Updated live as strategies discover names.
  final Map<String, String> labels = {};

  bool isLoading = false;
  int progress = 0;
  int total = 0;
  String? currentDeviceId;
  IconFetchMethod fetchMethod;

  static final File _sentinel = File('');

  bool _cancelled = false;

  AppIconController({this.fetchMethod = IconFetchMethod.adbScrape});

  // ── Strategy selection ────────────────────────────────────────────────────

  IconFetchStrategy _buildStrategy() => switch (fetchMethod) {
        IconFetchMethod.adbScrape => AdbScrapeStrategy(),
        IconFetchMethod.helperApk => HelperApkStrategy(),
        IconFetchMethod.oneClickExport => OneClickExportStrategy(),
      };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Loads icons and labels for [packages] on [deviceId].
  ///
  /// Step 1: Hydrate labels from disk cache immediately.
  /// Step 2: Hydrate icons from disk cache in parallel.
  /// Step 3: Notify listeners so UI renders cache hits.
  /// Step 4: If uncached packages remain, delegate to active strategy.
  Future<void> loadForDevice(String deviceId, List<String> packages) async {
    _cancelled = false;
    currentDeviceId = deviceId;
    total = packages.length;
    progress = 0;

    icons.clear();
    labels.clear();

    // Step 1: Labels from _labels.json
    final cachedLabels = await AppIconCache.loadCachedLabels();
    for (final pkg in packages) {
      final cached = cachedLabels[pkg];
      labels[pkg] = (cached != null && cached.isNotEmpty) ? cached : pkg;
    }

    // Hydrate labels from local dictionary for any that are still raw package names
    for (final pkg in packages) {
      if (labels[pkg] == pkg) {
        final dictLabel = getLocalDictionaryLabel(pkg);
        if (dictLabel != pkg) labels[pkg] = dictLabel;
      }
    }

    isLoading = true;
    notifyListeners();

    // Step 2: Icons from disk cache (parallel)
    final cacheResults = await Future.wait(
      packages.map((pkg) async {
        final file = await AppIconCache.getCachedIconIfExists(pkg);
        return MapEntry(pkg, file);
      }),
    );

    final uncached = <String>[];
    for (final entry in cacheResults) {
      if (entry.value != null) {
        icons[entry.key] = entry.value;
      } else {
        icons[entry.key] = null; // pending
        uncached.add(entry.key);
      }
    }

    progress = packages.length - uncached.length;

    // Step 3: Notify — UI shows everything cached so far
    notifyListeners();

    // Step 4: Nothing uncached → done, skip strategy entirely
    if (uncached.isEmpty) {
      isLoading = false;
      notifyListeners();
      return;
    }

    // Check if a labels cache already exists. If so, mark uncached as sentinel
    // and return — the user can explicitly trigger fetchMissing() to fetch more.
    final hasLabels = await AppIconCache.hasLabelsCache();
    if (hasLabels) {
      for (final pkg in uncached) {
        icons[pkg] = _sentinel;
      }
      isLoading = false;
      notifyListeners();
      return;
    }

    // No cache at all — attempt strategy (will throw UnimplementedError until implemented)
    await _runStrategy(uncached, forceUpdate: false);
  }

  /// Re-fetches all packages using the active strategy, bypassing cache.
  /// Called by the "Scrape Missing Info" button in Settings and App Drawer.
  Future<void> fetchMissing({bool forceUpdate = true}) async {
    if (currentDeviceId == null || labels.isEmpty) return;
    _cancelled = false;
    final packages = labels.keys.toList();
    await _runStrategy(packages, forceUpdate: forceUpdate);
  }

  /// Resets in-memory icon/label state without touching the disk cache.
  Future<void> clearCache() async {
    _cancelled = true;
    _resetMemoryState();
  }

  /// Resets in-memory state without touching the disk cache.
  /// Use when no device is selected (e.g. device disconnected).
  void resetState() {
    _cancelled = true;
    _resetMemoryState();
  }

  void _resetMemoryState() {
    icons.clear();
    labels.clear();
    progress = 0;
    total = 0;
    isLoading = false;
    currentDeviceId = null;
    notifyListeners();
  }

  /// Cancel any in-flight strategy run.
  void cancel() {
    _cancelled = true;
  }

  /// Looks up [packageName] in the local hardcoded dictionary.
  /// Returns the package name itself if not found.
  String getLocalDictionaryLabel(String packageName) {
    return commonPackageNames[packageName] ?? packageName;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _runStrategy(List<String> packages, {required bool forceUpdate}) async {
    isLoading = true;
    notifyListeners();

    try {
      await _buildStrategy().fetchAll(
        packages: packages,
        labels: labels,
        batchSize: 10,
        forceUpdate: forceUpdate,
        isCancelled: () => _cancelled,
        onLabelDiscovered: (pkg, label) {
          labels[pkg] = label;
          notifyListeners();
        },
        onBatchDone: (partial) {
          for (final entry in partial.entries) {
            icons[entry.key] = entry.value ?? _sentinel;
          }
          progress = icons.values.where((v) => v != null).length;
          notifyListeners();
        },
      );
    } on UnimplementedError catch (e) {
      // Strategy not yet implemented — log and continue gracefully.
      // The UI already shows whatever was loaded from cache.
      debugPrint('[AppIconController] Strategy not implemented: $e');
    } catch (e) {
      debugPrint('[AppIconController] Strategy error: $e');
    }

    isLoading = false;
    notifyListeners();
  }
}
