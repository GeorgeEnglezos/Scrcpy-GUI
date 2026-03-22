import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import '../models/settings_model.dart';
import '../services/log_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../widgets/surrounding_panel.dart';
import '../widgets/custom_checkbox.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_multi_dropdown.dart';
import 'package:provider/provider.dart';
import '../services/app_icon_controller.dart';
import '../services/app_icon_cache.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  late AppSettings _settings;
  String _appIconCacheDirectory = '';
  bool _isLoading = true;

  final MultiSelectController<String> _shortcutModController =
      MultiSelectController<String>();

  final List<DropdownItem<String>> _shortcutModItems = [
    DropdownItem(label: 'lctrl', value: 'lctrl'),
    DropdownItem(label: 'rctrl', value: 'rctrl'),
    DropdownItem(label: 'lalt', value: 'lalt'),
    DropdownItem(label: 'ralt', value: 'ralt'),
    DropdownItem(label: 'lsuper', value: 'lsuper'),
    DropdownItem(label: 'rsuper', value: 'rsuper'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    final settingsDir = await _settingsService.getSettingsDirectory();
    final appIconCacheDir = await AppIconCache.cacheDir();

    if (settings.recordingsDirectory.isEmpty) {
      settings.recordingsDirectory = '$settingsDir/Recordings';
    }
    if (settings.downloadsDirectory.isEmpty) {
      settings.downloadsDirectory = '$settingsDir/Downloads';
    }
    if (settings.batDirectory.isEmpty) {
      // Default scripts directory to the downloads directory
      if (settings.downloadsDirectory.isNotEmpty) {
        settings.batDirectory = settings.downloadsDirectory;
      } else {
        settings.batDirectory = '$settingsDir/Downloads';
      }
    }

    await _createDirectoryIfNeeded(settings.recordingsDirectory);
    await _createDirectoryIfNeeded(settings.downloadsDirectory);
    await _createDirectoryIfNeeded(settings.batDirectory);

    setState(() {
      _settings = settings;
      _settings.settingsDirectory = settingsDir;
      _appIconCacheDirectory = appIconCacheDir.path;
      _isLoading = false;
    });

    if (settings.shortcutMod.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _shortcutModController.selectWhere(
            (item) => _settings.shortcutMod.contains(item.value),
          );
        }
      });
    }
  }

  Future<void> _createDirectoryIfNeeded(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  Future<void> _saveSettings() async {
    await _settingsService.saveSettings(_settings);
  }

  Future<void> _pickDirectory(Function(String) onSelected) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        onSelected(result);
      });
    }
  }

  // ---------------------------------------------------------
  // ✔ UNIVERSAL OPEN FOLDER FUNCTION — Windows / macOS / Linux
  // ---------------------------------------------------------
  Future<void> _openFolder(String path) async {
    if (path.isEmpty) return;

    final directory = Directory(path);
    if (!await directory.exists()) return;

    try {
      if (Platform.isWindows) {
        final normalized = directory.path.replaceAll('/', '\\');

        // DO NOT add quotes around the path.
        await Process.run('cmd', [
          '/c',
          'start',
          '',
          normalized,
        ], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [directory.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directory.path]);
      }
    } catch (e) {
      LogService.error('SettingsPage/openFolder', 'Failed to open folder', err: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open folder: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _movePanelUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _settings.panelOrder.removeAt(index);
        _settings.panelOrder.insert(index - 1, item);
      });
      _saveSettings();
    }
  }

  void _movePanelDown(int index) {
    if (index < _settings.panelOrder.length - 1) {
      setState(() {
        final item = _settings.panelOrder.removeAt(index);
        _settings.panelOrder.insert(index + 1, item);
      });
      _saveSettings();
    }
  }

  Future<void> _showResetUserInterfaceConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reset User Interface?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset all panel settings (order, visibility, full width, and lock expanded) to their defaults. Directory settings and other preferences will not be affected.\n\nThis action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset User Interface'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _settingsService.resetUserInterface();
      await _loadSettings();
    }
  }

  Future<void> _showResetAllSettingsConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reset All Settings?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset ALL settings to their defaults, including:\n• Panel settings (order, visibility, etc.)\n• Directory paths\n• Functionality preferences\n• Boot tab selection\n\nThis action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All Settings'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _settingsService.resetAllSettings();
      await _loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showResetUserInterfaceConfirmation,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset ONLY User Interface'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showResetAllSettingsConfirmation,
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Reset All Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWideScreen = constraints.maxWidth > 1400;

                if (isWideScreen) {
                  return StaggeredGrid.count(
                    crossAxisCount: 10,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    children: [
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 3,
                        child: _buildFunctionalitySection(),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 3,
                        child: _buildUserInterfaceSection(),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 4,
                        child: _buildDirectorySection(),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 3,
                        child: _buildAppDrawerSection(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildFunctionalitySection(),
                      const SizedBox(height: 24),
                      _buildUserInterfaceSection(),
                      const SizedBox(height: 24),
                      _buildDirectorySection(),
                      const SizedBox(height: 24),
                      _buildAppDrawerSection(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<String> _availableBootTabs() {
    return [
      'Home',
      'Favorites',
      if (_settings.showAppDrawerTab) 'App Drawer',
      if (_settings.showBatFilesTab) 'Scripts',
    ];
  }

  String _resolvedBootTabValue() {
    final availableTabs = _availableBootTabs();
    final normalizedBootTab = _settings.bootTab == 'Bat Files'
        ? 'Scripts'
        : _settings.bootTab;

    if (availableTabs.contains(normalizedBootTab)) return normalizedBootTab;
    return 'Home';
  }

  Widget _buildFunctionalitySection() {
    return SurroundingPanel(
      icon: Icons.settings_suggest,
      title: 'Functionality',
      showButton: false,
      lockedExpanded: true,
      contentPadding: const EdgeInsets.all(12),
      child: Column(
        children: [
          CustomCheckbox(
            label: 'Open CMD windows for scrcpy commands',
            value: _settings.openCmdWindows,
            onChanged: (value) {
              setState(() {
                _settings.openCmdWindows = value;
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          CustomCheckbox(
            label: 'Show Scripts tab',
            value: _settings.showBatFilesTab,
            onChanged: (value) {
              setState(() {
                _settings.showBatFilesTab = value;
                if (!value &&
                    (_settings.bootTab == 'Scripts' ||
                        _settings.bootTab == 'Bat Files')) {
                  _settings.bootTab = 'Home';
                }
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          CustomCheckbox(
            label: 'Show App Drawer tab',
            value: _settings.showAppDrawerTab,
            onChanged: (value) {
              setState(() {
                _settings.showAppDrawerTab = value;
                if (!value && _settings.bootTab == 'App Drawer') {
                  _settings.bootTab = 'Home';
                }
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          CustomCheckbox(
            label: 'Show manual IP input (for wireless debugging)',
            value: _settings.showManualIpInput,
            onChanged: (value) {
              setState(() {
                _settings.showManualIpInput = value;
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          CustomCheckbox(
            label: 'Check for updates on startup',
            value: _settings.checkForUpdatesOnStartup,
            onChanged: (value) {
              setState(() {
                _settings.checkForUpdatesOnStartup = value;
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          CustomCheckbox(
            label: 'Enable logging',
            value: _settings.loggingEnabled,
            onChanged: (value) async {
              setState(() {
                _settings.loggingEnabled = value;
              });
              await LogService.setLoggingEnabled(value);
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          CustomDropdown(
            label: 'Boot Tab',
            value: _resolvedBootTabValue(),
            items: _availableBootTabs(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings.bootTab = value;
                });
                _saveSettings();
              }
            },
          ),
          const SizedBox(height: 16),
          CustomMultiDropdown(
            label: 'Shortcut Mod Key',
            items: _shortcutModItems,
            controller: _shortcutModController,
            onSelectionChange: (selected) {
              setState(() {
                _settings.shortcutMod = selected;
              });
              _saveSettings();
            },
            tooltip:
                'Select one or more modifier keys used for scrcpy shortcuts (e.g. lctrl+rctrl). Defaults to left Alt or left Super if not set.',
          ),
        ],
      ),
    );
  }

  Widget _buildUserInterfaceSection() {
    return SurroundingPanel(
      icon: Icons.dashboard,
      title: 'User Interface',
      showButton: false,
      lockedExpanded: true,
      contentPadding: const EdgeInsets.all(12),
      child: _buildPanelOrderTable(),
    );
  }

  Widget _buildAppDrawerSection() {
    return SurroundingPanel(
      icon: Icons.grid_view,
      title: 'App Drawer',
      showButton: false,
      lockedExpanded: true,
      contentPadding: const EdgeInsets.all(12),
      child: Column(
        children: [
          CustomCheckbox(
            label: 'Auto-group apps by Android category',
            value: context
                .read<AppIconController>()
                .appDrawerSettings
                .autoGroupByCategory,
            onChanged: (value) {
              final controller = context.read<AppIconController>();
              controller.appDrawerSettings.autoGroupByCategory = value;
              controller.saveSettings();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          CustomCheckbox(
            label: 'Show scripts in App Drawer',
            value: context
                .read<AppIconController>()
                .appDrawerSettings
                .showScripts,
            onChanged: (value) {
              final controller = context.read<AppIconController>();
              controller.appDrawerSettings.showScripts = value;
              controller.saveSettings();
              setState(() {});
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.hover),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text(
                          'Clear Internal Cache?',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'This will delete all locally cached app icons and labels. You will need to scrape again to restore them.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Clear Cache'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && mounted) {
                      await context.read<AppIconController>().clearCache();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('App icon and label cache cleared.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text('Clear Internal Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'Deletes local icon/label copies. Helpful if scraping failed previously.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelOrderTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 80),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Panel',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Show',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Full Width',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Lock Expanded',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_settings.panelOrder.length, (index) {
            return _buildPanelRow(index);
          }),
        ],
      ),
    );
  }

  Widget _buildPanelRow(int index) {
    final panel = _settings.panelOrder[index];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  color: index > 0
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  onPressed: index > 0 ? () => _movePanelUp(index) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  color: index < _settings.panelOrder.length - 1
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  onPressed: index < _settings.panelOrder.length - 1
                      ? () => _movePanelDown(index)
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              panel.displayName,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: panel.visible,
                onChanged: (value) {
                  setState(() {
                    panel.visible = value ?? false;
                  });
                  _saveSettings();
                },
                activeColor: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: panel.isFullWidth,
                onChanged: (value) {
                  setState(() {
                    panel.isFullWidth = value ?? false;
                  });
                  _saveSettings();
                },
                activeColor: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: panel.lockedExpanded,
                onChanged: (value) {
                  setState(() {
                    panel.lockedExpanded = value ?? false;
                  });
                  _saveSettings();
                },
                activeColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorySection() {
    return SurroundingPanel(
      icon: Icons.folder,
      title: 'Directory Settings',
      showButton: false,
      lockedExpanded: true,
      contentPadding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildDirectoryRow(
            'Scrcpy Directory',
            _settings.scrcpyDirectory.isEmpty
                ? '(using system PATH)'
                : _settings.scrcpyDirectory,
            onBrowse: () => _pickDirectory((path) {
              _settings.scrcpyDirectory = path;
              _saveSettings();
            }),
            onClear: _settings.scrcpyDirectory.isNotEmpty
                ? () {
                    setState(() => _settings.scrcpyDirectory = '');
                    _saveSettings();
                  }
                : null,
          ),
          const SizedBox(height: 16),
          _buildDirectoryRow(
            'Recordings Directory',
            _settings.recordingsDirectory,
            onBrowse: () => _pickDirectory((path) {
              _settings.recordingsDirectory = path;
              _saveSettings();
            }),
          ),
          const SizedBox(height: 16),
          _buildDirectoryRow(
            'Downloads Directory',
            _settings.downloadsDirectory,
            onBrowse: () => _pickDirectory((path) {
              _settings.downloadsDirectory = path;
              _saveSettings();
            }),
          ),
          const SizedBox(height: 16),
          _buildDirectoryRow(
            Platform.isWindows
                ? 'Scripts Directory (.bat, .cmd)'
                : 'Scripts Directory (.sh${Platform.isMacOS ? ', .command' : ''})',
            _settings.batDirectory,
            onBrowse: () => _pickDirectory((path) {
              _settings.batDirectory = path;
              _saveSettings();
            }),
          ),
          const SizedBox(height: 16),
          _buildDirectoryRow(
            'App Icons & _labels.json Location',
            _appIconCacheDirectory,
            showBrowseButton: false,
          ),
          const SizedBox(height: 16),
          _buildDirectoryRow(
            'Settings Location',
            _settings.settingsDirectory,
            showOpenButton: false,
            showBrowseButton: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryRow(
    String label,
    String path, {
    VoidCallback? onBrowse,
    VoidCallback? onClear,
    bool showOpenButton = true,
    bool showBrowseButton = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  path,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            if (showOpenButton) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _openFolder(path),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Open',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],

            if (showBrowseButton) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onBrowse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Browse...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],

            if (onClear != null) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onClear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
