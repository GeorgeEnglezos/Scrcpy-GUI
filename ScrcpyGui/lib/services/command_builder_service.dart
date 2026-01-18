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

import 'package:flutter/foundation.dart';
import '../models/scrcpy_options.dart';
import 'device_manager_service.dart';

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

  /// Audio configuration options (bitrate, codec, buffer, etc.)
  AudioOptions audioOptions = AudioOptions();

  /// Screen recording options (output file, format, bitrate, etc.)
  ScreenRecordingOptions recordingOptions = ScreenRecordingOptions();

  /// Virtual display options (resolution, DPI, decorations, etc.)
  VirtualDisplayOptions virtualDisplayOptions = VirtualDisplayOptions();

  /// General casting options (fullscreen, orientation, video codec, package, etc.)
  GeneralCastOptions generalCastOptions = GeneralCastOptions();

  /// Camera options (camera ID, size, facing, FPS, aspect ratio, etc.)
  CameraOptions cameraOptions = CameraOptions();

  /// Input control options (mouse, keyboard, paste behavior, etc.)
  InputControlOptions inputControlOptions = InputControlOptions();

  /// Display/Window configuration options (position, size, rotation, render driver, etc.)
  DisplayWindowOptions displayWindowOptions = DisplayWindowOptions();

  /// Network/Connection options (TCP/IP, tunneling, ADB forward, etc.)
  NetworkConnectionOptions networkConnectionOptions = NetworkConnectionOptions();


  /// Advanced/Developer options (verbosity, cleanup, V4L2, etc.)
  AdvancedOptions advancedOptions = AdvancedOptions();

  /// OTG Mode options (OTG, HID keyboard/mouse)
  OtgModeOptions otgModeOptions = OtgModeOptions();

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
    // Clean up listener
    _deviceManagerService?.removeListener(_onDeviceChanged);
    super.dispose();
  }

  void updateAudioOptions(AudioOptions options) {
    audioOptions = options;
    _log('Audio options updated: $audioOptions');
    notifyListeners();
  }

  /// Also affects window title (adds 'record-' prefix)
  void updateRecordingOptions(ScreenRecordingOptions options) {
    recordingOptions = options;
    _log('Recording options updated: $recordingOptions');
    notifyListeners();
  }

  void updateVirtualDisplayOptions(VirtualDisplayOptions options) {
    virtualDisplayOptions = options;
    _log('Virtual display options updated: $virtualDisplayOptions');
    notifyListeners();
  }

  void updateGeneralCastOptions(GeneralCastOptions options) {
    generalCastOptions = options;
    _log('General cast options updated: $generalCastOptions');
    notifyListeners();
  }

  void updateCameraOptions(CameraOptions options) {
    cameraOptions = options;
    _log('Camera options updated: $cameraOptions');
    notifyListeners();
  }

  void updateInputControlOptions(InputControlOptions options) {
    inputControlOptions = options;
    _log('Input control options updated: $inputControlOptions');
    notifyListeners();
  }

  void updateDisplayWindowOptions(DisplayWindowOptions options) {
    displayWindowOptions = options;
    _log('Display/Window options updated: $displayWindowOptions');
    notifyListeners();
  }

  void updateNetworkConnectionOptions(NetworkConnectionOptions options) {
    networkConnectionOptions = options;
    _log('Network/Connection options updated: $networkConnectionOptions');
    notifyListeners();
  }

  void updateAdvancedOptions(AdvancedOptions options) {
    advancedOptions = options;
    _log('Advanced options updated: $advancedOptions');
    notifyListeners();
  }

  void updateOtgModeOptions(OtgModeOptions options) {
    otgModeOptions = options;
    _log('OTG mode options updated: $otgModeOptions');
    notifyListeners();
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
    audioOptions = AudioOptions();
    recordingOptions = ScreenRecordingOptions();
    virtualDisplayOptions = VirtualDisplayOptions();
    generalCastOptions = GeneralCastOptions();
    cameraOptions = CameraOptions();
    inputControlOptions = InputControlOptions();
    displayWindowOptions = DisplayWindowOptions();
    networkConnectionOptions = NetworkConnectionOptions();
    advancedOptions = AdvancedOptions();
    otgModeOptions = OtgModeOptions();
    _log('All options reset to defaults');
    notifyListeners();
  }

  /// Internal logging helper for debugging
  void _log(String message) {
    debugPrint('[CommandBuilderService] $message');
  }
}
