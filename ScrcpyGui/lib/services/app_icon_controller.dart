/// App Icon Controller
///
/// ChangeNotifier that owns all icon/label state for the App Drawer and
/// Settings page. Single source of truth - no page calls AppIconCache or
/// strategies directly.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/package_names.dart';
import '../models/app_drawer_settings_model.dart';
import 'app_icon_cache.dart';
import 'icon_fetch_strategy.dart';
import 'settings_service.dart';
import 'strategies/adb_scrape_strategy.dart';
import 'strategies/helper_apk_strategy.dart';

class AppIconController extends ChangeNotifier {
  /// Icons keyed by package name.
  /// null = not yet attempted
  /// File('') = sentinel - attempted, no icon found
  /// File(path) = cached icon on disk
  final Map<String, File?> icons = {};

  /// Human-readable labels keyed by package name.
  /// Updated live as strategies discover names.
  final Map<String, String> labels = {};

  bool isLoading = false;
  int progress = 0;
  int total = 0;
  String progressStatus = '';
  String? currentDeviceId;
  AppDrawerSettings appDrawerSettings;

  static final File _sentinel = File('');

  bool _cancelled = false;
  bool _isRunning = false;

  AppIconController({AppDrawerSettings? appDrawerSettings})
    : appDrawerSettings = appDrawerSettings ?? AppDrawerSettings();

  IconFetchStrategy _buildStrategy({bool helperApkAutoInstall = false}) =>
      switch (appDrawerSettings.iconFetchMethod) {
        IconFetchMethod.adbScrape => const AdbScrapeStrategy(),
        IconFetchMethod.helperApk => HelperApkStrategy(
            autoInstall: helperApkAutoInstall,
          ),
      };

