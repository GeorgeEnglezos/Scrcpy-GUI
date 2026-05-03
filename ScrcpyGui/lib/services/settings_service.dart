import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/app_drawer_settings_model.dart';
import '../models/settings_model.dart';
import 'log_service.dart';

/// Internal notifier — exposed externally only as [Listenable] so callers
/// must use addListener/removeListener and cannot call [notifyListeners]
/// directly.
class _ScopedNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class SettingsService {
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  SettingsService._();

  static AppSettings? _cachedSettings;
  static AppDrawerSettings? _cachedAppDrawerSettings;

  static AppSettings? get currentSettings => _cachedSettings;
  static AppDrawerSettings? get currentAppDrawerSettings => _cachedAppDrawerSettings;

  /// Fires when [AppSettings] is persisted. Subscribe to be notified of
  /// changes that affect the app shell (boot tab, panel order, scrcpy
  /// directory, shortcut mod, etc.). App-drawer-only changes do NOT fire
  /// this notifier.
  final _ScopedNotifier _appSettingsNotifier = _ScopedNotifier();
  Listenable get appSettingsNotifier => _appSettingsNotifier;

  /// Fires when [AppDrawerSettings] is persisted. Subscribe for app-drawer
  /// state (favorites, groups, icon fetch method, etc.). [AppSettings]
  /// changes do NOT fire this notifier.
  final _ScopedNotifier _appDrawerNotifier = _ScopedNotifier();
  Listenable get appDrawerNotifier => _appDrawerNotifier;

  final String _settingsFileName = 'scrcpy_gui_settings.json';
  final String _appDrawerSettingsFileName = 'app_drawer_settings.json';

  /// Load settings from disk
  Future<AppSettings> loadSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    final settingsDir = await getSettingsDirectory();
    final settingsFile = File(p.join(settingsDir, _settingsFileName));

    if (await settingsFile.exists()) {
      final jsonString = await settingsFile.readAsString();
      final loaded = AppSettings.fromJsonString(jsonString);

      // Migration: drop deprecated panels and add any newly-introduced ones.
      final migrated = _migratePanels(loaded);
      _cachedSettings = migrated;

      // Persist only if migration actually produced a different list, to
      // avoid a useless write (and listener fire) on every cold start.
      if (!_panelOrderEquals(loaded.panelOrder, migrated.panelOrder)) {
        await saveSettings(migrated);
      }
    } else {
      _cachedSettings = AppSettings.defaultSettings();
      await saveSettings(_cachedSettings!);
    }

    return _cachedSettings!;
  }

  /// Returns a copy of [settings] with deprecated panels removed and any
  /// newly-introduced default panels appended. Pure: never mutates input.
  AppSettings _migratePanels(AppSettings settings) {
    const deprecatedPanelIds = {'shortcuts'};
    final defaults = buildDefaultPanels();

    final retained = settings.panelOrder
        .where((panel) => !deprecatedPanelIds.contains(panel.id))
        .toList();

    final currentIds = retained.map((p) => p.id).toSet();
    final missing =
        defaults.where((panel) => !currentIds.contains(panel.id)).toList();

    if (missing.isEmpty) {
      // Length unchanged AND no deprecated entries removed → no change at all.
      if (retained.length == settings.panelOrder.length) return settings;
    }

    return settings.copyWith(panelOrder: [...retained, ...missing]);
  }

  bool _panelOrderEquals(List<PanelSettings> a, List<PanelSettings> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  /// Save settings to disk.
  ///
  /// The in-memory cache is updated synchronously (before the first await) so
  /// that any code that reads [currentSettings] right after kicking off this
  /// save sees the new value, even if persistence is still in flight.
  Future<bool> saveSettings(AppSettings settings) async {
    _cachedSettings = settings;
    try {
      final settingsDir = await getSettingsDirectory();
      final settingsFile = File(p.join(settingsDir, _settingsFileName));

      if (!await settingsFile.exists()) {
        await settingsFile.create(recursive: true);
      }

      await settingsFile.writeAsString(settings.toJsonString());
      _appSettingsNotifier.notify();
      return true;
    } catch (e) {
      LogService.error('SettingsService/saveSettings', 'Failed to save settings', err: e);
      return false;
    }
  }

  /// Returns the app settings directory
  Future<String> getSettingsDirectory() async {
    String dir;
    if (Platform.isWindows) {
      dir = Platform.environment['APPDATA'] ?? '.';
    } else if (Platform.isMacOS) {
      dir = '${Platform.environment['HOME']}/Library/Application Support';
    } else {
      dir = Platform.environment['HOME'] ?? '.';
    }
    final fullDir = p.join(dir, 'ScrcpyGui');
    final directory = Directory(fullDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return fullDir;
  }

  /// Reset only User Interface settings (panel order and properties)
  Future<void> resetUserInterface() async {
    if (_cachedSettings != null) {
      await saveSettings(
        _cachedSettings!.copyWith(panelOrder: buildDefaultPanels()),
      );
    }
  }

  /// Reset all settings to defaults
  Future<void> resetAllSettings() async {
    final settingsDir = await getSettingsDirectory();
    final settingsFile = File(p.join(settingsDir, _settingsFileName));

    // Delete the settings file
    if (await settingsFile.exists()) {
      await settingsFile.delete();
    }

    _cachedSettings = AppSettings.defaultSettings();
    await saveSettings(_cachedSettings!);
    await resetAppDrawerSettings();
  }

  // ── App Drawer Settings ─────────────────────────────────────────────────

  /// Load app drawer settings from disk
  Future<AppDrawerSettings> loadAppDrawerSettings() async {
    if (_cachedAppDrawerSettings != null) return _cachedAppDrawerSettings!;

    final settingsDir = await getSettingsDirectory();
    final file = File(p.join(settingsDir, _appDrawerSettingsFileName));

    if (await file.exists()) {
      final jsonString = await file.readAsString();
      _cachedAppDrawerSettings = AppDrawerSettings.fromJsonString(jsonString);
    } else {
      _cachedAppDrawerSettings = AppDrawerSettings();
      await saveAppDrawerSettings(_cachedAppDrawerSettings!);
    }

    return _cachedAppDrawerSettings!;
  }

  /// Save app drawer settings to disk.
  ///
  /// The in-memory cache is updated synchronously (before the first await) so
  /// that any code that reads [currentAppDrawerSettings] right after kicking
  /// off this save sees the new value, even if persistence is still in flight.
  /// Without this, a fire-and-forget save followed by an immediate consumer
  /// read would observe the stale persisted value.
  Future<bool> saveAppDrawerSettings(AppDrawerSettings settings) async {
    _cachedAppDrawerSettings = settings;
    try {
      final settingsDir = await getSettingsDirectory();
      final file = File(p.join(settingsDir, _appDrawerSettingsFileName));

      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      await file.writeAsString(settings.toJsonString());
      _appDrawerNotifier.notify();
      return true;
    } catch (e) {
      LogService.error('SettingsService/saveAppDrawerSettings', 'Failed to save app drawer settings', err: e);
      return false;
    }
  }

  /// Reset app drawer settings to defaults
  Future<void> resetAppDrawerSettings() async {
    final settingsDir = await getSettingsDirectory();
    final file = File(p.join(settingsDir, _appDrawerSettingsFileName));

    if (await file.exists()) {
      await file.delete();
    }

    _cachedAppDrawerSettings = AppDrawerSettings();
    await saveAppDrawerSettings(_cachedAppDrawerSettings!);
  }
}
