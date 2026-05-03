/// Camera settings panel for scrcpy command configuration.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../services/device_manager_service.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

class CameraCommandsPanel extends StatefulWidget {
  const CameraCommandsPanel({super.key});

  @override
  State<CameraCommandsPanel> createState() => _CameraCommandsPanelState();
}

class _CameraCommandsPanelState extends State<CameraCommandsPanel> {
  final List<String> cameraFacingOptions = ['front', 'back', 'external'];
  final List<String> cameraSizeOptions = [
    '1920x1080', '1280x720', '640x480', '320x240',
  ];
  final List<String> cameraFpsOptions = ['15', '30', '60'];
  final List<String> cameraArOptions = ['16:9', '4:3', '1:1'];

  DeviceManagerService? _deviceManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceManager = context.read<DeviceManagerService>();
      _deviceManager?.selectedDeviceNotifier.addListener(_onDeviceChanged);
    });
  }

  void _onDeviceChanged() => setState(() {});

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;

    return SurroundingPanel(
      icon: Icons.camera_alt,
      title: 'Camera',
      showButton: true,
      panelType: 'Camera',
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(
        cameraId: '',
        cameraSize: '',
        cameraFacing: '',
        cameraFps: '',
        cameraAr: '',
        cameraHighSpeed: false,
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Camera ID',
                  value: cmd.cameraId,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(cameraId: val)),
                  tooltip: 'Specify the device camera id to mirror. The available camera ids can be listed by: scrcpy --list-cameras',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera Size',
                  value: cmd.cameraSize.isEmpty ? null : cmd.cameraSize,
                  suggestions: cameraSizeOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(cameraSize: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(cameraSize: '')),
                  tooltip: 'Specify an explicit camera capture size (e.g., 1920x1080).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera Facing',
                  value: cmd.cameraFacing.isEmpty ? null : cmd.cameraFacing,
                  suggestions: cameraFacingOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(cameraFacing: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(cameraFacing: '')),
                  tooltip: 'Select the device camera by its facing direction. Possible values are "front", "back" and "external".',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera FPS',
                  value: cmd.cameraFps.isEmpty ? null : cmd.cameraFps,
                  suggestions: cameraFpsOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(cameraFps: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(cameraFps: '')),
                  tooltip: "Specify the camera capture frame rate. If not specified, Android's default frame rate (30 fps) is used.",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera Aspect Ratio',
                  value: cmd.cameraAr.isEmpty ? null : cmd.cameraAr,
                  suggestions: cameraArOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(cameraAr: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(cameraAr: '')),
                  tooltip: 'Select the camera size by its aspect ratio (+/- 10%). Possible values are "sensor" (use the camera sensor aspect ratio), "<num>:<den>" (e.g. "4:3") or "<value>" (e.g. "1.6").',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'High Speed Mode',
                  value: cmd.cameraHighSpeed,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(cameraHighSpeed: val)),
                  tooltip: 'Enable high-speed camera capture mode. This mode is restricted to specific resolutions and frame rates, listed by --list-camera-sizes.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
