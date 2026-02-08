/// General settings panel for commonly used scrcpy command options.
///
/// This panel provides the most frequently used scrcpy settings including
/// window configuration, screen behavior, video encoding, and general options.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';
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
  List<String> videoCodecOptions = [];
  final List<String> orientationOptions = ['0', '90', '180', '270'];

  DeviceManagerService? _deviceManager;

  @override
  void initState() {
    super.initState();
    _loadVideoCodecs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _deviceManager = Provider.of<DeviceManagerService>(
        context,
        listen: false,
      );
      _deviceManager?.selectedDeviceNotifier.addListener(_onDeviceChanged);
    });
  }

  void _onDeviceChanged() {
    _loadVideoCodecs();
  }

  Future<void> _loadVideoCodecs() async {
    final deviceManager = Provider.of<DeviceManagerService>(
      context,
      listen: false,
    );
    final deviceId = deviceManager.selectedDevice;

    if (deviceId == null) {
      if (mounted) setState(() => videoCodecOptions = []);
      return;
    }

    final info = DeviceManagerService.devicesInfo[deviceId];
    if (info != null) {
      if (mounted) setState(() => videoCodecOptions = info.videoCodecs);
    } else {
      if (mounted) setState(() => videoCodecOptions = []);
    }
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDevices = videoCodecOptions.isNotEmpty;
    final opts = context.select<CommandBuilderService, GeneralCastOptions>(
      (s) => s.generalCastOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    return SurroundingPanel(
      icon: Icons.desktop_windows,
      title: 'General',
      showButton: true,
      panelType: "General",
      onClearPressed: () {
        cmdService.updateGeneralCastOptions(const GeneralCastOptions());
        debugPrint('[CommonCommandsPanel] Fields cleared!');
      },
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
                  value: opts.windowTitle,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(windowTitle: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set a custom window title.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Fullscreen',
                  value: opts.fullscreen,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(fullscreen: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Start in fullscreen.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Screen off',
                  value: opts.turnScreenOff,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(turnScreenOff: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
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
                  value: opts.stayAwake,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(stayAwake: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Keep the device on while scrcpy is running, when the device is plugged in.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Crop Screen (W:H:X:Y)',
                  value: opts.crop,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(crop: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Crop the device screen on the server. The values are expressed in the device natural orientation (typically, portrait for a phone, landscape for a tablet).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: "Orientation",
                  value: opts.videoOrientation.isNotEmpty ? opts.videoOrientation : null,
                  suggestions: orientationOptions,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(videoOrientation: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateGeneralCastOptions(opts.copyWith(videoOrientation: ''));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
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
                  value: opts.windowBorderless,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(windowBorderless: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Disable window decorations (display borderless window).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Window Always on Top',
                  value: opts.windowAlwaysOnTop,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(windowAlwaysOnTop: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Make scrcpy window always on top (above other windows).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Disable Screensaver',
                  value: opts.disableScreensaver,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(disableScreensaver: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
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
                  value: opts.videoBitRate,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(videoBitRate: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
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
                      value: opts.videoCodecEncoderPair.isNotEmpty ? opts.videoCodecEncoderPair : null,
                      suggestions: videoCodecOptions,
                      onChanged: (val) {
                        cmdService.updateGeneralCastOptions(opts.copyWith(videoCodecEncoderPair: val));
                        debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                      },
                      onClear: () {
                        cmdService.updateGeneralCastOptions(opts.copyWith(videoCodecEncoderPair: ''));
                        debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
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
                  value: opts.printFps,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(printFps: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Start FPS counter, to print framerate logs to the console. It can be started or stopped at any time with MOD+i.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Power Off on Close',
                  value: opts.powerOffOnClose,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(powerOffOnClose: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Turn the device screen off when closing scrcpy.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Time Limit (seconds)',
                  value: opts.timeLimit,
                  onChanged: (val) {
                    cmdService.updateGeneralCastOptions(opts.copyWith(timeLimit: val));
                    debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set the maximum mirroring time, in seconds.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Extra Parameters',
            value: opts.extraParameters,
            onChanged: (val) {
              cmdService.updateGeneralCastOptions(opts.copyWith(extraParameters: val));
              debugPrint('[CommonCommandsPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
            },
            tooltip: 'Add any additional scrcpy command-line parameters not covered by the GUI options above.',
          ),
        ],
      ),
    );
  }
}
