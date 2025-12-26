import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/settings_model.dart';

class SettingsService {
  static AppSettings? _cachedSettings; // Cache settings in memory

  static AppSettings? get currentSettings => _cachedSettings;

  final String _settingsFileName = 'scrcpy_gui_settings.json';

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
    final existingIds = settings.panelOrder.map((p) => p.id).toSet();

    // Remove deprecated panels (e.g., shortcuts panel)
    final deprecatedPanelIds = {'shortcuts'};
    settings.panelOrder.removeWhere((panel) => deprecatedPanelIds.contains(panel.id));

    if (deprecatedPanelIds.any((id) => existingIds.contains(id))) {
      debugPrint('Settings migration: Removed deprecated panels: ${deprecatedPanelIds.where((id) => existingIds.contains(id)).join(", ")}');
    }

    // Find panels in defaultPanels that aren't in the saved settings
    final currentIds = settings.panelOrder.map((p) => p.id).toSet();
    final missingPanels = defaultPanels
        .where((panel) => !currentIds.contains(panel.id))
        .toList();

    if (missingPanels.isNotEmpty) {
      // Add missing panels to the end of the panel order
      settings.panelOrder.addAll(missingPanels);
      debugPrint('Settings migration: Added ${missingPanels.length} new panels');
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
      stderr.writeln('Failed to save settings: $e');
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
  }
}
