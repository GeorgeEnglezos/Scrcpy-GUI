import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/command_panel.dart';
import '../../widgets/surrounding_panel.dart';
import '../../services/command_notifier.dart';
import '../../services/device_manager_service.dart';
import '../../services/terminal_service.dart';
import '../../services/commands_service.dart';
import '../../services/log_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import 'package:provider/provider.dart';

class CommandActionsPanel extends StatefulWidget {
  final VoidCallback? onRun;
  final VoidCallback? onFavorite;

  const CommandActionsPanel({
    super.key,
    this.onRun,
    this.onFavorite,
  });

  @override
  State<CommandActionsPanel> createState() => _CommandActionsPanelState();
}

class _CommandActionsPanelState extends State<CommandActionsPanel> {
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.1.',
  );
  final TextEditingController _portController = TextEditingController(
    text: '5555',
  );
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _ipController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommandNotifier>(
      builder: (context, commandNotifier, _) {
        final command = commandNotifier.fullCommand;
        final displayCmd = commandNotifier.displayCommand;

        return SurroundingPanel(
          icon: Icons.terminal,
          title: 'Command',
          panelType: 'Default',
          panelId: 'actions',
          showButton: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              CommandPanel(
                command: command,
                displayCommand: displayCmd,
                showDelete: false,
                onDownload: () =>
                    TerminalService.generateScript(context, command),
              ),
              const SizedBox(height: 12),
              Consumer<DeviceManagerService>(
                builder: (context, deviceManager, _) {
                  final devices =
                      DeviceManagerService.devicesInfo.values.toList();
                  final rawSelected = deviceManager.selectedDevice;
                  final selected = (rawSelected != null &&
                          devices.any((d) => d.deviceId == rawSelected))
                      ? rawSelected
                      : null;
                  final isDeviceSelected =
                      selected != null && selected.isNotEmpty;
                  final isDropdownEnabled = devices.length > 1;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final bool showIpField =
                          SettingsService.currentSettings?.showManualIpInput ??
                          false;
                      final bool showDivider =
                          constraints.maxWidth > (showIpField ? 677 : 535);

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 170),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selected,
                              hint: const Text(
                                'Select Device',
                                overflow: TextOverflow.ellipsis,
                              ),
                              items: devices.map((device) {
                                return DropdownMenuItem<String>(
                                  value: device.deviceId,
                                  child: Text(
                                    device.deviceId,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: isDropdownEnabled
                                  ? (value) {
                                      if (value != null) {
                                        deviceManager.selectedDevice = value;
                                      }
                                    }
                                  : null,
                            ),
                          ),
                          IconButton(
                            onPressed: () => TerminalService.executeCommand(
                              context,
                              command,
                              source: 'CommandPanel/Run',
                            ),
                            icon: const Icon(Icons.play_arrow, size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.runGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              elevation: 2,
                              shadowColor:
                                  AppColors.runGreen.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            tooltip: 'Run Command',
                          ),
                          IconButton(
                            onPressed: widget.onFavorite ??
                                () => _favoriteCommand(context, command),
                            icon: const Icon(Icons.favorite, size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.favoriteRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              elevation: 2,
                              shadowColor: AppColors.favoriteRed
                                  .withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            tooltip: 'Add to Favorites',
                          ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (showDivider)
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.grey.shade400,
                                ),
                              if (showIpField)
                                SizedBox(
                                  width: 130,
                                  child: TextField(
                                    controller: _ipController,
                                    decoration: InputDecoration(
                                      labelText: 'IP (optional)',
                                      hintText: '192.168.1.x',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.blue.shade600,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    keyboardType: TextInputType.text,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d.]'),
                                      ),
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                  ),
                                ),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _portController,
                                  decoration: InputDecoration(
                                    labelText: 'Port',
                                    hintText: '5555',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade600,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(5),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final effectiveIp = showIpField
                                      ? _ipController.text.trim()
                                      : '';
                                  final canConnect =
                                      (isDeviceSelected ||
                                          effectiveIp.isNotEmpty) &&
                                      !_isConnecting;
                                  if (!canConnect) return null;
                                  return () => _connectWirelessly(
                                        context,
                                        selected ?? '',
                                      );
                                }(),
                                icon: const Icon(Icons.wifi, size: 22),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.connectGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.grey.shade300,
                                  disabledForegroundColor:
                                      Colors.grey.shade500,
                                  padding: const EdgeInsets.all(12),
                                  elevation: 2,
                                  shadowColor: AppColors.connectGreen
                                      .withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                tooltip: () {
                                  final ip = showIpField
                                      ? _ipController.text.trim()
                                      : '';
                                  if (isDeviceSelected && ip.isNotEmpty) {
                                    return 'USB + IP: enables TCP/IP on the USB device then connects to $ip';
                                  } else if (ip.isNotEmpty) {
                                    return 'Direct connect to $ip using the entered port';
                                  } else if (isDeviceSelected) {
                                    return 'Auto-detect: enables TCP/IP on the USB device and connects wirelessly';
                                  }
                                  return 'Connect wirelessly\n\n'
                                      'Via USB device (1-click): select the device you want to connect wirelessly\n'
                                      'from the dropdown and the connection will be done automatically\n\n'
                                      'Via Wireless Debugging (Android 11+ - Manual approach):\n'
                                      '  0. If not enabled from the settings, enable the manual IP input\n'
                                      '  1. Developer Options → Wireless Debugging → Enable\n'
                                      '  2. Enter the IPv4 address of your device\n'
                                      '  3. Enter the port shown on the Wireless Debugging screen (not 5555)\n'
                                      '  4. Press this button';
                                }(),
                              ),
                              IconButton(
                                onPressed: isDeviceSelected
                                    ? () =>
                                        _stopConnection(context, selected)
                                    : null,
                                icon: const Icon(Icons.close, size: 22),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.stopRed,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.grey.shade300,
                                  disabledForegroundColor:
                                      Colors.grey.shade500,
                                  padding: const EdgeInsets.all(12),
                                  elevation: 2,
                                  shadowColor: AppColors.stopRed
                                      .withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                tooltip: 'Stop Connection',
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _favoriteCommand(BuildContext context, String command) async {
    LogService.info('CommandPanel/Favorite', 'cmd=$command');
    final commandsService = CommandsService();
    await commandsService.addToFavorites(command);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to favorites: $command'),
        backgroundColor: AppColors.favoriteRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _connectWirelessly(
      BuildContext context, String deviceId) async {
    final showIp = SettingsService.currentSettings?.showManualIpInput ?? false;
    final ip = showIp ? _ipController.text.trim() : '';
    final port = _portController.text.trim();
    LogService.info(
      'CommandPanel/ConnectWireless',
      'device=${LogService.sanitizeDevice(deviceId)} ip=${ip.isEmpty ? '(auto)' : '[redacted]'} port=[redacted]',
    );

    final portNum = int.tryParse(port);
    if (portNum == null || portNum < 1 || portNum > 65535) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            port.isEmpty
                ? 'Port number cannot be empty'
                : 'Invalid port number: $port',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (ip.isEmpty && deviceId.contains(':')) {
      LogService.warning(
          'CommandPanel/ConnectWireless', 'Device is already wireless');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Device is already connected wirelessly. Disconnect first to reconnect.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);

    final bool hasUsbDevice = deviceId.isNotEmpty && !deviceId.contains(':');
    final bool isPureDirectConnect = ip.isNotEmpty && !hasUsbDevice;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPureDirectConnect
              ? 'Connecting to $ip:$portNum...'
              : 'Setting up wireless connection...',
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final Map<String, dynamic> result;

      if (ip.isNotEmpty && hasUsbDevice) {
        result = await TerminalService.setupWirelessConnectionManual(
          deviceId, ip, portNum,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => {
            'success': false,
            'message': 'Connection timed out. Check USB connection and try again.',
          },
        );
      } else if (ip.isNotEmpty) {
        final ipError = TerminalService.validateIpAddress(ip);
        if (ipError != null) {
          result = {'success': false, 'message': ipError};
        } else {
          final connectResult = await TerminalService.connectWireless(
            ip, portNum,
          ).timeout(const Duration(seconds: 15), onTimeout: () => 'timeout');
          final success = connectResult.contains('connected') ||
              connectResult.contains('already connected');
          result = {
            'success': success,
            'message': success
                ? 'Connected to $ip:$portNum'
                : connectResult == 'timeout'
                    ? 'Connection timed out. Make sure the device is reachable at $ip.'
                    : 'Connection failed: $connectResult',
          };
        }
      } else {
        result = await TerminalService.setupWirelessConnection(
          deviceId, portNum,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => {
            'success': false,
            'message': 'Connection timed out. Check USB connection and try again.',
          },
        );
      }

      if (!context.mounted) return;

      final success = result['success'] == true;
      final message = result['message']?.toString() ?? 'Unknown error';

      if (success) {
        LogService.info('CommandPanel/ConnectWireless',
            'Connected: ${LogService.sanitizeMessage(message)}');
      } else {
        LogService.warning('CommandPanel/ConnectWireless',
            'Failed: ${LogService.sanitizeMessage(message)}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );

      if (success && !isPureDirectConnect) {
        Future.delayed(const Duration(seconds: 4), () {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You can now disconnect the USB cable. Wireless device should appear in the device list.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        });
      }
    } catch (e) {
      LogService.error('CommandPanel/ConnectWireless', 'Unexpected error',
          err: e);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up wireless connection: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _stopConnection(
      BuildContext context, String deviceId) async {
    LogService.info('CommandPanel/StopConnection',
        'device=${LogService.sanitizeDevice(deviceId)}');
    if (!deviceId.contains(':')) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected device is not a wireless connection'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disconnecting wireless connection...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );

    final result = await TerminalService.disconnectWireless(deviceId);

    if (!context.mounted) return;

    final success = result['success'] == true;
    final message = result['message']?.toString() ?? 'Unknown error';

    if (success) {
      LogService.info('CommandPanel/StopConnection',
          'Disconnected: ${LogService.sanitizeMessage(message)}');
    } else {
      LogService.warning('CommandPanel/StopConnection',
          'Failed: ${LogService.sanitizeMessage(message)}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
