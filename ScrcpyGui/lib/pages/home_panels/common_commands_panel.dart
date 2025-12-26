/// General settings panel for commonly used scrcpy command options.
///
/// This panel provides the most frequently used scrcpy settings including
/// window configuration, screen behavior, video encoding, and general options.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../services/device_manager_service.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

/// Panel for configuring general and commonly used scrcpy options.
///
/// The [CommonCommandsPanel] provides access to the most frequently used settings:
/// - Window configuration (title, fullscreen, borderless, always on top)
/// - Screen behavior (screen off, stay awake, screensaver)
/// - Display settings (crop, orientation)
/// - Video encoding (bit rate, codec selection)
/// - Session options (time limit, power off on close, FPS display)
/// - Extra parameters for advanced customization
///
/// The panel loads device-specific video codecs and updates when device selection changes.
class CommonCommandsPanel extends StatefulWidget {
  /// Creates a common commands panel.
  const CommonCommandsPanel({super.key, this.clearController});

  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

  @override
  State<CommonCommandsPanel> createState() => _CommonCommandsPanelState();
}

class _CommonCommandsPanelState extends State<CommonCommandsPanel> {
  String windowTitle = '';
  bool fullscreen = false;
  bool screenOff = false;
  bool stayAwake = false;
  String cropScreen = '';
  String? videoOrientation;
  bool windowBorderless = false;
  bool windowAlwaysOnTop = false;
  bool disableScreensaver = false;
  String videoBitRate = '';
  String videoCodec = '';
  String extraParameters = '';
  bool printFps = false;
  String timeLimit = '';
  bool powerOffOnClose = false;

  List<String> videoCodecOptions = [];
  final List<String> orientationOptions = ['0', '90', '180', '270'];

  DeviceManagerService? _deviceManager;

