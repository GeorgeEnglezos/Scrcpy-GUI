/// Virtual display configuration panel for scrcpy.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

class VirtualDisplayCommandsPanel extends StatefulWidget {
  const VirtualDisplayCommandsPanel({super.key});

  @override
  State<VirtualDisplayCommandsPanel> createState() =>
      _VirtualDisplayCommandsPanelState();
}

class _VirtualDisplayCommandsPanelState
    extends State<VirtualDisplayCommandsPanel> {
  final List<String> resolutionOptions = [
    '1920x1080',
    '1280x720',
    '2560x1440',
    '3840x2160',
    '1024x768',
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;

    return SurroundingPanel(
      icon: Icons.monitor,
      title: 'Virtual Display',
      panelType: 'Virtual Display',
      showButton: true,
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(
        newDisplay: false,
        resolution: '',
        dpi: '',
        noVdDestroyContent: false,
        noVdSystemDecorations: false,
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: CustomCheckbox(
                  label: 'New Display',
                  value: cmd.newDisplay,
                  onChanged: (val) {
                    if (val) {
                      notifier.update(cmd.copyWith(
                        newDisplay: true,
                        resolution: cmd.resolution.isEmpty
                            ? resolutionOptions.first
                            : cmd.resolution,
                      ));
                    } else {
                      notifier.update(cmd.copyWith(
                        newDisplay: false,
                        resolution: '',
                        dpi: '',
                        noVdDestroyContent: false,
                        noVdSystemDecorations: false,
                      ));
                    }
                  },
                  tooltip: 'Create a new display with the specified resolution and density. If not provided, they default to the main display dimensions and DPI.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !cmd.newDisplay,
                  child: Opacity(
                    opacity: cmd.newDisplay ? 1.0 : 0.5,
                    child: CustomSearchBar(
                      hintText: 'Resolution',
                      suggestions: resolutionOptions,
                      value: cmd.resolution,
                      onChanged: (val) =>
                          notifier.update(cmd.copyWith(resolution: val)),
                      onClear: () =>
                          notifier.update(cmd.copyWith(resolution: '')),
                      tooltip: 'Set the resolution for the new display (e.g., 1920x1080). Defaults to the main display dimensions.',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !cmd.newDisplay,
                  child: Opacity(
                    opacity: cmd.newDisplay ? 1.0 : 0.5,
                    child: CustomCheckbox(
                      label: "Don't Destroy Content",
                      value: cmd.noVdDestroyContent,
                      onChanged: (val) =>
                          notifier.update(cmd.copyWith(noVdDestroyContent: val)),
                      tooltip: 'Disable virtual display "destroy content on removal" flag. With this option, when the virtual display is closed, the running apps are moved to the main display rather than being destroyed.',
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
                child: AbsorbPointer(
                  absorbing: !cmd.newDisplay,
                  child: Opacity(
                    opacity: cmd.newDisplay ? 1.0 : 0.5,
                    child: CustomCheckbox(
                      label: 'No Display Decorations',
                      value: cmd.noVdSystemDecorations,
                      onChanged: (val) => notifier
                          .update(cmd.copyWith(noVdSystemDecorations: val)),
                      tooltip: 'Disable virtual display system decorations flag.',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !cmd.newDisplay,
                  child: Opacity(
                    opacity: cmd.newDisplay ? 1.0 : 0.5,
                    child: CustomTextField(
                      label: 'Dots Per Inch (DPI)',
                      value: cmd.dpi,
                      onChanged: (val) =>
                          notifier.update(cmd.copyWith(dpi: val)),
                      tooltip: 'Set the DPI for the new display. Defaults to the main display DPI.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
