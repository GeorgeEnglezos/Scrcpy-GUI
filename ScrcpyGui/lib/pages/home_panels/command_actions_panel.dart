import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/command_panel.dart';
import '../../widgets/surrounding_panel.dart';
import '../../services/command_builder_service.dart';
import '../../services/device_manager_service.dart';
import '../../services/terminal_service.dart';
import '../../services/commands_service.dart';
import '../../services/settings_service.dart';
import '../../utils/clear_notifier.dart';
import '../../theme/app_colors.dart';
import 'package:provider/provider.dart';

class CommandActionsPanel extends StatefulWidget {
  final VoidCallback? onRun;
  final VoidCallback? onFavorite;
  final ClearController clearController;

  const CommandActionsPanel({
    super.key,
    this.onRun,
    this.onFavorite,
    required this.clearController,
  });

  @override
  State<CommandActionsPanel> createState() => _CommandActionsPanelState();
}

class _CommandActionsPanelState extends State<CommandActionsPanel> {
  final TextEditingController _portController = TextEditingController(text: '5555');

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommandBuilderService>(
      builder: (context, commandService, _) {
        final command = commandService.fullCommand;

        return SurroundingPanel(
          icon: Icons.terminal,
          title: "Command",
          panelType: "Default",
          panelId: "actions",
          showButton: false,
          showClearAllButton: true,
          clearController: widget.clearController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              CommandPanel(
                command: command,
                showDelete: false,
                onDownload: () => _downloadAsBat(context, command),
              ),
              const SizedBox(height: 12),
              Consumer<DeviceManagerService>(
                builder: (context, deviceManager, _) {
                  final devices = DeviceManagerService.devicesInfo.values.toList();
                  final selected = deviceManager.selectedDevice;
                  final isDeviceSelected = selected != null && selected.isNotEmpty;
                  final isDropdownEnabled = devices.length > 1;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate if we have enough width for all items in one row
                      // Dropdown (200) + Run (48) + Favorite (48) + Spacing (24) = ~320
                      // Port section needs: Divider (1) + Port (100) + Wifi (48) + Stop (48) + Spacing (48) = ~245
                      // Total needed: ~565px for one row
                      final bool showDivider = constraints.maxWidth > 565;

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
                            onPressed: () => _runCommand(context, command),
                            icon: const Icon(Icons.play_arrow, size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.runGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              elevation: 2,
                              shadowColor: AppColors.runGreen.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            tooltip: 'Run Command',
                          ),
                          IconButton(
                            onPressed:
                                widget.onFavorite ??
                                () => _favoriteCommand(context, command),
                            icon: const Icon(Icons.favorite, size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.favoriteRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              elevation: 2,
                              shadowColor: AppColors.favoriteRed.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            tooltip: 'Add to Favorites',
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDivider) ...[
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.grey.shade400,
                                  margin: const EdgeInsets.only(right: 12),
                                ),
                              ],
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
                                      borderSide: BorderSide(color: Colors.grey.shade400),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: isDeviceSelected
                                    ? () => _connectWirelessly(context, selected)
                                    : null,
                                icon: const Icon(Icons.wifi, size: 22),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.connectGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade500,
                                  padding: const EdgeInsets.all(12),
                                  elevation: 2,
                                  shadowColor: AppColors.connectGreen.withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                tooltip: 'Connect Wirelessly',
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: isDeviceSelected
                                    ? () => _stopConnection(context, selected)
                                    : null,
                                icon: const Icon(Icons.close, size: 22),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.stopRed,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade500,
                                  padding: const EdgeInsets.all(12),
                                  elevation: 2,
                                  shadowColor: AppColors.stopRed.withValues(alpha: 0.3),
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

  Future<void> _runCommand(BuildContext context, String command) async {
    final commandsService = CommandsService();
    final settings = SettingsService.currentSettings;

    // Track command execution
    await commandsService.trackCommandExecution(command);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Running command...'),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 1),
      ),
    );

    // Use openCmdWindows setting to determine how to run the command
    if (settings?.openCmdWindows ?? false) {
      // Run in new terminal window (tracked for instances panel)
      await TerminalService.runCommandInNewTerminal(command);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Started in new window: $command'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Run in same terminal (original behavior)
      final result = await TerminalService.runCommand(command);

      if (!context.mounted) return;
      if (result.isNotEmpty) {
        _showOutputDialog(context, command, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to run command: $command'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showOutputDialog(BuildContext context, String command, String output) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Output for: $command'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              output.isNotEmpty ? output : 'No output received.',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _favoriteCommand(BuildContext context, String command) async {
    final commandsService = CommandsService();

    // Add to favorites
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

  Future<void> _connectWirelessly(BuildContext context, String deviceId) async {
    final port = _portController.text.trim();

    // Validate port number
    final portNum = int.tryParse(port);
    if (portNum == null || portNum < 1 || portNum > 65535) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid port number: $port'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // Check if device is already wireless
    if (deviceId.contains(':')) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device is already connected wirelessly. Disconnect first to reconnect.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Setting up wireless connection...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Use TerminalService to setup wireless connection
      final result = await TerminalService.setupWirelessConnection(
        deviceId,
        portNum,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          backgroundColor: result['success'] as bool
              ? Colors.green.shade700
              : Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );

      // If successful, show additional instructions
      if (result['success'] as bool) {
        Future.delayed(const Duration(seconds: 4), () {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can now disconnect the USB cable. Wireless device should appear in the device list.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        });
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up wireless connection: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _stopConnection(BuildContext context, String deviceId) async {
    // Check if this is a wireless connection (contains ':')
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] as String),
        backgroundColor: result['success'] as bool
            ? Colors.green.shade700
            : Colors.red.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadAsBat(BuildContext context, String command) async {
    try {
      final settings = SettingsService.currentSettings;
      final downloadsDir = settings?.downloadsDirectory;

      if (downloadsDir == null || downloadsDir.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloads directory not configured in settings'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final directory = Directory(downloadsDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      List<String> nameParts = [];

      if (command.contains('--record')) {
        nameParts.add('recording');
      }

      final packageRegex = RegExp(r'--start-app[=\s]+([^\s]+)');
      final match = packageRegex.firstMatch(command);
      if (match != null) {
        final packageName = match
            .group(1)
            ?.replaceAll('"', '')
            .replaceAll("'", '');
        if (packageName != null && packageName.isNotEmpty) {
          nameParts.add(packageName);
        }
      }

      String baseFilename = nameParts.isEmpty ? 'scrcpy' : nameParts.join('_');

      String filename = baseFilename;
      int counter = 1;
      while (await File('$downloadsDir/$filename.bat').exists()) {
        filename = '$baseFilename ($counter)';
        counter++;
      }

      final file = File('$downloadsDir/$filename.bat');
      await file.writeAsString('@echo off\n$command\npause');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded to ${file.path}'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
