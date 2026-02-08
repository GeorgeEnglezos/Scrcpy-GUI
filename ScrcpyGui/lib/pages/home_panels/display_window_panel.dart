/// Display and window configuration panel for scrcpy.
///
/// This panel provides configuration for window position, size, rotation,
/// display selection, rendering, and buffering options.
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

/// Panel for configuring display window properties and rendering options.
///
/// The [DisplayWindowPanel] allows configuration of:
/// - Window position (X, Y coordinates)
/// - Window size (width, height)
/// - Display rotation (0-3, 90-degree increments)
/// - Display ID for multi-display devices
/// - Display buffer size
/// - Render driver selection
/// - ADB forward mode forcing
class DisplayWindowPanel extends StatefulWidget {
  /// Creates a display window panel.
  const DisplayWindowPanel({super.key, this.clearController});

  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

  @override
  State<DisplayWindowPanel> createState() => _DisplayWindowPanelState();
}

class _DisplayWindowPanelState extends State<DisplayWindowPanel> {
  final List<String> rotationOptions = ['0', '1', '2', '3'];
  final List<String> renderDriverOptions = [
    'direct3d',
    'direct3d11',
    'direct3d12',
    'opengl',
    'opengles',
    'opengles2',
    'metal',
    'software',
  ];

  @override
  Widget build(BuildContext context) {
    final opts = context.select<CommandBuilderService, DisplayWindowOptions>(
      (s) => s.displayWindowOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    return SurroundingPanel(
      icon: Icons.crop_square,
      title: 'Display/Window',
      showButton: true,
      panelType: "Display/Window",
      onClearPressed: () {
        cmdService.updateDisplayWindowOptions(const DisplayWindowOptions());
        debugPrint('[DisplayWindowPanel] Fields cleared!');
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
                  label: 'Window X Position',
                  value: opts.windowX,
                  onChanged: (val) {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(windowX: val));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set the initial window horizontal position. Default is "auto".',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Window Y Position',
                  value: opts.windowY,
                  onChanged: (val) {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(windowY: val));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set the initial window vertical position. Default is "auto".',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Window Width',
                  value: opts.windowWidth,
                  onChanged: (val) {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(windowWidth: val));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set the initial window width. Default is 0 (automatic).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Window Height',
                  value: opts.windowHeight,
                  onChanged: (val) {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(windowHeight: val));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set the initial window height. Default is 0 (automatic).',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Rotation (0=0°, 1=90°, 2=180°, 3=270°)',
                  value: opts.rotation.isNotEmpty ? opts.rotation : null,
                  suggestions: rotationOptions,
                  onChanged: (val) {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(rotation: val));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(rotation: ''));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Rotate the video content by 90° increments (0, 1, 2, or 3 for 0°, 90°, 180°, 270° clockwise).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Display ID',
                  value: opts.displayId,
                  onChanged: (val) {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(displayId: val));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Specify the device display id to mirror. The available display ids can be listed by: scrcpy --list-displays. Default is 0.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Display Buffer (ms)',
                  value: opts.displayBuffer,
                  onChanged: (val) {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(displayBuffer: val));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Add a buffering delay (in milliseconds) before displaying video frames. This increases latency to compensate for jitter. Default is 0 (no buffering).',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomSearchBar(
                  hintText: 'Render Driver',
                  value: opts.renderDriver.isNotEmpty ? opts.renderDriver : null,
                  suggestions: renderDriverOptions,
                  onChanged: (val) {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(renderDriver: val));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(renderDriver: ''));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Request SDL to use the given render driver (this is just a hint). Supported names: direct3d, opengl, opengles2, opengles, metal, software.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Force ADB Forward',
                  value: opts.forceAdbForward,
                  onChanged: (val) {
                    cmdService.updateDisplayWindowOptions(opts.copyWith(forceAdbForward: val));
                    debugPrint('[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Do not attempt to use "adb reverse" to connect to the device.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
