/// OTG (On-The-Go) mode configuration panel for scrcpy.
///
/// This panel provides settings for enabling OTG mode which allows physical
/// keyboard/mouse control of devices without mirroring the display.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';
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
  @override
  Widget build(BuildContext context) {
    final opts = context.select<CommandBuilderService, OtgModeOptions>(
      (s) => s.otgModeOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    return SurroundingPanel(
      icon: Icons.usb,
      title: 'OTG Mode',
      showButton: true,
      panelType: "OTG Mode",
      onClearPressed: () {
        cmdService.updateOtgModeOptions(const OtgModeOptions());
        debugPrint('[OtgModePanel] Fields cleared!');
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
                  label: 'Enable OTG Mode',
                  value: opts.otg,
                  onChanged: (val) {
                    cmdService.updateOtgModeOptions(opts.copyWith(otg: val));
                    debugPrint('[OtgModePanel] Updated OtgModeOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Run in OTG mode: simulate physical keyboard and mouse, as if the computer keyboard and mouse were plugged directly to the device via an OTG cable. In this mode, adb (USB debugging) is not necessary, and mirroring is disabled.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'HID Keyboard',
                  value: opts.hidKeyboard,
                  onChanged: (val) {
                    cmdService.updateOtgModeOptions(opts.copyWith(hidKeyboard: val));
                    debugPrint('[OtgModePanel] Updated OtgModeOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Simulate a physical HID keyboard. Keyboard may be disabled separately using --keyboard=disabled.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'HID Mouse',
                  value: opts.hidMouse,
                  onChanged: (val) {
                    cmdService.updateOtgModeOptions(opts.copyWith(hidMouse: val));
                    debugPrint('[OtgModePanel] Updated OtgModeOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Simulate a physical HID mouse. Mouse may be disabled separately using --mouse=disabled.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'OTG mode allows control of the device via USB On-The-Go.\n'
            'This mode simulates physical keyboard and mouse input without video streaming.\n'
            'Note: Requires USB OTG support on the device.',
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
