/// Command Builder Service
///
/// Centralized service for constructing scrcpy commands from UI panel inputs.
/// Uses a modular architecture where each panel updates its respective option group.
///
/// Key Responsibilities:
/// - Maintain separate option objects for each command category
/// - Combine all options into a complete scrcpy command
/// - Generate dynamic window titles based on recording status and package
/// - Notify listeners when any option changes
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/scrcpy_options.dart';
import 'device_manager_service.dart';
import 'options_state_service.dart';

/// Service for building scrcpy commands from panel options
///
/// This service uses Provider's ChangeNotifier to broadcast command changes
/// to the UI in real-time as users modify options in different panels.
///
/// Architecture:
/// Each panel (Audio, Recording, Virtual Display, General) maintains its own
/// options object and calls the corresponding update method when changed.
/// The [fullCommand] getter assembles all options into a complete command string.
class CommandBuilderService extends ChangeNotifier {
  /// Base scrcpy command with error handling flag
  /// The .exe extension is optional on Windows (resolved via PATHEXT)
  String baseCommand = "scrcpy --pause-on-exit=if-error";

  /// All option objects in a single immutable bundle (backing store for persistence)
  OptionsBundle _options = const OptionsBundle();

  /// Single instance of the persistence service
  final OptionsStateService _stateService = OptionsStateService();

  // Getters that delegate to the bundle — panels read these directly.
  AudioOptions get audioOptions => _options.audioOptions;
  ScreenRecordingOptions get recordingOptions => _options.recordingOptions;
  VirtualDisplayOptions get virtualDisplayOptions => _options.virtualDisplayOptions;
  GeneralCastOptions get generalCastOptions => _options.generalCastOptions;
  CameraOptions get cameraOptions => _options.cameraOptions;
  InputControlOptions get inputControlOptions => _options.inputControlOptions;
  DisplayWindowOptions get displayWindowOptions => _options.displayWindowOptions;
  NetworkConnectionOptions get networkConnectionOptions => _options.networkConnectionOptions;
  AdvancedOptions get advancedOptions => _options.advancedOptions;
  OtgModeOptions get otgModeOptions => _options.otgModeOptions;

  /// Reference to DeviceManagerService to get selected device
  DeviceManagerService? _deviceManagerService;

  /// Gets the device manager service reference
  DeviceManagerService? get deviceManagerService => _deviceManagerService;

  /// Sets the device manager service and listens for device selection changes
  set deviceManagerService(DeviceManagerService? service) {
    // Remove old listener if exists
    _deviceManagerService?.removeListener(_onDeviceChanged);

    _deviceManagerService = service;

    // Add new listener if service is not null
    _deviceManagerService?.addListener(_onDeviceChanged);
  }

  /// Called when device selection changes in DeviceManagerService
  void _onDeviceChanged() {
    notifyListeners(); // Rebuild command when device changes
  }

  @override
  void dispose() {
    unawaited(flushPendingSave());
    _deviceManagerService?.removeListener(_onDeviceChanged);
    super.dispose();
  }

  void updateAudioOptions(AudioOptions options) {
    _options = _options.copyWith(audioOptions: options);
    _log('Audio options updated: $audioOptions');
    notifyListeners();
    _scheduleSave();
  }

  /// Also affects window title (adds 'record-' prefix)
  void updateRecordingOptions(ScreenRecordingOptions options) {
    _options = _options.copyWith(recordingOptions: options);
    _log('Recording options updated: $recordingOptions');
    notifyListeners();
    _scheduleSave();
  }

  void updateVirtualDisplayOptions(VirtualDisplayOptions options) {
    _options = _options.copyWith(virtualDisplayOptions: options);
    _log('Virtual display options updated: $virtualDisplayOptions');
    notifyListeners();
    _scheduleSave();
  }

  void updateGeneralCastOptions(GeneralCastOptions options) {
    _options = _options.copyWith(generalCastOptions: options);
    _log('General cast options updated: $generalCastOptions');
    notifyListeners();
    _scheduleSave();
  }

  void updateCameraOptions(CameraOptions options) {
    _options = _options.copyWith(cameraOptions: options);
    _log('Camera options updated: $cameraOptions');
    notifyListeners();
    _scheduleSave();
  }

  void updateInputControlOptions(InputControlOptions options) {
    _options = _options.copyWith(inputControlOptions: options);
    _log('Input control options updated: $inputControlOptions');
    notifyListeners();
    _scheduleSave();
  }

