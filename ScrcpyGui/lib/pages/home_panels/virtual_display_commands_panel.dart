/// Virtual display configuration panel for scrcpy.
///
/// This panel provides settings for creating and configuring virtual displays
/// on Android devices for mirroring purposes.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';
import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';

/// Panel for configuring virtual display options.
///
/// The [VirtualDisplayCommandsPanel] allows configuration of:
/// - New display creation
/// - Virtual display resolution
/// - Display density (DPI)
/// - Display flags
/// - Virtual display ID
/// - Destruction on exit behavior
///
/// Virtual displays are useful for screen recording or mirroring without
/// affecting the physical device display.
class VirtualDisplayCommandsPanel extends StatefulWidget {
  /// Creates a virtual display commands panel.
  const VirtualDisplayCommandsPanel({super.key, this.clearController});

  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

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
    final opts = context.select<CommandBuilderService, VirtualDisplayOptions>(
      (s) => s.virtualDisplayOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    return SurroundingPanel(
      icon: Icons.monitor,
      title: 'Virtual Display',
      panelType: "Virtual Display",
      showButton: true,
      onClearPressed: () {
        cmdService.updateVirtualDisplayOptions(const VirtualDisplayOptions());
        debugPrint('[VirtualDisplayCommandsPanel] Fields cleared!');
      },
      clearController: widget.clearController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: CustomCheckbox(
                  label: 'New Display',
                  value: opts.newDisplay,
                  onChanged: (val) {
                    var newOpts = opts.copyWith(newDisplay: val);
                    if (val && opts.resolution.isEmpty) {
                      newOpts = newOpts.copyWith(
                        resolution: resolutionOptions.first,
                      );
                    } else if (!val) {
                      newOpts = newOpts.copyWith(
                        resolution: '',
                        dpi: '',
                        noVdSystemDecorations: false,
                        noVdDestroyContent: false,
                      );
                    }
                    cmdService.updateVirtualDisplayOptions(newOpts);
                    debugPrint('[VirtualDisplayCommandsPanel] Updated VirtualDisplayOptions → ${cmdService.fullCommand}');
                  },
                  tooltip:
                      'Create a new display with the specified resolution and density. If not provided, they default to the main display dimensions and DPI.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !opts.newDisplay,
                  child: Opacity(
                    opacity: opts.newDisplay ? 1.0 : 0.5,
                    child: CustomSearchBar(
                      hintText: 'Resolution',
                      suggestions: resolutionOptions,
                      value: opts.resolution,
                      onChanged: (val) {
                        cmdService.updateVirtualDisplayOptions(
                          opts.copyWith(resolution: val),
                        );
                        debugPrint('[VirtualDisplayCommandsPanel] Updated VirtualDisplayOptions → ${cmdService.fullCommand}');
                      },
                      onClear: () {
                        cmdService.updateVirtualDisplayOptions(
                          opts.copyWith(resolution: ''),
                        );
                        debugPrint('[VirtualDisplayCommandsPanel] Updated VirtualDisplayOptions → ${cmdService.fullCommand}');
                      },
                      tooltip: 'Set the resolution for the new display (e.g., 1920x1080). Defaults to the main display dimensions.',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !opts.newDisplay,
                  child: Opacity(
                    opacity: opts.newDisplay ? 1.0 : 0.5,
                    child: CustomCheckbox(
                      label: "Don't Destroy Content",
                      value: opts.noVdDestroyContent,
                      onChanged: (val) {
                        cmdService.updateVirtualDisplayOptions(
                          opts.copyWith(noVdDestroyContent: val),
                        );
                        debugPrint('[VirtualDisplayCommandsPanel] Updated VirtualDisplayOptions → ${cmdService.fullCommand}');
                      },
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
                  absorbing: !opts.newDisplay,
                  child: Opacity(
                    opacity: opts.newDisplay ? 1.0 : 0.5,
                    child: CustomCheckbox(
                      label: 'No Display Decorations',
                      value: opts.noVdSystemDecorations,
                      onChanged: (val) {
                        cmdService.updateVirtualDisplayOptions(
                          opts.copyWith(noVdSystemDecorations: val),
                        );
                        debugPrint('[VirtualDisplayCommandsPanel] Updated VirtualDisplayOptions → ${cmdService.fullCommand}');
                      },
                      tooltip: 'Disable virtual display system decorations flag.',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !opts.newDisplay,
                  child: Opacity(
                    opacity: opts.newDisplay ? 1.0 : 0.5,
                    child: CustomTextField(
                      label: 'Dots Per Inch (DPI)',
                      value: opts.dpi,
                      onChanged: (val) {
                        cmdService.updateVirtualDisplayOptions(
                          opts.copyWith(dpi: val),
                        );
                        debugPrint('[VirtualDisplayCommandsPanel] Updated VirtualDisplayOptions → ${cmdService.fullCommand}');
                      },
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
