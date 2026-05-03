import 'package:flutter/foundation.dart';

import '../models/scrcpy_command.dart';
import 'device_manager_service.dart';
import 'settings_service.dart';
import 'terminal_service.dart';

/// Central state holder for the in-progress scrcpy command.
///
/// Owns the current [ScrcpyCommand] and exposes [fullCommand] — the fully
/// assembled CLI string including base executable, selected device serial,
/// window title, shortcut modifier, and all flag arguments.
///
/// Reactive to two external sources: the active device (via the optional
/// [DeviceManagerService] hook) and `shortcutMod` from [SettingsService].
/// Listeners are notified whenever any of these change.
class CommandNotifier extends ChangeNotifier {
  /// Builds the notifier and starts listening to [settingsService] (or the
  /// default singleton) so that [fullCommand] updates reactively when
  /// settings fields it depends on (currently `shortcutMod`) change.
  CommandNotifier({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService() {
    _lastShortcutMod = SettingsService.currentSettings?.shortcutMod ?? const [];
    _settingsService.appSettingsNotifier.addListener(_onAppSettingsChanged);
  }

  ScrcpyCommand _current = ScrcpyCommand.empty();
  ScrcpyCommand get current => _current;

  final SettingsService _settingsService;
  List<String> _lastShortcutMod = const [];

  DeviceManagerService? _deviceManager;

  void setDeviceManager(DeviceManagerService service) {
    _deviceManager?.removeListener(_onDeviceChanged);
    _deviceManager = service;
    _deviceManager?.addListener(_onDeviceChanged);
  }

  void _onDeviceChanged() => notifyListeners();

  /// Re-emits when [AppSettings] fields that affect [fullCommand] change.
  /// Today that's only `shortcutMod`. If more settings start influencing
  /// the command string, extend the diff here.
  void _onAppSettingsChanged() {
    final next = SettingsService.currentSettings?.shortcutMod ?? const [];
    if (!_shortcutModEquals(next, _lastShortcutMod)) {
      _lastShortcutMod = List.unmodifiable(next);
      notifyListeners();
    }
  }

  static bool _shortcutModEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void update(ScrcpyCommand command) {
    _current = command;
    notifyListeners();
  }

  void reset() {
    _current = ScrcpyCommand.empty();
    notifyListeners();
  }

  void loadDefault() {
    final preset = SettingsService.currentSettings?.defaultPreset;
    if (preset != null) {
      _current = preset;
      notifyListeners();
    }
  }

  /// Persist the current command as the default preset. Returns true on
  /// successful disk write, false otherwise. Builds a new settings instance
  /// — never mutates the cached settings before persistence succeeds.
  Future<bool> saveDefault() async {
    final settings = SettingsService.currentSettings;
    if (settings == null) return false;
    return SettingsService().saveSettings(
      settings.copyWith(defaultPreset: _current),
    );
  }

  /// Full command string including base, serial, window title, and shortcut mod.
  String get fullCommand {
    final base = '${TerminalService.scrcpyExecutable} --pause-on-exit=if-error';
    final serial = _deviceManager?.selectedDevice;
    final serialPart =
        (serial != null && serial.isNotEmpty) ? '--serial=$serial' : '';

    String finalWindowTitle = '';
    if (_current.outputFile.isNotEmpty) finalWindowTitle = 'record-';
    if (_current.windowTitle.isEmpty && _current.selectedPackage.isNotEmpty) {
      finalWindowTitle += _current.selectedPackage;
    } else if (_current.windowTitle.isNotEmpty) {
      finalWindowTitle += _current.windowTitle;
    } else {
      finalWindowTitle += 'ScrcpyGui';
    }
    final escaped = finalWindowTitle.replaceAll('"', '\\"');
    final windowTitlePart = finalWindowTitle.contains(' ')
        ? '--window-title="$escaped"'
        : '--window-title=$escaped';

    final shortcutMod = SettingsService.currentSettings?.shortcutMod ?? [];
    final shortcutPart = shortcutMod.isNotEmpty
        ? '--shortcut-mod=${shortcutMod.join(',')}'
        : '';

    final parts = [
      base,
      serialPart,
      windowTitlePart,
      shortcutPart,
      _current.toCliString(),
    ];
    return parts.where((p) => p.isNotEmpty).join(' ').trim();
  }

  String get displayCommand => TerminalService.toDisplayCommand(fullCommand);

  @override
  void dispose() {
    _settingsService.appSettingsNotifier.removeListener(_onAppSettingsChanged);
    _deviceManager?.removeListener(_onDeviceChanged);
    super.dispose();
  }
}
