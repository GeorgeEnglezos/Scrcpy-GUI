/// Display and window configuration panel for scrcpy.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

class DisplayWindowPanel extends StatefulWidget {
  const DisplayWindowPanel({super.key});

  @override
  State<DisplayWindowPanel> createState() => _DisplayWindowPanelState();
}

class _DisplayWindowPanelState extends State<DisplayWindowPanel> {
  final List<String> rotationOptions = ['0', '90', '180', '270'];
  final List<String> renderDriverOptions = [
    'direct3d',
    'opengl',
    'opengles',
    'opengles2',
    'metal',
    'software',
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;

    return SurroundingPanel(
      icon: Icons.crop_square,
      title: 'Display/Window',
      showButton: true,
      panelType: 'Display/Window',
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(
        windowX: '',
        windowY: '',
        windowWidth: '',
        windowHeight: '',
        rotation: '',
        displayId: '',
        displayBuffer: '',
        renderDriver: '',
        forceAdbForward: false,
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Window X Position',
                  value: cmd.windowX,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(windowX: val)),
                  tooltip: 'Set the initial window horizontal position. Default is "auto".',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Window Y Position',
                  value: cmd.windowY,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(windowY: val)),
                  tooltip: 'Set the initial window vertical position. Default is "auto".',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Window Width',
                  value: cmd.windowWidth,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(windowWidth: val)),
                  tooltip: 'Set the initial window width. Default is 0 (automatic).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Window Height',
                  value: cmd.windowHeight,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(windowHeight: val)),
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
                  hintText: 'Display Orientation (0°, 90°, 180°, 270°)',
                  value: cmd.rotation.isEmpty ? null : cmd.rotation,
                  suggestions: rotationOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(rotation: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(rotation: '')),
                  tooltip: 'Set the display orientation in degrees (0, 90, 180, 270). This only affects the client-side display, not recordings.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Display ID',
                  value: cmd.displayId,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(displayId: val)),
                  tooltip: 'Specify the device display id to mirror. The available display ids can be listed by: scrcpy --list-displays. Default is 0.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Display Buffer (ms)',
                  value: cmd.displayBuffer,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(displayBuffer: val)),
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
                  value: cmd.renderDriver.isEmpty ? null : cmd.renderDriver,
                  suggestions: renderDriverOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(renderDriver: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(renderDriver: '')),
                  tooltip: 'Request SDL to use the given render driver (this is just a hint). Supported names: direct3d, opengl, opengles2, opengles, metal, software.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Force ADB Forward',
                  value: cmd.forceAdbForward,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(forceAdbForward: val)),
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
