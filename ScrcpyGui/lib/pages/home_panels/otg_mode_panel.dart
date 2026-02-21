/// OTG (On-The-Go) mode configuration panel for scrcpy.
///
/// This panel provides settings for enabling OTG mode which allows physical
/// keyboard/mouse control of devices without mirroring the display.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/surrounding_panel.dart';

/// Panel for configuring OTG mode options.
///
/// The [OtgModePanel] allows configuration of:
/// - OTG mode enable/disable
/// - HID keyboard simulation
/// - HID mouse simulation
///
/// OTG mode enables physical keyboard and mouse control over USB without
/// screen mirroring, useful for controlling devices with broken screens
/// or for minimal latency input.
class OtgModePanel extends StatefulWidget {
  /// Creates an OTG mode panel.
  const OtgModePanel({super.key, this.clearController});

  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

  @override
  State<OtgModePanel> createState() => _OtgModePanelState();
}

class _OtgModePanelState extends State<OtgModePanel> {
  bool otg = false;

  void _updateService(BuildContext context) {
    final cmdService = Provider.of<CommandBuilderService>(
      context,
      listen: false,
    );

    final options = cmdService.otgModeOptions.copyWith(
      otg: otg,
    );

    cmdService.updateOtgModeOptions(options);

    debugPrint(
      '[OtgModePanel] Updated OtgModeOptions → ${cmdService.fullCommand}',
    );
  }

  void _clearAllFields() {
    setState(() {
      otg = false;
    });
    _updateService(context);
  }

  @override
  Widget build(BuildContext context) {
    return SurroundingPanel(
      icon: Icons.usb,
      title: 'OTG Mode',
      showButton: true,
      panelType: "OTG Mode",
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
                  label: 'Enable OTG Mode',
                  value: otg,
                  onChanged: (val) {
                    setState(() => otg = val);
                    _updateService(context);
                  },
                  tooltip: 'Run in OTG mode: simulate physical keyboard and mouse, as if the computer keyboard and mouse were plugged directly to the device via an OTG cable. In this mode, adb (USB debugging) is not necessary, and mirroring is disabled. Keyboard (--keyboard=aoa) and mouse (--mouse=aoa) are implicitly enabled.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'OTG mode allows control of the device via USB On-The-Go.\n'
            'This mode simulates physical keyboard and mouse input without video streaming.\n'
            'Note: --keyboard=aoa and --mouse=aoa are implicitly set by --otg.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
