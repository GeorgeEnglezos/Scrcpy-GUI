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
  DeviceManagerService? deviceManagerService;

  /// Update audio options from the Audio Commands Panel
  ///
  /// [options] New audio options containing bitrate, codec, buffer, etc.
  ///
  /// Triggers [notifyListeners] to update the command display.
  void updateAudioOptions(AudioOptions options) {
    audioOptions = options;
    _log('Audio options updated: $audioOptions');
    notifyListeners();
  }

  /// Update recording options from the Recording Commands Panel
  ///
  /// [options] New recording options containing output file, format, bitrate, etc.
  ///
  /// Triggers [notifyListeners] to update the command display.
  /// Also affects window title generation (adds 'record-' prefix).
  void updateRecordingOptions(ScreenRecordingOptions options) {
    recordingOptions = options;
    _log('Recording options updated: $recordingOptions');
    notifyListeners();
  }

  /// Update virtual display options from the Virtual Display Commands Panel
  ///
  /// [options] New virtual display options containing resolution, DPI, decorations, etc.
  ///
  /// Triggers [notifyListeners] to update the command display.
  void updateVirtualDisplayOptions(VirtualDisplayOptions options) {
    virtualDisplayOptions = options;
    _log('Virtual display options updated: $virtualDisplayOptions');
    notifyListeners();
  }

  /// Update general cast options from the Common Commands Panel
  ///
  /// [options] New general options containing window settings, video codec, package, etc.
  ///
  /// Triggers [notifyListeners] to update the command display.
  void updateGeneralCastOptions(GeneralCastOptions options) {
    generalCastOptions = options;
    _log('General cast options updated: $generalCastOptions');
    notifyListeners();
  }

  /// Update camera options from the Camera Commands Panel
  ///
  /// [options] New camera options containing camera ID, size, facing, FPS, etc.
  ///
  /// Triggers [notifyListeners] to update the command display.
  void updateCameraOptions(CameraOptions options) {
    cameraOptions = options;
    _log('Camera options updated: $cameraOptions');
    notifyListeners();
  }

  /// Update input control options from the Input Control Panel
  ///
  /// [options] New input control options containing mouse, keyboard, paste settings, etc.
  ///
  /// Triggers [notifyListeners] to update the command display.
  void updateInputControlOptions(InputControlOptions options) {
    inputControlOptions = options;
    _log('Input control options updated: $inputControlOptions');
    notifyListeners();
  }

  /// Update display/window options from the Display/Window Configuration Panel
  ///
  /// [options] New display/window options containing position, size, rotation, etc.
  ///
  /// Triggers [notifyListeners] to update the command display.
  void updateDisplayWindowOptions(DisplayWindowOptions options) {
    displayWindowOptions = options;
    _log('Display/Window options updated: $displayWindowOptions');
    notifyListeners();
  }

  /// Update network/connection options from the Network/Connection Panel
  ///
  /// [options] New network options containing TCP/IP, tunnel, ADB forward settings, etc.
  ///
  /// Triggers [notifyListeners] to update the command display.
  void updateNetworkConnectionOptions(NetworkConnectionOptions options) {
    networkConnectionOptions = options;
    _log('Network/Connection options updated: $networkConnectionOptions');
    notifyListeners();
  }

  /// Update advanced options from the Advanced/Developer Panel
  ///
  /// [options] New advanced options containing verbosity, cleanup, V4L2 settings, etc.
  ///
  /// Triggers [notifyListeners] to update the command display.
  void updateAdvancedOptions(AdvancedOptions options) {
    advancedOptions = options;
    _log('Advanced options updated: $advancedOptions');
    notifyListeners();
  }

  /// Update OTG mode options from the OTG Mode Panel
  ///
  /// [options] New OTG options containing OTG, HID keyboard/mouse settings
  ///
  /// Triggers [notifyListeners] to update the command display.
  void updateOtgModeOptions(OtgModeOptions options) {
    otgModeOptions = options;
    _log('OTG mode options updated: $otgModeOptions');
    notifyListeners();
  }

  /// Generates the complete scrcpy command from all option groups
  ///
  /// Combines all command parts in the correct order:
  /// 1. Base command with error handling
  /// 2. Device serial (--serial flag for selected device)
  /// 3. Dynamic window title (includes recording prefix and package name)
  /// 4. General options (fullscreen, orientation, video codec, etc.)
  /// 5. Virtual display options
  /// 6. Recording options
  /// 7. Audio options
  ///
  /// Window title generation logic:
  /// - If recording: Prefixes with 'record-'
  /// - Uses custom window title if provided
  /// - Falls back to package name if selected
  /// - Defaults to "ScrcpyGui" if nothing else specified
  ///
  /// Returns the complete command string ready for execution
  ///
  /// Example output:
  /// ```
  /// scrcpy --pause-on-exit=if-error --serial=abc123 --window-title=record-MyApp
  /// --fullscreen --video-codec=h264 --record=output.mkv --audio-bitrate=128k
  /// ```
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
    final serialPart = deviceSerial != null ? '--serial=$deviceSerial' : '';

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

  /// Resets all options to their default values
  ///
  /// Called when switching away from the Home page to clear the command state.
  /// This ensures that the command builder starts fresh when returning to the Home page.
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
