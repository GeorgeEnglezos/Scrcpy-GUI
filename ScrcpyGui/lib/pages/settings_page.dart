import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../widgets/surrounding_panel.dart';
import '../widgets/custom_checkbox.dart';
import '../widgets/custom_dropdown.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  late AppSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    final settingsDir = await _settingsService.getSettingsDirectory();

    if (settings.scrcpyDirectory.isEmpty) {
      settings.scrcpyDirectory = '$settingsDir/Scrcpy-Installation';
    }
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

    await _createDirectoryIfNeeded(settings.scrcpyDirectory);
    await _createDirectoryIfNeeded(settings.recordingsDirectory);
    await _createDirectoryIfNeeded(settings.downloadsDirectory);
    await _createDirectoryIfNeeded(settings.batDirectory);

    setState(() {
      _settings = settings;
      _settings.settingsDirectory = settingsDir;
      _isLoading = false;
    });
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
      debugPrint('Failed to open folder: $e');
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
            Row(
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
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWideScreen = constraints.maxWidth > 1400;

                if (isWideScreen) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildFunctionalitySection()),
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

  Widget _buildFunctionalitySection() {
    return SurroundingPanel(
      icon: Icons.settings_suggest,
      title: 'Functionality',
      showButton: false,
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
              });
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          CustomDropdown(
            label: 'Boot Tab',
            value: _settings.showBatFilesTab
                ? _settings.bootTab
                : (_settings.bootTab == 'Scripts' || _settings.bootTab == 'Bat Files' ? 'Home' : _settings.bootTab),
            items: _settings.showBatFilesTab
                ? const ['Home', 'Favorites', 'Scripts']
                : const ['Home', 'Favorites'],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings.bootTab = value;
                });
                _saveSettings();
              }
            },
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
      contentPadding: const EdgeInsets.all(12),
      child: _buildPanelOrderTable(),
    );
  }

  Widget _buildPanelOrderTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
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
                  child: Text(
                    'Hide',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Full Width',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Lock Expanded',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
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
          bottom: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1)),
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
                value: !panel.visible,
                onChanged: (value) {
                  setState(() {
                    panel.visible = !(value ?? false);
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
      contentPadding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildDirectoryRow(
            'Scrcpy Directory',
            _settings.scrcpyDirectory,
            onBrowse: () => _pickDirectory((path) {
              _settings.scrcpyDirectory = path;
              _saveSettings();
            }),
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
            Platform.isWindows ? 'Scripts Directory (.bat, .cmd)' : 'Scripts Directory (.sh${Platform.isMacOS ? ', .command' : ''})',
            _settings.batDirectory,
            onBrowse: () => _pickDirectory((path) {
              _settings.batDirectory = path;
              _saveSettings();
            }),
          ),
          const SizedBox(height: 16),
          _buildDirectoryRow(
            'Settings Location',
            _settings.settingsDirectory,
            showButton: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryRow(
    String label,
    String path, {
    VoidCallback? onBrowse,
    bool showButton = true,
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

            if (showButton) ...[
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

            if (showButton) ...[
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
          ],
        ),
      ],
    );
  }
}
