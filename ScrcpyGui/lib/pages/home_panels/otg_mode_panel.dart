/// OTG (On-The-Go) mode configuration panel for scrcpy.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/surrounding_panel.dart';

class OtgModePanel extends StatefulWidget {
  const OtgModePanel({super.key});

  @override
  State<OtgModePanel> createState() => _OtgModePanelState();
}

class _OtgModePanelState extends State<OtgModePanel> {
  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;

    return SurroundingPanel(
      icon: Icons.usb,
      title: 'OTG Mode',
      showButton: true,
      panelType: 'OTG Mode',
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(otg: false)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomCheckbox(
                  label: 'Enable OTG Mode',
                  value: cmd.otg,
                  onChanged: (val) => notifier.update(cmd.copyWith(otg: val)),
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
