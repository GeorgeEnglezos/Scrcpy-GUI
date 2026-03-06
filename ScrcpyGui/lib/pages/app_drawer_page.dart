/// App Drawer Page
///
/// Displays installed apps on the connected Android device as a searchable
/// icon grid. Tapping an app launches a standalone scrcpy session for that app.
///
/// Icons are loaded from disk cache via AppIconController. Repeat visits are
/// instant. Use "Scrape Missing Info" to fetch icons not yet cached.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_icon_controller.dart';
import '../services/device_manager_service.dart';
import '../services/settings_service.dart';
import '../services/terminal_service.dart';
import '../theme/app_colors.dart';

const _kGridMinTileWidth = 110.0;

class AppDrawerPage extends StatefulWidget {
  const AppDrawerPage({super.key});

  @override
  State<AppDrawerPage> createState() => _AppDrawerPageState();
}

class _AppDrawerPageState extends State<AppDrawerPage> {
  String _searchQuery = '';
  DeviceManagerService? _deviceManager;
  bool _commandExpanded = false;
  late TextEditingController _cmdController;
  bool _cmdDirty = false;

  @override
  void initState() {
    super.initState();
    _cmdController = TextEditingController(
      text: SettingsService.currentSettings?.appDrawerSettings.appLaunchCommand ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceManager = Provider.of<DeviceManagerService>(context, listen: false);
      _deviceManager!.selectedDeviceNotifier.addListener(_onDeviceChanged);
      _loadPackages();
    });
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    _cmdController.dispose();
    super.dispose();
  }

  void _onDeviceChanged() => _loadPackages();

  Future<void> _loadPackages() async {
    final dm = _deviceManager ?? Provider.of<DeviceManagerService>(context, listen: false);
    final deviceId = dm.selectedDevice;
    final controller = Provider.of<AppIconController>(context, listen: false);

    if (deviceId == null) {
      controller.resetState();
      return;
    }

    final info = DeviceManagerService.devicesInfo[deviceId];
    if (info == null) return;

    final sorted = List<String>.from(info.packages)
      ..sort((a, b) {
        final la = info.packageLabels[a] ?? a;
        final lb = info.packageLabels[b] ?? b;
        return la.toLowerCase().compareTo(lb.toLowerCase());
      });

    setState(() => _searchQuery = '');
    await controller.loadForDevice(deviceId, sorted);
  }

  Future<void> _fetchMissingInfo() async {
    final controller = Provider.of<AppIconController>(context, listen: false);
    await controller.fetchMissing(forceUpdate: true);
  }

  Future<void> _reload() async {
    _loadPackages();
  }

  Future<void> _clearIconCache() async {
    final controller = Provider.of<AppIconController>(context, listen: false);
    await controller.clearCache();
    _loadPackages();
  }

  Future<void> _saveCommand() async {
    final settings = SettingsService.currentSettings;
    if (settings == null) return;
    settings.appDrawerSettings.appLaunchCommand = _cmdController.text.trim();
    await SettingsService().saveSettings(settings);
    setState(() => _cmdDirty = false);
  }

  Future<void> _launchApp(String packageName) async {
    final dm = _deviceManager ?? Provider.of<DeviceManagerService>(context, listen: false);
    final deviceId = dm.selectedDevice;
    if (deviceId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No device connected'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final controller = Provider.of<AppIconController>(context, listen: false);
    final label = controller.labels[packageName] ?? packageName;

    // Build command from saved template
    final settings = SettingsService.currentSettings;
    var template = (settings?.appDrawerSettings.appLaunchCommand ?? '').trim();
    if (template.isEmpty) {
      template = 'scrcpy --pause-on-exit=if-error --new-display=1920x1080';
    }

    final buffer = StringBuffer(template);

    if (!template.contains('--serial')) {
      buffer.write(' --serial=$deviceId');
    }
    buffer.write(' --start-app=$packageName');
    if (!template.contains('--window-title')) {
      buffer.write(' --window-title=$label');
    }

    final cmd = buffer.toString();
    debugPrint('[AppDrawer] Launching: $cmd');
    await TerminalService.runCommandInNewTerminal(cmd);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Launching $label…'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<String> _filteredPackages(AppIconController controller) {
    final packages = controller.labels.keys.toList();
    if (_searchQuery.isEmpty) return packages;
    final q = _searchQuery.toLowerCase();
    return packages.where((pkg) {
      final label = (controller.labels[pkg] ?? pkg).toLowerCase();
      return label.contains(q) || pkg.toLowerCase().contains(q);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer2<DeviceManagerService, AppIconController>(
      builder: (context, dm, controller, _) {
        final hasDevice = dm.selectedDevice != null;
        final packages = _filteredPackages(controller);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildHeader(hasDevice, controller, packages.length),
              if (hasDevice) _buildCommandBar(),
              if (!hasDevice)
                _buildNoDevice()
              else if (controller.labels.isEmpty && !controller.isLoading)
                _buildEmpty()
              else
                Expanded(child: _buildGrid(controller, packages)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool hasDevice, AppIconController controller, int filteredCount) {
    final totalCount = controller.labels.length;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Icon(Icons.grid_view, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'App Drawer',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          if (totalCount > 0)
            Text(
              '$filteredCount / $totalCount apps',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          const Spacer(),
          if (controller.isLoading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading icons…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(width: 12),
          ],
          if (!controller.isLoading && hasDevice && totalCount > 0) ...[
            Tooltip(
              message: 'Check web for missing icons & names',
              child: IconButton(
                icon: const Icon(Icons.cloud_download, size: 20),
                color: AppColors.textSecondary,
                hoverColor: AppColors.hover,
                onPressed: _fetchMissingInfo,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Search field
          if (hasDevice && totalCount > 0)
            SizedBox(
              width: 220,
              height: 36,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search apps…',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Clear icon cache button
          if (hasDevice)
            Tooltip(
              message: 'Clear icon cache',
              child: IconButton(
                icon: Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
                onPressed: _clearIconCache,
                splashRadius: 18,
              ),
            ),
          // Reload button
          if (hasDevice)
            Tooltip(
              message: 'Reload apps',
              child: IconButton(
                icon: Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: _reload,
                splashRadius: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoDevice() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No device connected',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect an Android device to see its apps here.',
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apps, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No user apps found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandBar() {
    const defaultCmd = 'scrcpy --pause-on-exit=if-error --new-display=1920x1080';
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, thickness: 1, color: AppColors.divider),
            InkWell(
              onTap: () => setState(() => _commandExpanded = !_commandExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.terminal, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'App Launch Command',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _commandExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_commandExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus && _cmdDirty) _saveCommand();
                        },
                        child: TextField(
                          controller: _cmdController,
                          onChanged: (_) => setState(() => _cmdDirty = true),
                          onEditingComplete: () {
                            if (_cmdDirty) _saveCommand();
                            FocusScope.of(context).unfocus();
                          },
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: defaultCmd,
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.divider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Reset to default',
                      child: IconButton(
                        icon: Icon(Icons.restore, size: 20, color: AppColors.textSecondary),
                        splashRadius: 18,
                        onPressed: () {
                          setState(() {
                            _cmdController.text = defaultCmd;
                            _cmdDirty = true;
                          });
                          _saveCommand();
                        },
                      ),
                    ),
                    Tooltip(
                      message:
                          '--serial, --start-app, and --window-title\n(if not present) are appended automatically',
                      child: Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(AppIconController controller, List<String> visible) {
    if (visible.isEmpty) {
      return Center(
        child: Text(
          'No apps match "$_searchQuery"',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gridPadding = 16.0;
        const spacing = 8.0;
        final crossAxisCount = (constraints.maxWidth / _kGridMinTileWidth).floor().clamp(3, 12);
        final tileWidth = (constraints.maxWidth - gridPadding * 2 - spacing * (crossAxisCount - 1)) / crossAxisCount;
        return GridView.builder(
          padding: const EdgeInsets.all(gridPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 0.82,
          ),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final pkg = visible[index];
            final iconEntry = controller.icons[pkg];
            final isSentinel = iconEntry?.path.isEmpty == true;
            return _AppTile(
              packageName: pkg,
              label: (controller.labels[pkg]?.isNotEmpty == true) ? controller.labels[pkg]! : pkg,
              iconFile: isSentinel ? null : iconEntry,
              iconLoading: !controller.icons.containsKey(pkg),
              tileWidth: tileWidth,
              onTap: () => _launchApp(pkg),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _AppTile
// ---------------------------------------------------------------------------

class _AppTile extends StatefulWidget {
  final String packageName;
  final String label;
  final File? iconFile;
  final bool iconLoading;
  final double tileWidth;
  final VoidCallback onTap;

  const _AppTile({
    required this.packageName,
    required this.label,
    required this.iconFile,
    required this.iconLoading,
    required this.tileWidth,
    required this.onTap,
  });

  @override
  State<_AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<_AppTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.divider,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Stack(
            children: [
              // Icon centered in the space above the label area
              Positioned.fill(
                bottom: 34,
                child: Center(child: _buildIcon()),
              ),
              // Label pinned to bottom, max 2 lines (~34 px), text flows top-down
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 34,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    widget.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    // Icon occupies ~55% of the tile width, clamped to a sensible range.
    final size = (widget.tileWidth * 0.55).clamp(32.0, 96.0);

    if (widget.iconLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    if (widget.iconFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          widget.iconFile!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder(size),
        ),
      );
    }

    return _placeholder(size);
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.android, color: AppColors.primary.withValues(alpha: 0.6), size: size * 0.6),
    );
  }
}
