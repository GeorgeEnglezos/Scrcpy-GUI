import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../theme/app_colors.dart';
import '../models/settings_model.dart';
import '../utils/clear_notifier.dart';

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
  const HomePage({super.key, this.panelOrder});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ClearController _clearController = ClearController();
  late List<PanelSettings> panelOrder = [];
  bool _isLoading = true;

  late final Map<String, Widget> allPanels;

  @override
  void initState() {
    super.initState();

    allPanels = {
      'actions': CommandActionsPanel(clearController: _clearController),
      'package': PackageSelectorPanel(clearController: _clearController),
      'common': CommonCommandsPanel(clearController: _clearController),
      'audio': AudioCommandsPanel(clearController: _clearController),
      'camera': CameraCommandsPanel(clearController: _clearController),
      'input': InputControlPanel(clearController: _clearController),
      'display': DisplayWindowPanel(clearController: _clearController),
      'network': NetworkConnectionPanel(clearController: _clearController),
      'virtual': VirtualDisplayCommandsPanel(clearController: _clearController),
      'recording': RecordingCommandsPanel(clearController: _clearController),
      'advanced': AdvancedPanel(clearController: _clearController),
      'otg': OtgModePanel(clearController: _clearController),
      'running': InstancesPanel(clearController: _clearController),
    };

    _loadSettings();
  }

  void _loadSettings() {
    panelOrder = widget.panelOrder != null
        ? widget.panelOrder!
              .map(
                (e) => e is PanelSettings
                    ? e
                    : PanelSettings.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : allPanels.keys
              .map(
                (id) => PanelSettings(
                  id: id,
                  displayName: _getPanelDisplayName(id),
                  visible: true,
                  isFullWidth: false,
                ),
              )
              .toList();

    setState(() => _isLoading = false);
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSingleColumn = constraints.maxWidth < 1000;
        final int columnCount = isSingleColumn ? 1 : 2;
        final visiblePanels = panelOrder.where((p) => p.visible).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(32),
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
        );
      },
    );
  }
}