  void updateDisplayWindowOptions(DisplayWindowOptions options) {
    _options = _options.copyWith(displayWindowOptions: options);
    _log('Display/Window options updated: $displayWindowOptions');
    notifyListeners();
    _scheduleSave();
  }

  void updateNetworkConnectionOptions(NetworkConnectionOptions options) {
    _options = _options.copyWith(networkConnectionOptions: options);
    _log('Network/Connection options updated: $networkConnectionOptions');
    notifyListeners();
    _scheduleSave();
  }

  void updateAdvancedOptions(AdvancedOptions options) {
    _options = _options.copyWith(advancedOptions: options);
    _log('Advanced options updated: $advancedOptions');
    notifyListeners();
    _scheduleSave();
  }

  void updateOtgModeOptions(OtgModeOptions options) {
    _options = _options.copyWith(otgModeOptions: options);
    _log('OTG mode options updated: $otgModeOptions');
    notifyListeners();
    _scheduleSave();
  }

  /// Builds complete scrcpy command from all panels
  /// Window title: auto-prefixed with 'record-' when recording, defaults to "ScrcpyGui"
  String get fullCommand {
    final generalPart = generalCastOptions.generateCommandPart();
    final virtualPart = virtualDisplayOptions.generateCommandPart();
    final recordingPart = recordingOptions.generateCommandPart();
    final audioPart = audioOptions.generateCommandPart();
    final cameraPart = cameraOptions.generateCommandPart();
    final inputControlPart = inputControlOptions.generateCommandPart();
    final displayWindowPart = displayWindowOptions.generateCommandPart();
    final networkConnectionPart = networkConnectionOptions.generateCommandPart();
    final advancedPart = advancedOptions.generateCommandPart();
    final otgModePart = otgModeOptions.generateCommandPart();

    // Dynamic window-title including recording info
    String finalWindowTitle = "";
    String windowTitle = generalCastOptions.windowTitle;
    if (recordingOptions.outputFile.isNotEmpty) {
      finalWindowTitle = 'record-';
    }
    if (windowTitle.isEmpty && generalCastOptions.selectedPackage.isNotEmpty) {
      finalWindowTitle += generalCastOptions.selectedPackage;
    } else if (windowTitle.isNotEmpty) {
      finalWindowTitle += windowTitle;
    } else {
      finalWindowTitle += "ScrcpyGui";
    }
    final windowTitlePart = '--window-title=$finalWindowTitle';

    // Add device serial if selected
    final deviceSerial = deviceManagerService?.selectedDevice;
    final serialPart = (deviceSerial != null && deviceSerial.isNotEmpty)
        ? '--serial=$deviceSerial'
        : '';

    final parts = [
      baseCommand,
      serialPart,
      windowTitlePart,
      generalPart,
      cameraPart,
      inputControlPart,
      displayWindowPart,
      networkConnectionPart,
      virtualPart,
      recordingPart,
      audioPart,
      advancedPart,
      otgModePart,
    ];

    final cmd = parts.where((p) => p.isNotEmpty).join(' ').trim();
    _log('Full command rebuilt: $cmd');
    return cmd;
  }

  /// Reset all options to defaults
  void resetToDefaults() {
    _options = const OptionsBundle();
    _log('All options reset to defaults');
    notifyListeners();
    _scheduleSave();
  }

  // --- Persistence ---

  Timer? _saveTimer;

  /// Serialize all 10 option objects to a single JSON map.
  Map<String, dynamic> optionsToJson() => _options.toJson();

  /// Restore all 10 option objects from a JSON map.
  /// Recording state is cleared since it's session-specific (stale filenames).
  void loadOptionsFromJson(Map<String, dynamic> json) {
    try {
      _options = OptionsBundle.fromJson(json);
      // Clear recording state — outputFile contains a session-specific timestamp
      _options = _options.copyWith(recordingOptions: const ScreenRecordingOptions());
      _log('Options loaded from JSON');
    } catch (e) {
      _log('Error deserializing options, falling back to defaults: $e');
      _options = const OptionsBundle();
    }
    notifyListeners();
  }

  /// Schedule a debounced save to avoid excessive disk writes.
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 4000), () {
      _stateService.saveOptionsState(optionsToJson());
    });
  }

  /// Flush any pending save immediately (used on app close).
  Future<void> flushPendingSave() async {
		if (_saveTimer != null){
    	_saveTimer?.cancel();
    	await _stateService.saveOptionsState(optionsToJson());
		}
  }

  /// Internal logging helper for debugging
  void _log(String message) {
    debugPrint('[CommandBuilderService] $message');
  }
}
