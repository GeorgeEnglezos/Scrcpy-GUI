/// Network connection settings panel for TCP/IP and tunnel configuration.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

class NetworkConnectionPanel extends StatefulWidget {
  const NetworkConnectionPanel({super.key});

  @override
  State<NetworkConnectionPanel> createState() =>
      _NetworkConnectionPanelState();
}

class _NetworkConnectionPanelState extends State<NetworkConnectionPanel> {
  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;

    return SurroundingPanel(
      icon: Icons.wifi,
      title: 'Network/Connection',
      showButton: true,
      panelType: 'Network/Connection',
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(
        tcpipPort: '',
        selectTcpip: false,
        tunnelHost: '',
        tunnelPort: '',
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'TCP/IP Port',
                  value: cmd.tcpipPort,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(tcpipPort: val)),
                  tooltip: 'Set the TCP port (range) used by the client to listen. Default is 27183:27199.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Select TCP/IP Device',
                  value: cmd.selectTcpip,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(selectTcpip: val)),
                  tooltip: 'Use TCP/IP device (if there is exactly one, like adb -e).',
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'SSH Tunnel Host',
                  value: cmd.tunnelHost,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(tunnelHost: val)),
                  tooltip: 'Set the IP address of the adb tunnel to reach the scrcpy server. This option automatically enables --force-adb-forward. Default is localhost.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'SSH Tunnel Port',
                  value: cmd.tunnelPort,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(tunnelPort: val)),
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
