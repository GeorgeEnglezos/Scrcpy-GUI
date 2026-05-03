/// General settings panel for commonly used scrcpy command options.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../services/device_manager_service.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

class CommonCommandsPanel extends StatefulWidget {
  const CommonCommandsPanel({super.key});

  @override
  State<CommonCommandsPanel> createState() => _CommonCommandsPanelState();
}

class _CommonCommandsPanelState extends State<CommonCommandsPanel> {
  List<String> videoCodecOptions = [];

  final List<String> orientationOptions = [
    '0', '90', '180', '270',
    'flip0', 'flip90', 'flip180', 'flip270',
    '@0', '@90', '@180', '@270',
    '@flip0', '@flip90', '@flip180', '@flip270',
  ];

  DeviceManagerService? _deviceManager;

  @override
  void initState() {
    super.initState();
    _loadVideoCodecs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceManager = context.read<DeviceManagerService>();
      _deviceManager?.selectedDeviceNotifier.addListener(_onDeviceChanged);
    });
  }

  void _onDeviceChanged() => _loadVideoCodecs();

  Future<void> _loadVideoCodecs() async {
    final deviceManager = context.read<DeviceManagerService>();
    final deviceId = deviceManager.selectedDevice;

    if (deviceId == null) {
      setState(() => videoCodecOptions = []);
      return;
    }

    final info = DeviceManagerService.devicesInfo[deviceId];
    setState(() => videoCodecOptions = info?.videoCodecs ?? []);

    // If the current codec is no longer valid for this device, clear it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = context.read<CommandNotifier>();
      if (notifier.current.videoCodecEncoderPair.isNotEmpty &&
          !videoCodecOptions.contains(notifier.current.videoCodecEncoderPair)) {
        notifier.update(
            notifier.current.copyWith(videoCodecEncoderPair: ''));
      }
    });
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;
    final hasDevices = videoCodecOptions.isNotEmpty;

    return SurroundingPanel(
      icon: Icons.desktop_windows,
      title: 'General',
      showButton: true,
      panelType: 'General',
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(
        windowTitle: '',
        fullscreen: false,
        turnScreenOff: false,
        stayAwake: false,
        crop: '',
        videoOrientation: '',
        windowBorderless: false,
        windowAlwaysOnTop: false,
        disableScreensaver: false,
        videoBitRate: '',
        maxFps: '',
        maxSize: '',
        videoCodecEncoderPair: '',
        extraParameters: '',
        printFps: false,
        timeLimit: '',
        powerOffOnClose: false,
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Window Title',
                  value: cmd.windowTitle,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(windowTitle: val)),
                  tooltip: 'Set a custom window title.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Fullscreen',
                  value: cmd.fullscreen,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(fullscreen: val)),
                  tooltip: 'Start in fullscreen.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Screen off',
                  value: cmd.turnScreenOff,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(turnScreenOff: val)),
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
                  value: cmd.stayAwake,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(stayAwake: val)),
                  tooltip: 'Keep the device on while scrcpy is running, when the device is plugged in.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Crop Screen (W:H:X:Y)',
                  value: cmd.crop,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(crop: val)),
                  tooltip: 'Crop the device screen on the server. The values are expressed in the device natural orientation (typically, portrait for a phone, landscape for a tablet).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: "Orientation",
                  value: cmd.videoOrientation.isEmpty
                      ? null
                      : cmd.videoOrientation,
                  suggestions: orientationOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(videoOrientation: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(videoOrientation: '')),
                  tooltip: 'Set the capture orientation (server-side). Affects both mirroring and recording. Values: 0, 90, 180, 270 (rotation), flip0/flip90/flip180/flip270 (mirrored), or prefix with @ to lock against device rotation.',
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
                  value: cmd.windowBorderless,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(windowBorderless: val)),
                  tooltip: 'Disable window decorations (display borderless window).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Window Always on Top',
                  value: cmd.windowAlwaysOnTop,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(windowAlwaysOnTop: val)),
                  tooltip: 'Make scrcpy window always on top (above other windows).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Disable Screensaver',
                  value: cmd.disableScreensaver,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(disableScreensaver: val)),
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
                  value: cmd.videoBitRate,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(videoBitRate: val)),
                  tooltip: "Encode the video at the given bit rate, expressed in bits/s. Unit suffixes are supported: 'K' (x1000) and 'M' (x1000000). Default is 8M (8000000).",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Max FPS',
                  value: cmd.maxFps,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(maxFps: val)),
                  tooltip: 'Limit the frame rate of screen capture. Affects both mirroring and recording. Officially supported since Android 10.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Max Size',
                  value: cmd.maxSize,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(maxSize: val)),
                  tooltip: 'Limit both the width and height of the video to this value. The other dimension is scaled to preserve aspect ratio. Affects both mirroring and recording.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AbsorbPointer(
                  absorbing: !hasDevices,
                  child: Opacity(
                    opacity: hasDevices ? 1 : 0.5,
                    child: CustomSearchBar(
                      hintText: hasDevices
                          ? "Search Codec..."
                          : "No device connected",
                      value: cmd.videoCodecEncoderPair.isEmpty
                          ? null
                          : cmd.videoCodecEncoderPair,
                      suggestions: videoCodecOptions,
                      onChanged: (val) =>
                          notifier.update(cmd.copyWith(videoCodecEncoderPair: val)),
                      onClear: () =>
                          notifier.update(cmd.copyWith(videoCodecEncoderPair: '')),
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
                  value: cmd.printFps,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(printFps: val)),
                  tooltip: 'Start FPS counter, to print framerate logs to the console. It can be started or stopped at any time with MOD+i.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Power Off on Close',
                  value: cmd.powerOffOnClose,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(powerOffOnClose: val)),
                  tooltip: 'Turn the device screen off when closing scrcpy.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Time Limit (seconds)',
                  value: cmd.timeLimit,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(timeLimit: val)),
                  tooltip: 'Set the maximum mirroring time, in seconds.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Extra Parameters',
            value: cmd.extraParameters,
            onChanged: (val) =>
                notifier.update(cmd.copyWith(extraParameters: val)),
            tooltip: 'Add any additional scrcpy command-line parameters not covered by the GUI options above.',
          ),
        ],
      ),
    );
  }
}
