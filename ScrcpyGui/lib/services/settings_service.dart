import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/app_drawer_settings_model.dart';
import '../models/settings_model.dart';
import 'log_service.dart';

class SettingsService {
  static AppSettings? _cachedSettings; // Cache settings in memory
  static AppDrawerSettings? _cachedAppDrawerSettings;

  static AppSettings? get currentSettings => _cachedSettings;
  static AppDrawerSettings? get currentAppDrawerSettings => _cachedAppDrawerSettings;

  final String _settingsFileName = 'scrcpy_gui_settings.json';
  final String _appDrawerSettingsFileName = 'app_drawer_settings.json';

  /// Load settings from disk
  Future<AppSettings> loadSettings() async {
    if (_cachedSettings != null) return _cachedSettings!;

    final settingsDir = await getSettingsDirectory();
    final settingsFile = File(p.join(settingsDir, _settingsFileName));

    if (await settingsFile.exists()) {
      final jsonString = await settingsFile.readAsString();
      _cachedSettings = AppSettings.fromJsonString(jsonString); // Cache it

      // Migration: Add any missing panels from defaultPanels
      _migratePanels(_cachedSettings!);

      // Save migrated settings
      await saveSettings(_cachedSettings!);
    } else {
      _cachedSettings =
          AppSettings.defaultSettings(); // <-- use default factory
      await saveSettings(_cachedSettings!);
    }

    return _cachedSettings!;
  }

  /// Migrate settings by adding any new panels that don't exist in saved settings
  void _migratePanels(AppSettings settings) {
    // Remove deprecated panels (e.g., shortcuts panel)
    final deprecatedPanelIds = {'shortcuts'};
    settings.panelOrder.removeWhere((panel) => deprecatedPanelIds.contains(panel.id));

    // Find panels in defaultPanels that aren't in the saved settings
    final currentIds = settings.panelOrder.map((p) => p.id).toSet();
    final missingPanels = defaultPanels
        .where((panel) => !currentIds.contains(panel.id))
        .toList();

    if (missingPanels.isNotEmpty) {
      // Add missing panels to the end of the panel order
      settings.panelOrder.addAll(missingPanels);
    }
  }

  /// Save settings to disk
  Future<bool> saveSettings(AppSettings settings) async {
    try {
      final settingsDir = await getSettingsDirectory();
      final settingsFile = File(p.join(settingsDir, _settingsFileName));

      if (!await settingsFile.exists()) {
        await settingsFile.create(recursive: true);
      }

      await settingsFile.writeAsString(settings.toJsonString());
      _cachedSettings = settings; // Update cache
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
      // Reset panel order to defaults while preserving other settings
      _cachedSettings!.panelOrder = List.from(defaultPanels);
      await saveSettings(_cachedSettings!);
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

    // Reset cache to default settings
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

  /// Save app drawer settings to disk
  Future<bool> saveAppDrawerSettings(AppDrawerSettings settings) async {
    try {
      final settingsDir = await getSettingsDirectory();
      final file = File(p.join(settingsDir, _appDrawerSettingsFileName));

      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      await file.writeAsString(settings.toJsonString());
      _cachedAppDrawerSettings = settings;
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
