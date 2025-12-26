import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/scrcpy_instance_model.dart';
import '../../services/terminal_service.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/surrounding_panel.dart';

class InstancesPanel extends StatefulWidget {
  final ClearController? clearController;
  const InstancesPanel({super.key, this.clearController});

  @override
  State<InstancesPanel> createState() => _InstancesPanelState();
}

class _InstancesPanelState extends State<InstancesPanel> {
  List<ScrcpyInstance> _instances = [];
  Timer? _refreshTimer;
  bool _isExpanded = true;
  final Set<int> _selectedPids = {};

  @override
  void initState() {
    super.initState();
    _refreshInstances();
    // Auto-refresh every 5 seconds (reduced from 2 for better performance)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshInstances();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshInstances() async {
    if (!mounted) return;

    try {
      final processes = await TerminalService.getScrcpyProcesses();
      if (!mounted) return;

      setState(() {
        _instances = processes
            .map((proc) {
                final pid = int.tryParse(proc['pid'] ?? '0') ?? 0;

                // Parse start time
                DateTime? startTime;
                final startTimeStr = proc['startTime'];
                if (startTimeStr != null && startTimeStr.length >= 14) {
                  try {
                    final year = int.parse(startTimeStr.substring(0, 4));
                    final month = int.parse(startTimeStr.substring(4, 6));
                    final day = int.parse(startTimeStr.substring(6, 8));
                    final hour = int.parse(startTimeStr.substring(8, 10));
                    final minute = int.parse(startTimeStr.substring(10, 12));
                    final second = int.parse(startTimeStr.substring(12, 14));
                    startTime = DateTime(year, month, day, hour, minute, second);
                  } catch (_) {
                    // Silently fail on parse error
                  }
                }

                // Parse connection type
                ConnectionType connectionType = ConnectionType.unknown;
                final connTypeStr = proc['connectionType'];
                if (connTypeStr == 'wireless') {
                  connectionType = ConnectionType.wireless;
                } else if (connTypeStr == 'usb') {
                  connectionType = ConnectionType.usb;
                }

                return ScrcpyInstance(
                  pid: pid,
                  command: proc['name'] ?? 'scrcpy',
                  deviceId: proc['deviceId'] ?? 'Unknown',
                  fullCommand: proc['fullCommand'],
                  windowTitle: proc['windowTitle'],
                  connectionType: connectionType,
                  startTime: startTime,
                  memoryUsage: double.tryParse(proc['memoryUsage'] ?? ''),
                );
              })
            .where((instance) => instance.pid != 0)
            .toList();

        // Remove selected PIDs that no longer exist
        _selectedPids.removeWhere(
          (pid) => !_instances.any((inst) => inst.pid == pid),
        );
      });
    } catch (_) {
      // Silently handle errors
    }
  }

  void _killInstance(int pid) async {
    if (!mounted) return;
    await TerminalService.killProcess(pid);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _refreshInstances();
    }
  }

  Future<void> _killAllInstances() async {
    if (!mounted) return;
    for (final pid in _selectedPids) {
      await TerminalService.killProcess(pid);
    }
    _selectedPids.clear();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _refreshInstances();
    }
  }

  Future<void> _killAllSelectedOrAll() async {
    if (!mounted) return;
    if (_selectedPids.isEmpty) {
      // Kill all instances
      for (final instance in _instances) {
        if (!mounted) return;
        await TerminalService.killProcess(instance.pid);
      }
    } else {
      // Kill selected instances
      await _killAllInstances();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _refreshInstances();
    }
  }

  void _rerunCommand(ScrcpyInstance instance) async {
    if (!mounted) return;
    if (instance.fullCommand != null) {
      // Run command without opening new terminal window
      await TerminalService.runCommand(instance.fullCommand!);
      // Give it a moment to start, then refresh
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        _refreshInstances();
      }
    }
  }

  void _clearAllFields() {
    _selectedPids.clear();
    _refreshInstances();
  }

  @override
  Widget build(BuildContext context) {
    return SurroundingPanel(
      icon: Icons.phone_android,
      title: 'Running Instances',
      panelType: "Running Instances",
      showButton: true,
      onClearPressed: _clearAllFields,
      clearController: widget.clearController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _instances.isEmpty
                    ? 'No running instances'
                    : '${_instances.length} instance(s) running',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  if (_instances.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.unfold_less : Icons.unfold_more,
                      ),
                      tooltip: _isExpanded ? 'Compact View' : 'Expanded View',
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                  if (_instances.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_sweep, color: Colors.red.shade300),
                      tooltip: 'Kill All Instances',
                      onPressed: _killAllSelectedOrAll,
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: _refreshInstances,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_instances.isNotEmpty)
            Column(
              children: _instances.map((instance) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      instance.windowTitle ?? 'PID: ${instance.pid}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: instance.connectionType == ConnectionType.wireless
                                          ? Colors.blue.withValues(alpha: 0.3)
                                          : Colors.green.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      instance.connectionTypeString,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Device: ${instance.deviceId}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  // Memory usage only available on Windows
                                  if (_isExpanded && instance.memoryUsage != null)
                                    Text(
                                      'Mem: ${instance.memoryUsage!.toStringAsFixed(0)} MB',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                              if (_isExpanded) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Uptime: ${instance.uptimeString}',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'PID: ${instance.pid}',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_isExpanded) ...[
                          IconButton(
                            onPressed: instance.fullCommand != null
                                ? () => _rerunCommand(instance)
                                : null,
                            icon: const Icon(Icons.refresh, size: 20),
                            color: Colors.green.shade300,
                            tooltip: 'Rerun Command',
                          ),
                          IconButton(
                            onPressed: () => _killInstance(instance.pid),
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.red.shade300,
                            tooltip: 'Kill Process',
                          ),
                        ] else
                          IconButton(
                            onPressed: () => _killInstance(instance.pid),
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.red.shade300,
                            tooltip: 'Kill Process',
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
