/// Display and window configuration panel for scrcpy.
///
/// This panel provides configuration for window position, size, rotation,
/// display selection, rendering, and buffering options.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
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
  String windowX = '';
  String windowY = '';
  String windowWidth = '';
  String windowHeight = '';
  String? rotation;
  String displayId = '';
  String displayBuffer = '';
  String? renderDriver;
  bool forceAdbForward = false;

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

  void _updateService(BuildContext context) {
    final cmdService = Provider.of<CommandBuilderService>(
      context,
      listen: false,
    );

    final options = cmdService.displayWindowOptions.copyWith(
      windowX: windowX,
      windowY: windowY,
      windowWidth: windowWidth,
      windowHeight: windowHeight,
      rotation: rotation ?? '',
      displayId: displayId,
      displayBuffer: displayBuffer,
      renderDriver: renderDriver ?? '',
      forceAdbForward: forceAdbForward,
    );

    cmdService.updateDisplayWindowOptions(options);

    debugPrint(
      '[DisplayWindowPanel] Updated DisplayWindowOptions → ${cmdService.fullCommand}',
    );
  }

  void _clearAllFields() {
    setState(() {
      windowX = '';
      windowY = '';
      windowWidth = '';
      windowHeight = '';
      rotation = null;
      displayId = '';
      displayBuffer = '';
      renderDriver = null;
      forceAdbForward = false;
    });
    _updateService(context);
  }

  @override
  Widget build(BuildContext context) {
    return SurroundingPanel(
      icon: Icons.crop_square,
      title: 'Display/Window',
      showButton: true,
      panelType: "Display/Window",
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
                  label: 'Window X Position',
                  value: windowX,
                  onChanged: (val) {
                    setState(() => windowX = val);
                    _updateService(context);
                  },
                  tooltip: 'Set the initial window horizontal position. Default is "auto".',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Window Y Position',
                  value: windowY,
                  onChanged: (val) {
                    setState(() => windowY = val);
                    _updateService(context);
                  },
                  tooltip: 'Set the initial window vertical position. Default is "auto".',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Window Width',
                  value: windowWidth,
                  onChanged: (val) {
                    setState(() => windowWidth = val);
                    _updateService(context);
                  },
                  tooltip: 'Set the initial window width. Default is 0 (automatic).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Window Height',
                  value: windowHeight,
                  onChanged: (val) {
                    setState(() => windowHeight = val);
                    _updateService(context);
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
                  value: rotation,
                  suggestions: rotationOptions,
                  onChanged: (val) {
                    setState(() => rotation = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => rotation = null);
                    _updateService(context);
                  },
                  tooltip: 'Rotate the video content by 90° increments (0, 1, 2, or 3 for 0°, 90°, 180°, 270° clockwise).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Display ID',
                  value: displayId,
                  onChanged: (val) {
                    setState(() => displayId = val);
                    _updateService(context);
                  },
                  tooltip: 'Specify the device display id to mirror. The available display ids can be listed by: scrcpy --list-displays. Default is 0.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Display Buffer (ms)',
                  value: displayBuffer,
                  onChanged: (val) {
                    setState(() => displayBuffer = val);
                    _updateService(context);
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
                  value: renderDriver,
                  suggestions: renderDriverOptions,
                  onChanged: (val) {
                    setState(() => renderDriver = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => renderDriver = null);
                    _updateService(context);
                  },
                  tooltip: 'Request SDL to use the given render driver (this is just a hint). Supported names: direct3d, opengl, opengles2, opengles, metal, software.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Force ADB Forward',
                  value: forceAdbForward,
                  onChanged: (val) {
                    setState(() => forceAdbForward = val);
                    _updateService(context);
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
