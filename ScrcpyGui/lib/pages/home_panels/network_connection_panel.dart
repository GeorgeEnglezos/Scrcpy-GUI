/// Network connection settings panel for TCP/IP and tunnel configuration.
///
/// This panel provides configuration for wireless connections including
/// TCP/IP port settings, automatic selection, and SSH tunnel support.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

/// Panel for configuring network connection options for wireless scrcpy.
///
/// The [NetworkConnectionPanel] allows configuration of:
/// - TCP/IP port for wireless connection
/// - Automatic TCP/IP device selection
/// - SSH tunnel host and port
/// - ADB forward mode control
///
/// This panel is essential for setting up wireless Android device mirroring.
class NetworkConnectionPanel extends StatefulWidget {
  /// Creates a network connection panel.
  const NetworkConnectionPanel({super.key, this.clearController});

  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

  @override
  State<NetworkConnectionPanel> createState() =>
      _NetworkConnectionPanelState();
}

class _NetworkConnectionPanelState extends State<NetworkConnectionPanel> {
  @override
  Widget build(BuildContext context) {
    final opts = context.select<CommandBuilderService, NetworkConnectionOptions>(
      (s) => s.networkConnectionOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    return SurroundingPanel(
      icon: Icons.wifi,
      title: 'Network/Connection',
      showButton: true,
      panelType: "Network/Connection",
      onClearPressed: () {
        cmdService.updateNetworkConnectionOptions(const NetworkConnectionOptions());
        debugPrint('[NetworkConnectionPanel] Fields cleared!');
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
                  label: 'TCP/IP Port',
                  value: opts.tcpipPort,
                  onChanged: (val) {
                    cmdService.updateNetworkConnectionOptions(opts.copyWith(tcpipPort: val));
                    debugPrint('[NetworkConnectionPanel] Updated NetworkConnectionOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set the TCP port (range) used by the client to listen. Default is 27183:27199.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Select TCP/IP Device',
                  value: opts.selectTcpip,
                  onChanged: (val) {
                    cmdService.updateNetworkConnectionOptions(opts.copyWith(selectTcpip: val));
                    debugPrint('[NetworkConnectionPanel] Updated NetworkConnectionOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Use TCP/IP device (if there is exactly one, like adb -e).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Disable ADB Forward',
                  value: opts.noAdbForward,
                  onChanged: (val) {
                    cmdService.updateNetworkConnectionOptions(opts.copyWith(noAdbForward: val));
                    debugPrint('[NetworkConnectionPanel] Updated NetworkConnectionOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Do not attempt to use "adb reverse" to connect to the device.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'SSH Tunnel Host',
                  value: opts.tunnelHost,
                  onChanged: (val) {
                    cmdService.updateNetworkConnectionOptions(opts.copyWith(tunnelHost: val));
                    debugPrint('[NetworkConnectionPanel] Updated NetworkConnectionOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set the IP address of the adb tunnel to reach the scrcpy server. This option automatically enables --force-adb-forward. Default is localhost.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'SSH Tunnel Port',
                  value: opts.tunnelPort,
                  onChanged: (val) {
                    cmdService.updateNetworkConnectionOptions(opts.copyWith(tunnelPort: val));
                    debugPrint('[NetworkConnectionPanel] Updated NetworkConnectionOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set the TCP port of the adb tunnel to reach the scrcpy server. This option automatically enables --force-adb-forward. Default is 0 (not forced).',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
