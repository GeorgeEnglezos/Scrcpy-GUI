import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../widgets/app_snackbar.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import '../models/settings_model.dart';
import '../services/log_service.dart';
import '../services/settings_service.dart';
import '../services/shell_runner.dart';
import '../services/color_theme_notifier.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/surrounding_panel.dart';
import '../widgets/directory_row.dart';
import '../widgets/setup_wizard_dialog.dart';
import '../widgets/custom_checkbox.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_multi_dropdown.dart';
import '../widgets/ui_scale_dropdown.dart';
import 'package:provider/provider.dart';
import '../services/app_icon_controller.dart';
import '../services/app_icon_cache.dart';
import '../services/device_manager_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  late AppSettings _settings;
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

    final withDefaults = SettingsService.withDirectoryDefaults(
      settings,
      settingsDir,
    );
    final defaultsApplied =
        withDefaults.recordingsDirectory != settings.recordingsDirectory ||
        withDefaults.downloadsDirectory != settings.downloadsDirectory ||
        withDefaults.batDirectory != settings.batDirectory ||
        withDefaults.appIconsDirectory != settings.appIconsDirectory;
    settings = withDefaults;

    if (defaultsApplied) {
      // Persist the populated defaults so other consumers see them too.
      await _settingsService.saveSettings(settings);
    }

    await _createDirectoryIfNeeded(settings.recordingsDirectory);
    await _createDirectoryIfNeeded(settings.downloadsDirectory);
    await _createDirectoryIfNeeded(settings.batDirectory);
    await _createDirectoryIfNeeded(
      AppIconCache.cachePathIn(settings.appIconsDirectory),
    );

    setState(() {
      _settings = settings.copyWith(settingsDirectory: settingsDir);
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

  /// Creates [path] if it is missing, logging rather than throwing.
  ///
  /// A directory can point at a drive that is no longer plugged in, and this
  /// runs before the page leaves its loading state: throwing here would strand
  /// Settings on a spinner, which is worse than a missing folder.
  Future<void> _createDirectoryIfNeeded(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      LogService.error(
        'SettingsPage/createDirectory',
        'Could not create $path',
        err: e,
      );
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

  /// Points the icon cache at a new location, bringing the existing icons and
  /// labels along.
  ///
  /// Copied before the switch, because only the active cache is ever read:
  /// leaving them behind would look exactly like losing every icon. Has its own
  /// handler rather than reusing [_pickDirectory], whose callback runs inside
  /// setState and so cannot await the copy.
  Future<void> _pickAppIconsDirectory() async {
    final target = await FilePicker.platform.getDirectoryPath();
    if (target == null || p.equals(target, _settings.appIconsDirectory)) return;

    final previous = _settings.appIconsDirectory;
    await AppIconCache.copyCache(previous, target);

    // Persisted before the mounted gate: the copy already happened, so
    // returning early here would leave the duplicate on disk with the setting
    // still pointing at the old location.
    _settings = _settings.copyWith(appIconsDirectory: target);
    await _saveSettings();
    if (!mounted) return;

    setState(() {});
    showAppSnackBar(
      context,
      'App icons moved to ${AppIconCache.cachePathIn(target)}. The copies in '
      '$previous were left in place.',
      type: AppSnackBarType.info,
    );
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

  /// Reopens the first-run wizard, then reloads so the page shows whatever
  /// the wizard changed.
  Future<void> _runSetupAgain() async {
    await showSetupWizard(context);
    if (!mounted) return;
    await _loadSettings();
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

  Future<void> _showResetPanelLayoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Reset panel layout?',
          style: TextStyle(color: context.appTextPrimary),
        ),
        content: Text(
          'Puts the home page panels back to their default order, visibility, full width, and lock expanded.\n\nNothing else changes: directories, appearance, app drawer, and every other setting stay as they are.\n\nThis action cannot be undone.',
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
            child: const Text('Reset Panel Layout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _settingsService.resetPanelLayout();
      await _loadSettings();
    }
  }

  Future<void> _showResetAllSettingsConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Reset everything to defaults?',
          style: TextStyle(color: context.appTextPrimary),
        ),
        content: Text(
          'Puts the whole app back to how it was on a fresh install:\n• Panel layout\n• Directory paths (folders and their files are kept)\n• Appearance (theme and UI scale)\n• Functionality preferences and boot tab\n• App drawer settings\n\nThis action cannot be undone.',
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
            child: const Text('Reset Everything'),
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
                    onPressed: _runSetupAgain,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('Run Setup Again'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showResetPanelLayoutConfirmation,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset Panel Layout Only'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showResetAllSettingsConfirmation,
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Reset Everything to Defaults'),
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
                  // Three fixed columns rather than a staggered grid: App
                  // Drawer must sit under Functionality at the same width, and
                  // a staggered grid places it by height instead.
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildFunctionalitySection(),
                            const SizedBox(height: 24),
                            _buildAppDrawerSection(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: _buildUserInterfaceSection()),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildDirectorySection()),
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
          UiScaleDropdown(
            scale: _settings.uiScale,
            onChanged: (scale) {
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
            label: 'App Icons & Labels',
            // The cache folder itself, not the location holding it, because
            // that is the folder Open should reveal and the one icons land in.
            path: AppIconCache.cachePathIn(_settings.appIconsDirectory),
            onOpen: () =>
                _openFolder(AppIconCache.cachePathIn(_settings.appIconsDirectory)),
            onBrowse: _pickAppIconsDirectory,
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