  @override
  void initState() {
    super.initState();
    _loadVideoCodecs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceManager = Provider.of<DeviceManagerService>(
        context,
        listen: false,
      );
      _deviceManager?.selectedDeviceNotifier.addListener(_onDeviceChanged);
    });
  }

  void _onDeviceChanged() => _loadVideoCodecs();

  Future<void> _loadVideoCodecs() async {
    final deviceManager = Provider.of<DeviceManagerService>(
      context,
      listen: false,
    );
    final deviceId = deviceManager.selectedDevice;

    if (deviceId == null) {
      setState(() {
        videoCodecOptions = [];
        videoCodec = '';
      });
      return;
    }

    final info = DeviceManagerService.devicesInfo[deviceId];
    if (info != null) {
      setState(() {
        videoCodecOptions = info.videoCodecs;
        if (!videoCodecOptions.contains(videoCodec)) {
          videoCodec = '';
        }
      });
    } else {
      setState(() {
        videoCodecOptions = [];
        videoCodec = '';
      });
    }
  }

  void _updateService(BuildContext context) {
    final cmdService = Provider.of<CommandBuilderService>(
      context,
      listen: false,
    );

    final options = cmdService.generalCastOptions.copyWith(
      fullscreen: fullscreen,
      turnScreenOff: screenOff,
      stayAwake: stayAwake,
      windowTitle: windowTitle,
      crop: cropScreen,
      videoOrientation: videoOrientation ?? '',
      windowBorderless: windowBorderless,
      windowAlwaysOnTop: windowAlwaysOnTop,
      disableScreensaver: disableScreensaver,
      videoBitRate: videoBitRate,
      videoCodecEncoderPair: videoCodec,
      extraParameters: extraParameters,
      printFps: printFps,
      timeLimit: timeLimit,
      powerOffOnClose: powerOffOnClose,
    );

    cmdService.updateGeneralCastOptions(options);

    debugPrint(
      '[CommonPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}',
    );
  }

  void _clearAllFields() {
    setState(() {
      windowTitle = '';
      fullscreen = false;
      screenOff = false;
      stayAwake = false;
      cropScreen = '';
      videoOrientation = null;
      windowBorderless = false;
      windowAlwaysOnTop = false;
      disableScreensaver = false;
      videoBitRate = '';
      videoCodec = '';
      extraParameters = '';
      printFps = false;
      timeLimit = '';
      powerOffOnClose = false;
    });
    _updateService(context);
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDevices = videoCodecOptions.isNotEmpty;

    return SurroundingPanel(
      icon: Icons.desktop_windows,
      title: 'General',
      showButton: true,
      panelType: "General",
      onClearPressed: _clearAllFields,
      clearController: widget.clearController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Window Title',
                  value: windowTitle,
                  onChanged: (val) {
                    setState(() => windowTitle = val);
                    _updateService(context);
                  },
                  tooltip: 'Set a custom window title.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Fullscreen',
                  value: fullscreen,
                  onChanged: (val) {
                    setState(() => fullscreen = val);
                    _updateService(context);
                  },
                  tooltip: 'Start in fullscreen.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Screen off',
                  value: screenOff,
                  onChanged: (val) {
                    setState(() => screenOff = val);
                    _updateService(context);
                  },
                  tooltip: 'Turn the device screen off immediately.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomCheckbox(
                  label: 'Stay Awake',
                  value: stayAwake,
                  onChanged: (val) {
                    setState(() => stayAwake = val);
                    _updateService(context);
                  },
                  tooltip: 'Keep the device on while scrcpy is running, when the device is plugged in.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Crop Screen (W:H:X:Y)',
                  value: cropScreen,
                  onChanged: (val) {
                    setState(() => cropScreen = val);
                    _updateService(context);
                  },
                  tooltip: 'Crop the device screen on the server. The values are expressed in the device natural orientation (typically, portrait for a phone, landscape for a tablet).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: "Orientation",
                  value: videoOrientation,
                  suggestions: orientationOptions,
                  onChanged: (val) {
                    setState(() => videoOrientation = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => videoOrientation = '');
                    _updateService(context);
                  },
                  tooltip: 'Set the initial display orientation. The number represents the clockwise rotation in degrees. Default is 0.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomCheckbox(
                  label: 'Window Borderless',
                  value: windowBorderless,
                  onChanged: (val) {
                    setState(() => windowBorderless = val);
                    _updateService(context);
                  },
                  tooltip: 'Disable window decorations (display borderless window).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Window Always on Top',
                  value: windowAlwaysOnTop,
                  onChanged: (val) {
                    setState(() => windowAlwaysOnTop = val);
                    _updateService(context);
                  },
                  tooltip: 'Make scrcpy window always on top (above other windows).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Disable Screensaver',
                  value: disableScreensaver,
                  onChanged: (val) {
                    setState(() => disableScreensaver = val);
                    _updateService(context);
                  },
                  tooltip: 'Disable screensaver while scrcpy is running.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Video Bit Rate',
                  value: videoBitRate,
                  onChanged: (val) {
                    setState(() => videoBitRate = val);
                    _updateService(context);
                  },
                  tooltip: 'Encode the video at the given bit rate, expressed in bits/s. Unit suffixes are supported: \'K\' (x1000) and \'M\' (x1000000). Default is 8M (8000000).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AbsorbPointer(
                  absorbing: !hasDevices,
                  child: Opacity(
                    opacity: hasDevices ? 1 : 0.5,
                    child: CustomSearchBar(
                      hintText: hasDevices
                          ? "Search Codec..."
                          : "No device connected",
                      value: videoCodec.isNotEmpty ? videoCodec : null,
                      suggestions: videoCodecOptions,
                      onChanged: (val) {
                        setState(() => videoCodec = val);
                        _updateService(context);
                      },
                      onClear: () {
                        setState(() => videoCodec = '');
                        _updateService(context);
                      },
                      onReload: _loadVideoCodecs,
                      tooltip: 'Select a video codec (h264, h265 or av1). Default is h264. The available encoders can be listed from the device.',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomCheckbox(
                  label: 'Print FPS',
                  value: printFps,
                  onChanged: (val) {
                    setState(() => printFps = val);
                    _updateService(context);
                  },
                  tooltip: 'Start FPS counter, to print framerate logs to the console. It can be started or stopped at any time with MOD+i.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Power Off on Close',
                  value: powerOffOnClose,
                  onChanged: (val) {
                    setState(() => powerOffOnClose = val);
                    _updateService(context);
                  },
                  tooltip: 'Turn the device screen off when closing scrcpy.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Time Limit (seconds)',
                  value: timeLimit,
                  onChanged: (val) {
                    setState(() => timeLimit = val);
                    _updateService(context);
                  },
                  tooltip: 'Set the maximum mirroring time, in seconds.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Extra Parameters',
            value: extraParameters,
            onChanged: (val) {
              setState(() => extraParameters = val);
              _updateService(context);
            },
            tooltip: 'Add any additional scrcpy command-line parameters not covered by the GUI options above.',
          ),
        ],
      ),
    );
  }
}