  /// Loads icons and labels for [packages] on [deviceId].
  Future<void> loadForDevice(String deviceId, List<String> packages) async {
    // If a strategy is in-flight, cancel it and reset the running flag so a
    // fresh fetch can start after this load completes.
    if (_isRunning) {
      _cancelled = true;
      _isRunning = false;
    }
    _cancelled = false;
    currentDeviceId = deviceId;
    total = packages.length;
    progress = 0;
    progressStatus = '';

    icons.clear();
    labels.clear();

    // Step 1: Labels from _labels.json.
    final cachedLabels = await AppIconCache.loadCachedLabels();
    for (final pkg in packages) {
      final cached = cachedLabels[pkg];
      labels[pkg] = (cached != null && cached.isNotEmpty) ? cached : pkg;
    }

    // Hydrate labels from local dictionary for any still using raw package names.
    for (final pkg in packages) {
      if (labels[pkg] == pkg) {
        final dictLabel = getLocalDictionaryLabel(pkg);
        if (dictLabel != pkg) labels[pkg] = dictLabel;
      }
    }

    isLoading = true;
    notifyListeners();

    // Step 2: Icons from disk cache (parallel).
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
        icons[entry.key] = null;
        uncached.add(entry.key);
      }
    }

    progress = packages.length - uncached.length;
    notifyListeners();

    // Step 3: Nothing uncached -> done.
    if (uncached.isEmpty) {
      isLoading = false;
      notifyListeners();
      return;
    }

    // Step 4: No cached icons found — leave icons as null and let the UI
    // prompt the user to choose a fetch method manually.
    isLoading = false;
    notifyListeners();
  }

  /// Re-fetches all packages using the active strategy, bypassing cache.
  Future<void> fetchMissing({
    bool forceUpdate = true,
    bool helperApkAutoInstall = false,
    void Function(String message)? onError,
  }) async {
    if (currentDeviceId == null || labels.isEmpty) return;
    _cancelled = false;
    final packages = labels.keys.toList();
    await _runStrategy(
      packages,
      forceUpdate: forceUpdate,
      helperApkAutoInstall: helperApkAutoInstall,
      onError: onError,
    );
  }

  /// Fetches only packages that are missing an icon or have no resolved label.
  /// A package is "missing" if:
  ///   - its icon is null or sentinel (File(''))
  ///   - its label still equals the raw package name
  Future<void> fetchMissingOnly({
    bool helperApkAutoInstall = false,
    void Function(String message)? onError,
  }) async {
    if (currentDeviceId == null || labels.isEmpty) return;
    _cancelled = false;

    final missing = labels.keys.where((pkg) {
      final hasIcon = icons[pkg] != null && icons[pkg]!.path.isNotEmpty;
      final hasLabel = labels[pkg] != pkg;
      return !hasIcon || !hasLabel;
    }).toList();

    if (missing.isEmpty) return;
    await _runStrategy(
      missing,
      forceUpdate: true,
      helperApkAutoInstall: helperApkAutoInstall,
      onError: onError,
    );
  }

  /// Clears disk cache and resets in-memory icon/label state.
  Future<void> clearCache() async {
    _cancelled = true;
    await AppIconCache.clearCache();
    _resetMemoryState();
  }

  /// Resets in-memory state without touching disk cache.
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
  String getLocalDictionaryLabel(String packageName) {
    return commonPackageNames[packageName] ?? packageName;
  }

  /// Persist the current app drawer settings to disk.
  Future<void> saveSettings() async {
    await SettingsService().saveAppDrawerSettings(appDrawerSettings);
    notifyListeners();
  }

  /// Toggle favorite status for a package.
  void toggleFavorite(String packageName) {
    if (appDrawerSettings.favorites.contains(packageName)) {
      appDrawerSettings.favorites.remove(packageName);
    } else {
      appDrawerSettings.favorites.add(packageName);
    }
    saveSettings();
  }

  /// Check if a package is favorited.
  bool isFavorite(String packageName) =>
      appDrawerSettings.favorites.contains(packageName);

  /// Toggle script as favorite.
  void toggleScriptFavorite(String scriptPath) {
    if (appDrawerSettings.favorites.contains(scriptPath)) {
      appDrawerSettings.favorites.remove(scriptPath);
    } else {
      appDrawerSettings.favorites.add(scriptPath);
    }
    saveSettings();
  }

  /// Check if a script is favorited.
  bool isScriptFavorite(String scriptPath) =>
      appDrawerSettings.favorites.contains(scriptPath);

  // Group management

  /// Create a new empty group with [name].
  void createGroup(String name) {
    appDrawerSettings.groups.add(AppGroup(name: name));
    saveSettings();
  }

  /// Rename group at [index] to [newName].
  void renameGroup(int index, String newName) {
    if (index < 0 || index >= appDrawerSettings.groups.length) return;
    appDrawerSettings.groups[index].name = newName;
    saveSettings();
  }

  /// Delete group at [index]. Apps in it become ungrouped.
  void deleteGroup(int index) {
    if (index < 0 || index >= appDrawerSettings.groups.length) return;
    appDrawerSettings.groups.removeAt(index);
    saveSettings();
  }

  /// Move group from [oldIndex] to [newIndex].
  void reorderGroup(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= appDrawerSettings.groups.length) return;
    if (newIndex < 0 || newIndex >= appDrawerSettings.groups.length) return;
    final group = appDrawerSettings.groups.removeAt(oldIndex);
    appDrawerSettings.groups.insert(newIndex, group);
    saveSettings();
  }

  /// Move [packageName] into the group at [groupIndex].
  /// Removes from any other group first.
  void moveToGroup(String packageName, int groupIndex) {
    if (groupIndex < 0 || groupIndex >= appDrawerSettings.groups.length) return;
    for (final group in appDrawerSettings.groups) {
      group.items.remove(packageName);
    }
    appDrawerSettings.groups[groupIndex].items.add(packageName);
    saveSettings();
  }

  /// Remove [packageName] from whichever group currently contains it.
  void removeFromGroup(String packageName) {
    for (final group in appDrawerSettings.groups) {
      group.items.remove(packageName);
    }
    saveSettings();
  }

  /// Returns the index of the group containing [packageName], or -1.
  int groupIndexOf(String packageName) {
    for (var i = 0; i < appDrawerSettings.groups.length; i++) {
      if (appDrawerSettings.groups[i].items.contains(packageName)) return i;
    }
    return -1;
  }

  void _autoCreateGroups(Map<String, String> categories) {
    final grouped = <String, List<String>>{};
    for (final entry in categories.entries) {
      if (labels.containsKey(entry.key)) {
        grouped.putIfAbsent(entry.value, () => []).add(entry.key);
      }
    }

    appDrawerSettings.groups.removeWhere((g) => g.isAutoGenerated);

    for (final entry in grouped.entries) {
      appDrawerSettings.groups.add(
        AppGroup(name: entry.key, items: entry.value, isAutoGenerated: true),
      );
    }

    saveSettings();
  }

  Future<void> _runStrategy(
    List<String> packages, {
    required bool forceUpdate,
    bool helperApkAutoInstall = false,
    void Function(String message)? onError,
  }) async {
    if (_isRunning) return;
    if (currentDeviceId == null) return;

    _isRunning = true;
    isLoading = true;
    notifyListeners();

    try {
      final strategy = _buildStrategy(helperApkAutoInstall: helperApkAutoInstall);

      await strategy.fetchAll(
        deviceId: currentDeviceId!,
        packages: packages,
        labels: labels,
        batchSize: 5,
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
        onCategoriesLoaded: (categories) {
          if (appDrawerSettings.autoGroupByCategory) {
            _autoCreateGroups(categories);
          }
        },
        onProgress: (current, total, status) {
          progress = current;
          this.total = total;
          progressStatus = status;
          notifyListeners();
        },
      );
    } on UnimplementedError catch (e) {
      stderr.writeln('[Controller._runStrategy] Strategy not implemented: $e');
      return;
    } catch (e, st) {
      stderr.writeln('[Controller._runStrategy] Strategy error: $e\n$st');
      onError?.call(e.toString());
      return;
    } finally {
      if (labels.isNotEmpty) {
        await AppIconCache.saveLabels(labels);
      }
      _isRunning = false;
      isLoading = false;
      notifyListeners();
    }
  }
}
