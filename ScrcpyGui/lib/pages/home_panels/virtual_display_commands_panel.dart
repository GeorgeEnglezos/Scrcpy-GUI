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

  bool newDisplay = false;
  bool noDisplayDecorations = false;
  bool dontDestroyContent = false;
  String resolution = '';
  String dpi = '';

  void _updateService(BuildContext context) {
    final cmdService = Provider.of<CommandBuilderService>(
      context,
      listen: false,
    );

    final options = cmdService.virtualDisplayOptions.copyWith(
      newDisplay: newDisplay,
      noVdSystemDecorations: noDisplayDecorations,
      noVdDestroyContent: dontDestroyContent,
      resolution: resolution,
      dpi: dpi,
    );

    cmdService.updateVirtualDisplayOptions(options);

    debugPrint(
      '[VirtualDisplayPanel] Updated VirtualDisplayOptions → ${cmdService.fullCommand}',
    );
  }

  void _cleanSettings(BuildContext context) {
    setState(() {
      resolution = '';
      dpi = '';
      noDisplayDecorations = false;
      dontDestroyContent = false;
    });
    _updateService(context);
  }

  void _onNewDisplayChanged(BuildContext context, bool enabled) {
    setState(() {
      newDisplay = enabled;
      if (enabled && resolution.isEmpty) {
        resolution = resolutionOptions.first;
      }
    });

    if (!enabled) {
      _cleanSettings(context);
    }

    _updateService(context);
  }

  void _clearAllFields() {
    setState(() {
      newDisplay = false;
      noDisplayDecorations = false;
      dontDestroyContent = false;
      resolution = '';
      dpi = '';
    });
    _updateService(context);
  }

  @override
  Widget build(BuildContext context) {
    return SurroundingPanel(
      icon: Icons.monitor,
      title: 'Virtual Display',
      panelType: "Virtual Display",
      showButton: true,
      onClearPressed: _clearAllFields,
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
                  value: newDisplay,
                  onChanged: (val) {
                    _onNewDisplayChanged(context, val);
                  },
                  tooltip: 'Create a new display with the specified resolution and density. If not provided, they default to the main display dimensions and DPI.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !newDisplay,
                  child: Opacity(
                    opacity: newDisplay ? 1.0 : 0.5,
                    child: CustomSearchBar(
                      hintText: 'Resolution',
                      suggestions: resolutionOptions,
                      value: resolution,
                      onChanged: (val) {
                        setState(() => resolution = val);
                        _updateService(context);
                      },
                      onClear: () {
                        setState(() => resolution = '');
                        _updateService(context);
                      },
                      tooltip: 'Set the resolution for the new display (e.g., 1920x1080). Defaults to the main display dimensions.',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !newDisplay,
                  child: Opacity(
                    opacity: newDisplay ? 1.0 : 0.5,
                    child: CustomCheckbox(
                      label: "Don't Destroy Content",
                      value: dontDestroyContent,
                      onChanged: (val) {
                        setState(() => dontDestroyContent = val);
                        _updateService(context);
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
                  absorbing: !newDisplay,
                  child: Opacity(
                    opacity: newDisplay ? 1.0 : 0.5,
                    child: CustomCheckbox(
                      label: 'No Display Decorations',
                      value: noDisplayDecorations,
                      onChanged: (val) {
                        setState(() => noDisplayDecorations = val);
                        _updateService(context);
                      },
                      tooltip: 'Disable virtual display system decorations flag.',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !newDisplay,
                  child: Opacity(
                    opacity: newDisplay ? 1.0 : 0.5,
                    child: CustomTextField(
                      label: 'Dots Per Inch (DPI)',
                      value: dpi,
                      onChanged: (val) {
                        setState(() => dpi = val);
                        _updateService(context);
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
