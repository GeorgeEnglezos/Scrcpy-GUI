/// Camera settings panel for scrcpy command configuration.
///
/// This panel provides camera mirroring configuration including camera selection,
/// resolution, frame rate, aspect ratio, and high-speed mode settings.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';
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
  final List<String> cameraFacingOptions = ['front', 'back', 'external'];
  final List<String> cameraSizeOptions = [
    '1920x1080',
    '1280x720',
    '640x480',
    '320x240',
  ];
  final List<String> cameraFpsOptions = ['15', '30', '60'];
  final List<String> cameraArOptions = ['16:9', '4:3', '1:1'];

  @override
  Widget build(BuildContext context) {
    final opts = context.select<CommandBuilderService, CameraOptions>(
      (s) => s.cameraOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    return SurroundingPanel(
      icon: Icons.camera_alt,
      title: 'Camera',
      showButton: true,
      panelType: "Camera",
      onClearPressed: () {
        cmdService.updateCameraOptions(const CameraOptions());
        debugPrint('[CameraPanel] Fields cleared!');
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
                  label: 'Camera ID',
                  value: opts.cameraId,
                  onChanged: (val) {
                    cmdService.updateCameraOptions(opts.copyWith(cameraId: val));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Specify the device camera id to mirror. The available camera ids can be listed by: scrcpy --list-cameras',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera Size',
                  value: opts.cameraSize.isNotEmpty ? opts.cameraSize : null,
                  suggestions: cameraSizeOptions,
                  onChanged: (val) {
                    cmdService.updateCameraOptions(opts.copyWith(cameraSize: val));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateCameraOptions(opts.copyWith(cameraSize: ''));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Specify an explicit camera capture size (e.g., 1920x1080).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera Facing',
                  value: opts.cameraFacing.isNotEmpty ? opts.cameraFacing : null,
                  suggestions: cameraFacingOptions,
                  onChanged: (val) {
                    cmdService.updateCameraOptions(opts.copyWith(cameraFacing: val));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateCameraOptions(opts.copyWith(cameraFacing: ''));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
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
                  value: opts.cameraFps.isNotEmpty ? opts.cameraFps : null,
                  suggestions: cameraFpsOptions,
                  onChanged: (val) {
                    cmdService.updateCameraOptions(opts.copyWith(cameraFps: val));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateCameraOptions(opts.copyWith(cameraFps: ''));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Specify the camera capture frame rate. If not specified, Android\'s default frame rate (30 fps) is used.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Camera Aspect Ratio',
                  value: opts.cameraAr.isNotEmpty ? opts.cameraAr : null,
                  suggestions: cameraArOptions,
                  onChanged: (val) {
                    cmdService.updateCameraOptions(opts.copyWith(cameraAr: val));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateCameraOptions(opts.copyWith(cameraAr: ''));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Select the camera size by its aspect ratio (+/- 10%). Possible values are "sensor" (use the camera sensor aspect ratio), "<num>:<den>" (e.g. "4:3") or "<value>" (e.g. "1.6").',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'High Speed Mode',
                  value: opts.cameraHighSpeed,
                  onChanged: (val) {
                    cmdService.updateCameraOptions(opts.copyWith(cameraHighSpeed: val));
                    debugPrint('[CameraPanel] Updated CameraOptions → ${cmdService.fullCommand}');
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
