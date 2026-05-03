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
import 'log_service.dart';
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

  /// Persist the current app drawer settings to disk and notify listeners.
  /// Most callers should use one of the higher-level mutators which wrap
  /// this; only call directly when you've already updated [appDrawerSettings]
  /// some other way.
  Future<void> saveSettings() async {
    await SettingsService().saveAppDrawerSettings(appDrawerSettings);
    notifyListeners();
  }

  /// Replace [appDrawerSettings] with [next] and persist. Centralizes the
  /// "mutate via copyWith → save → notify" pattern.
  void _applySettings(AppDrawerSettings next) {
    appDrawerSettings = next;
    saveSettings();
  }

  // ── App-drawer-wide setters (replace direct page mutations) ──────────────

  void setAppLaunchCommand(String command) =>
      _applySettings(appDrawerSettings.copyWith(appLaunchCommand: command));

  void setIconFetchMethod(IconFetchMethod method) =>
      _applySettings(appDrawerSettings.copyWith(iconFetchMethod: method));

  void setAutoGroupByCategory(bool value) =>
      _applySettings(appDrawerSettings.copyWith(autoGroupByCategory: value));

  void setShowScripts(bool value) =>
      _applySettings(appDrawerSettings.copyWith(showScripts: value));

  void setIncludeSystemApps(bool value) =>
      _applySettings(appDrawerSettings.copyWith(includeSystemApps: value));

  void toggleScriptsCollapsed() => _applySettings(
        appDrawerSettings.copyWith(
          scriptsCollapsed: !appDrawerSettings.scriptsCollapsed,
        ),
      );

  void toggleOtherCollapsed() => _applySettings(
        appDrawerSettings.copyWith(
          otherCollapsed: !appDrawerSettings.otherCollapsed,
        ),
      );

  /// Toggle the collapsed state of the group at [index].
  void toggleGroupCollapsed(int index) {
    if (index < 0 || index >= appDrawerSettings.groups.length) return;
    final updated = [...appDrawerSettings.groups];
    final group = updated[index];
    updated[index] = group.copyWith(collapsed: !group.collapsed);
    _applySettings(appDrawerSettings.copyWith(groups: updated));
  }

  // ── Favorites ────────────────────────────────────────────────────────────

  /// Toggle favorite status for a package.
  void toggleFavorite(String packageName) {
    final favorites = appDrawerSettings.favorites.contains(packageName)
        ? appDrawerSettings.favorites.where((p) => p != packageName).toList()
        : [...appDrawerSettings.favorites, packageName];
    _applySettings(appDrawerSettings.copyWith(favorites: favorites));
  }

  /// Check if a package is favorited.
  bool isFavorite(String packageName) =>
      appDrawerSettings.favorites.contains(packageName);

  /// Toggle script as favorite. Same backing list as [toggleFavorite] —
  /// kept separate for symmetry with [isScriptFavorite].
  void toggleScriptFavorite(String scriptPath) => toggleFavorite(scriptPath);

  /// Check if a script is favorited.
  bool isScriptFavorite(String scriptPath) =>
      appDrawerSettings.favorites.contains(scriptPath);

  // ── Group management ─────────────────────────────────────────────────────

  /// Create a new empty group with [name].
  void createGroup(String name) {
    final groups = [...appDrawerSettings.groups, AppGroup(name: name)];
    _applySettings(appDrawerSettings.copyWith(groups: groups));
  }

  /// Rename group at [index] to [newName].
  void renameGroup(int index, String newName) {
    if (index < 0 || index >= appDrawerSettings.groups.length) return;
    final groups = [...appDrawerSettings.groups];
    groups[index] = groups[index].copyWith(name: newName);
    _applySettings(appDrawerSettings.copyWith(groups: groups));
  }

  /// Delete group at [index]. Apps in it become ungrouped.
  void deleteGroup(int index) {
    if (index < 0 || index >= appDrawerSettings.groups.length) return;
    final groups = [...appDrawerSettings.groups]..removeAt(index);
    _applySettings(appDrawerSettings.copyWith(groups: groups));
  }

  /// Move group from [oldIndex] to [newIndex].
  void reorderGroup(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= appDrawerSettings.groups.length) return;
    if (newIndex < 0 || newIndex >= appDrawerSettings.groups.length) return;
    final groups = [...appDrawerSettings.groups];
    final group = groups.removeAt(oldIndex);
    groups.insert(newIndex, group);
    _applySettings(appDrawerSettings.copyWith(groups: groups));
  }

  /// Move [packageName] into the group at [groupIndex].
  /// Removes from any other group first.
  void moveToGroup(String packageName, int groupIndex) {
    if (groupIndex < 0 || groupIndex >= appDrawerSettings.groups.length) return;
    final groups = [
      for (final g in appDrawerSettings.groups)
        g.copyWith(items: g.items.where((p) => p != packageName).toList()),
    ];
    final target = groups[groupIndex];
    groups[groupIndex] = target.copyWith(items: [...target.items, packageName]);
    _applySettings(appDrawerSettings.copyWith(groups: groups));
  }

  /// Remove [packageName] from whichever group currently contains it.
  void removeFromGroup(String packageName) {
    final groups = [
      for (final g in appDrawerSettings.groups)
        g.copyWith(items: g.items.where((p) => p != packageName).toList()),
    ];
    _applySettings(appDrawerSettings.copyWith(groups: groups));
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

    final retained =
        appDrawerSettings.groups.where((g) => !g.isAutoGenerated).toList();
    final autoGenerated = [
      for (final entry in grouped.entries)
        AppGroup(
          name: entry.key,
          items: entry.value,
          isAutoGenerated: true,
        ),
    ];
    _applySettings(
      appDrawerSettings.copyWith(groups: [...retained, ...autoGenerated]),
    );
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
      LogService.error('AppIconController/_runStrategy', 'Strategy not implemented', err: e);
      return;
    } catch (e, st) {
      LogService.error('AppIconController/_runStrategy', 'Strategy error', err: '$e\n$st');
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
