/// Camera settings panel for scrcpy command configuration.
///
/// This panel provides camera mirroring configuration including camera selection,
/// resolution, frame rate, aspect ratio, and high-speed mode settings.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

/// Panel for configuring camera mirroring options.
///
/// The [CameraCommandsPanel] allows users to configure:
/// - Camera ID selection for specific camera access
/// - Camera resolution (e.g., 1920x1080)
/// - Camera facing direction (front, back, external)
/// - Frame rate (FPS) settings
/// - Aspect ratio preferences
/// - High-speed capture mode
///
/// All settings are synchronized with [CommandBuilderService].
class CameraCommandsPanel extends StatefulWidget {
  /// Creates a camera commands panel.
  const CameraCommandsPanel({super.key, this.clearController});

  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

  @override
  State<CameraCommandsPanel> createState() => _CameraCommandsPanelState();
}

class _CameraCommandsPanelState extends State<CameraCommandsPanel> {
  String cameraId = '';
  String cameraSize = '';
  String? cameraFacing;
  String cameraFps = '';
  String cameraAr = '';
  bool cameraHighSpeed = false;

  final List<String> cameraFacingOptions = ['front', 'back', 'external'];
  final List<String> cameraSizeOptions = [
    '1920x1080',
    '1280x720',
    '640x480',
    '320x240',
  ];
  final List<String> cameraFpsOptions = ['15', '30', '60'];
  final List<String> cameraArOptions = ['16:9', '4:3', '1:1'];

  void _updateService(BuildContext context) {
    final cmdService = Provider.of<CommandBuilderService>(
      context,
      listen: false,
    );

    final options = cmdService.cameraOptions.copyWith(
      cameraId: cameraId,
      cameraSize: cameraSize,
      cameraFacing: cameraFacing ?? '',
      cameraFps: cameraFps,
      cameraAr: cameraAr,
      cameraHighSpeed: cameraHighSpeed,
    );

    cmdService.updateCameraOptions(options);

    debugPrint(
      '[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}',
    );
  }

  void _clearAllFields() {
    setState(() {
      cameraId = '';
      cameraSize = '';
      cameraFacing = null;
      cameraFps = '';
      cameraAr = '';
      cameraHighSpeed = false;
    });
    _updateService(context);
  }

  @override
  Widget build(BuildContext context) {
    return SurroundingPanel(
      icon: Icons.camera_alt,
      title: 'Camera',
      showButton: true,
      panelType: "Camera",
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
                  label: 'Camera ID',
                  value: cameraId,
                  onChanged: (val) {
                    setState(() => cameraId = val);
                    _updateService(context);
                  },
                  tooltip: 'Specify the device camera id to mirror. The available camera ids can be listed by: scrcpy --list-cameras',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera Size',
                  value: cameraSize.isNotEmpty ? cameraSize : null,
                  suggestions: cameraSizeOptions,
                  onChanged: (val) {
                    setState(() => cameraSize = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => cameraSize = '');
                    _updateService(context);
                  },
                  tooltip: 'Specify an explicit camera capture size (e.g., 1920x1080).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera Facing',
                  value: cameraFacing,
                  suggestions: cameraFacingOptions,
                  onChanged: (val) {
                    setState(() => cameraFacing = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => cameraFacing = null);
                    _updateService(context);
                  },
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
                  value: cameraFps.isNotEmpty ? cameraFps : null,
                  suggestions: cameraFpsOptions,
                  onChanged: (val) {
                    setState(() => cameraFps = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => cameraFps = '');
                    _updateService(context);
                  },
                  tooltip: 'Specify the camera capture frame rate. If not specified, Android\'s default frame rate (30 fps) is used.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera Aspect Ratio',
                  value: cameraAr.isNotEmpty ? cameraAr : null,
                  suggestions: cameraArOptions,
                  onChanged: (val) {
                    setState(() => cameraAr = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => cameraAr = '');
                    _updateService(context);
                  },
                  tooltip: 'Select the camera size by its aspect ratio (+/- 10%). Possible values are "sensor" (use the camera sensor aspect ratio), "<num>:<den>" (e.g. "4:3") or "<value>" (e.g. "1.6").',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'High Speed Mode',
                  value: cameraHighSpeed,
                  onChanged: (val) {
                    setState(() => cameraHighSpeed = val);
                    _updateService(context);
                  },
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
