import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/settings_service.dart';
import '../services/terminal_service.dart';
import '../theme/app_colors.dart';
import '../models/settings_model.dart';

// Import panels
import 'home_panels/audio_commands_panel.dart';
import 'home_panels/command_actions_panel.dart';
import 'home_panels/package_selector_panel.dart';
import 'home_panels/common_commands_panel.dart';
import 'home_panels/recording_commands_panel.dart';
import 'home_panels/virtual_display_commands_panel.dart';
import 'home_panels/instances_panel.dart';
import 'home_panels/camera_commands_panel.dart';
import 'home_panels/input_control_panel.dart';
import 'home_panels/display_window_panel.dart';
import 'home_panels/network_connection_panel.dart';
import 'home_panels/advanced_panel.dart';
import 'home_panels/otg_mode_panel.dart';

class HomePage extends StatefulWidget {
  final List<dynamic>? panelOrder; // Accept dynamic (JSON) from settings
  final VoidCallback? onNavigateToSettings;
  const HomePage({super.key, this.panelOrder, this.onNavigateToSettings});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<PanelSettings> panelOrder = [];
  String? _scrcpyWarning;
  String? _lastScrcpyDir;

  late final Map<String, Widget> allPanels;

  @override
  void initState() {
    super.initState();

    allPanels = {
      'actions': const CommandActionsPanel(),
      'package': const PackageSelectorPanel(),
      'common': const CommonCommandsPanel(),
      'audio': const AudioCommandsPanel(),
      'camera': const CameraCommandsPanel(),
      'input': const InputControlPanel(),
      'display': const DisplayWindowPanel(),
      'network': const NetworkConnectionPanel(),
      'virtual': const VirtualDisplayCommandsPanel(),
      'recording': const RecordingCommandsPanel(),
      'advanced': const AdvancedPanel(),
      'otg': const OtgModePanel(),
      'running': const InstancesPanel(),
    };

    _loadPanelOrder();
    _lastScrcpyDir = SettingsService.currentSettings?.scrcpyDirectory;
    _checkScrcpy();
    SettingsService().appSettingsNotifier.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService().appSettingsNotifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final settings = SettingsService.currentSettings;
    if (settings == null) return;

    if (settings.scrcpyDirectory != _lastScrcpyDir) {
      _lastScrcpyDir = settings.scrcpyDirectory;
      _checkScrcpy();
    }
    setState(_loadPanelOrder);
  }

  Future<void> _checkScrcpy() async {
    final onPath = await TerminalService.isScrcpyOnPath();
    if (!mounted) return;

    // If scrcpy is on PATH, it works regardless of any configured directory.
    if (onPath) {
      setState(() => _scrcpyWarning = null);
      return;
    }

    final dir = SettingsService.currentSettings?.scrcpyDirectory ?? '';
    if (dir.isEmpty) {
      setState(() => _scrcpyWarning =
          'Scrcpy was not found on your system PATH and no directory is configured. '
          'Install scrcpy and add it to PATH, or set the Scrcpy directory in Settings.');
      return;
    }

    final exe = TerminalService.scrcpyExecutable;
    final exists = await File(exe).exists();
    if (!mounted) return;
    setState(() => _scrcpyWarning = exists
        ? null
        : 'Scrcpy not found at "$exe". Set the correct Scrcpy directory in Settings, '
          'or ensure scrcpy is installed and available on your system PATH.');
  }

  /// Re-derives [panelOrder] from the latest settings. Pure — does not call
  /// setState. Callers wrap in setState if a rebuild is needed.
  void _loadPanelOrder() {
    final fromService = SettingsService.currentSettings?.panelOrder;
    final source = fromService ?? widget.panelOrder;

    if (source != null) {
      panelOrder = source
          .map(
            (e) => e is PanelSettings
                ? e
                : PanelSettings.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } else {
      panelOrder = allPanels.keys
          .map(
            (id) => PanelSettings(
              id: id,
              displayName: _getPanelDisplayName(id),
              visible: true,
              isFullWidth: false,
            ),
          )
          .toList();
    }
  }

  String _getPanelDisplayName(String id) {
    switch (id) {
      case 'actions':
        return 'Command Actions';
      case 'package':
        return 'Package Commands';
      case 'common':
        return 'Common Commands';
      case 'audio':
        return 'Audio Commands';
      case 'camera':
        return 'Camera Commands';
      case 'input':
        return 'Input Control';
      case 'display':
        return 'Display/Window';
      case 'network':
        return 'Network/Connection';
      case 'virtual':
        return 'Virtual Display Commands';
      case 'recording':
        return 'Recording Commands';
      case 'advanced':
        return 'Advanced/Developer';
      case 'otg':
        return 'OTG Mode';
      case 'running':
        return 'Running Instances';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSingleColumn = constraints.maxWidth < 1000;
        final int columnCount = isSingleColumn ? 1 : 2;
        final visiblePanels = panelOrder.where((p) => p.visible).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_scrcpyWarning != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _scrcpyWarning!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (widget.onNavigateToSettings != null)
                          TextButton(
                            onPressed: widget.onNavigateToSettings,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: const Text(
                              'Open Settings',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 800),
                      child: SingleChildScrollView(
                        child: StaggeredGrid.count(
                          crossAxisCount: columnCount,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          children: [
                            for (final panel in visiblePanels)
                              if (allPanels.containsKey(panel.id))
                                StaggeredGridTile.fit(
                                  crossAxisCellCount: panel.isFullWidth
                                      ? columnCount
                                      : 1,
                                  child: allPanels[panel.id]!,
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
