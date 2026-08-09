import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/app_snackbar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import '../models/settings_model.dart';
import '../services/log_service.dart';
import '../services/settings_service.dart';
import '../services/shell_runner.dart';
import '../services/color_theme_notifier.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/surrounding_panel.dart';
import '../widgets/directory_row.dart';
import '../widgets/custom_checkbox.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_multi_dropdown.dart';
import 'package:provider/provider.dart';
import '../services/app_icon_controller.dart';
import '../services/app_icon_cache.dart';
import '../services/device_manager_service.dart';

const _uiScaleDefaultLabel = '100% (Default)';

/// Dropdown label mapped to the stored scale factor. Order is the order shown.
const _uiScaleOptions = <String, double>{
  '120%': 1.20,
  '110%': 1.10,
  _uiScaleDefaultLabel: 1.0,
  '95%': 0.95,
  '90%': 0.90,
  '85%': 0.85,
  '80%': 0.80,
};

/// Reverse lookup with a tolerance, so a float that does not compare equal
/// cannot leave the dropdown blank. Falls back to the default rather than to
/// the first entry, which is the largest zoom.
String _uiScaleLabel(double scale) {
  for (final entry in _uiScaleOptions.entries) {
    if ((entry.value - scale).abs() < 0.001) return entry.key;
  }
  return _uiScaleDefaultLabel;
}

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

  @override
  void dispose() {
    _shortcutModController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    var settings = await _settingsService.loadSettings();
    final settingsDir = await _settingsService.getSettingsDirectory();
    final appIconCacheDir = await AppIconCache.cacheDir();

    final withDefaults = SettingsService.withDirectoryDefaults(
      settings,
      settingsDir,
    );
    final defaultsApplied =
        withDefaults.recordingsDirectory != settings.recordingsDirectory ||
        withDefaults.downloadsDirectory != settings.downloadsDirectory ||
        withDefaults.batDirectory != settings.batDirectory;
    settings = withDefaults;

    if (defaultsApplied) {
      // Persist the populated defaults so other consumers see them too.
      await _settingsService.saveSettings(settings);
    }

    await _createDirectoryIfNeeded(settings.recordingsDirectory);
    await _createDirectoryIfNeeded(settings.downloadsDirectory);
    await _createDirectoryIfNeeded(settings.batDirectory);

    setState(() {
      _settings = settings.copyWith(settingsDirectory: settingsDir);
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

  Future<void> _openFolder(String path) async {
    if (path.isEmpty) return;

    final directory = Directory(path);
    if (!await directory.exists()) return;

    try {
      await ShellRunner.openFolder(directory.path);
    } catch (e) {
      LogService.error(
        'SettingsPage/openFolder',
        'Failed to open folder',
        err: e,
      );
      if (mounted) {
        showAppSnackBar(
          context,
          'Failed to open folder: $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  void _movePanelUp(int index) {
    if (index > 0) {
      final reordered = [..._settings.panelOrder];
      final item = reordered.removeAt(index);
      reordered.insert(index - 1, item);
      setState(() {
        _settings = _settings.copyWith(panelOrder: reordered);
      });
      _saveSettings();
    }
  }

  void _movePanelDown(int index) {
    if (index < _settings.panelOrder.length - 1) {
      final reordered = [..._settings.panelOrder];
      final item = reordered.removeAt(index);
      reordered.insert(index + 1, item);
      setState(() {
        _settings = _settings.copyWith(panelOrder: reordered);
      });
      _saveSettings();
    }
  }

  /// Replace one panel in the current order via [PanelSettings.copyWith].
  void _updatePanelAt(int index, PanelSettings Function(PanelSettings) update) {
    final updatedList = [..._settings.panelOrder];
    updatedList[index] = update(updatedList[index]);
    setState(() {
      _settings = _settings.copyWith(panelOrder: updatedList);
    });
    _saveSettings();
  }

  Future<void> _showResetUserInterfaceConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Reset User Interface?',
          style: TextStyle(color: context.appTextPrimary),
        ),
        content: Text(
          'This will reset all panel settings (order, visibility, full width, and lock expanded) to their defaults. Directory settings and other preferences will not be affected.\n\nThis action cannot be undone.',
          style: TextStyle(color: context.appTextSecondary),
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
        backgroundColor: context.appSurface,
        title: Text(
          'Reset All Settings?',
          style: TextStyle(color: context.appTextPrimary),
        ),
        content: Text(
          'This will reset ALL settings to their defaults, including:\n• Panel settings (order, visibility, etc.)\n• Directory paths\n• Functionality preferences\n• Boot tab selection\n\nThis action cannot be undone.',
          style: TextStyle(color: context.appTextSecondary),
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
      return Scaffold(
        backgroundColor: context.appBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.appBackground,
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
                _settings = _settings.copyWith(openCmdWindows: value);
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          CustomCheckbox(
            label: 'Show Scripts tab',
            value: _settings.showBatFilesTab,
            onChanged: (value) {
              final resetBootTab =
                  !value &&
                  (_settings.bootTab == 'Scripts' ||
                      _settings.bootTab == 'Bat Files');
              setState(() {
                _settings = _settings.copyWith(
                  showBatFilesTab: value,
                  bootTab: resetBootTab ? 'Home' : null,
                );
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          CustomCheckbox(
            label: 'Show App Drawer tab',
            value: _settings.showAppDrawerTab,
            onChanged: (value) {
              final resetBootTab = !value && _settings.bootTab == 'App Drawer';
              setState(() {
                _settings = _settings.copyWith(
                  showAppDrawerTab: value,
                  bootTab: resetBootTab ? 'Home' : null,
                );
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
                _settings = _settings.copyWith(showManualIpInput: value);
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
                _settings = _settings.copyWith(checkForUpdatesOnStartup: value);
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final themeNotifier = context.watch<ColorThemeNotifier>();
              return CustomDropdown(
                label: 'Color Theme',
                value: themeNotifier.current.name,
                items: themeNotifier.presets.map((p) => p.name).toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<ColorThemeNotifier>().setPreset(value);
                    setState(() {
                      _settings = _settings.copyWith(colorPreset: value);
                    });
                    _saveSettings();
                  }
                },
              );
            },
          ),
          const SizedBox(height: 16),
          CustomDropdown(
            label: 'UI Scale',
            value: _uiScaleLabel(_settings.uiScale),
            items: _uiScaleOptions.keys.toList(),
            onChanged: (value) {
              final scale = _uiScaleOptions[value];
              if (scale == null) return;
              setState(() {
                _settings = _settings.copyWith(uiScale: scale);
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
                _settings = _settings.copyWith(loggingEnabled: value);
              });
              await LogService.setLoggingEnabled(value);
              await _saveSettings();
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
                  _settings = _settings.copyWith(bootTab: value);
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
                _settings = _settings.copyWith(shortcutMod: selected);
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
              context.read<AppIconController>().setAutoGroupByCategory(value);
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
              context.read<AppIconController>().setShowScripts(value);
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          CustomCheckbox(
            label: 'Include system apps',
            value: context
                .read<AppIconController>()
                .appDrawerSettings
                .includeSystemApps,
            onChanged: (value) async {
              context.read<AppIconController>().setIncludeSystemApps(value);
              setState(() {});
              await context.read<DeviceManagerService>().reloadAllDevices();
            },
          ),
          const SizedBox(height: 24),
          Divider(color: context.appHover),
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
                        backgroundColor: context.appSurface,
                        title: Text(
                          'Clear Internal Cache?',
                          style: TextStyle(color: context.appTextPrimary),
                        ),
                        content: Text(
                          'This will delete all locally cached app icons and labels. You will need to scrape again to restore them.',
                          style: TextStyle(color: context.appTextSecondary),
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
                        showAppSnackBar(
                          context,
                          'App icon and label cache cleared.',
                          type: AppSnackBarType.warning,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text('Clear Internal Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Deletes local icon/label copies. Helpful if scraping failed previously.',
                    style: TextStyle(
                      color: context.appTextSecondary,
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
    final textColor = context.appTextSecondary;
    return Container(
      decoration: BoxDecoration(
        color: context.appInputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appSurface,
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
                      color: context.appPrimary,
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
                        color: context.appPrimary,
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
                        color: context.appPrimary,
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
                        color: context.appPrimary,
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
    final textColor = context.appTextSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: textColor.withValues(alpha: 0.1)),
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
                      ? context.appPrimary
                      : textColor.withValues(alpha: 0.3),
                  onPressed: index > 0 ? () => _movePanelUp(index) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  color: index < _settings.panelOrder.length - 1
                      ? context.appPrimary
                      : textColor.withValues(alpha: 0.3),
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
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: panel.visible,
                onChanged: (value) {
                  _updatePanelAt(
                    index,
                    (p) => p.copyWith(visible: value ?? false),
                  );
                },
                activeColor: context.appPrimary,
                checkColor: context.appOnPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: panel.isFullWidth,
                onChanged: (value) {
                  _updatePanelAt(
                    index,
                    (p) => p.copyWith(isFullWidth: value ?? false),
                  );
                },
                activeColor: context.appPrimary,
                checkColor: context.appOnPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Checkbox(
                value: panel.lockedExpanded,
                onChanged: (value) {
                  _updatePanelAt(
                    index,
                    (p) => p.copyWith(lockedExpanded: value ?? false),
                  );
                },
                activeColor: context.appPrimary,
                checkColor: context.appOnPrimary,
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
          DirectoryRow(
            label: 'Scrcpy Directory',
            path: _settings.scrcpyDirectory.isEmpty
                ? '(using system PATH)'
                : _settings.scrcpyDirectory,
            onOpen: () => _openFolder(_settings.scrcpyDirectory),
            onBrowse: () => _pickDirectory((path) {
              _settings = _settings.copyWith(scrcpyDirectory: path);
              _saveSettings();
            }),
            onClear: _settings.scrcpyDirectory.isNotEmpty
                ? () {
                    setState(() {
                      _settings = _settings.copyWith(scrcpyDirectory: '');
                    });
                    _saveSettings();
                  }
                : null,
          ),
          const SizedBox(height: 16),
          DirectoryRow(
            label: 'Recordings Directory',
            path: _settings.recordingsDirectory,
            onOpen: () => _openFolder(_settings.recordingsDirectory),
            onBrowse: () => _pickDirectory((path) {
              _settings = _settings.copyWith(recordingsDirectory: path);
              _saveSettings();
            }),
          ),
          const SizedBox(height: 16),
          DirectoryRow(
            label: 'Downloads Directory',
            path: _settings.downloadsDirectory,
            onOpen: () => _openFolder(_settings.downloadsDirectory),
            onBrowse: () => _pickDirectory((path) {
              _settings = _settings.copyWith(downloadsDirectory: path);
              _saveSettings();
            }),
          ),
          const SizedBox(height: 16),
          DirectoryRow(
            label: Platform.isWindows
                ? 'Scripts Directory (.bat, .cmd)'
                : 'Scripts Directory (.sh${Platform.isMacOS ? ', .command' : ''})',
            path: _settings.batDirectory,
            onOpen: () => _openFolder(_settings.batDirectory),
            onBrowse: () => _pickDirectory((path) {
              _settings = _settings.copyWith(batDirectory: path);
              _saveSettings();
            }),
          ),
          const SizedBox(height: 16),
          DirectoryRow(
            label: 'App Icons & _labels.json Location',
            path: _appIconCacheDirectory,
            onOpen: () => _openFolder(_appIconCacheDirectory),
            showBrowseButton: false,
          ),
          const SizedBox(height: 16),
          DirectoryRow(
            label: 'Settings Location',
            path: _settings.settingsDirectory,
            showOpenButton: false,
            showBrowseButton: false,
          ),
        ],
      ),
    );
  }
}
