/// App Drawer Page
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_snackbar.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/app_drawer_settings_model.dart';
import '../services/app_icon_cache.dart';
import '../services/app_icon_controller.dart';
import '../services/device_manager_service.dart';
import '../services/log_service.dart';
import '../services/icon_fetch_strategy.dart';
import '../services/script_repository.dart';
import '../services/settings_service.dart';
import '../services/adb_service.dart';
import '../services/shell_runner.dart';
import '../utils/command_executor.dart';
import '../services/linux_shortcut_service.dart';
import '../services/macos_shortcut_service.dart';
import '../services/windows_shortcut_service.dart';
import '../theme/app_theme_colors.dart';
import 'app_drawer/app_drawer_dialogs.dart';
import 'app_drawer/app_drawer_tiles.dart';
import 'app_drawer/ctx_menu.dart';
import 'package:url_launcher/url_launcher.dart';

const _kGridMinTileWidth = 110.0;
const _kGroupHeaderBorderRadius = 12.0;
const _kGroupHeaderPadding = 10.0;

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
  final Map<String, String?> _scriptPackageByPath = {};
  final Map<String, File?> _scriptCachedIcons = {};
  bool _scriptIconRefreshScheduled = false;
  List<ScriptGroup> _scriptGroups = [];

  // Session-state checkbox options (not persisted)
  bool _helperApkAutoInstall = false;

  // Custom context menu (right-click / three-dot button).
  final CtxMenuController _ctxMenu = CtxMenuController();

  @override
  void initState() {
    super.initState();
    _cmdController = TextEditingController(
      text: SettingsService.currentAppDrawerSettings?.appLaunchCommand ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceManager = Provider.of<DeviceManagerService>(
        context,
        listen: false,
      );
      _deviceManager!.selectedDeviceNotifier.addListener(_onDeviceChanged);
      _deviceManager!.packagesReloadedTick.addListener(_onPackagesReloaded);
      _loadPackages();
      _loadScriptGroups();
    });
  }

  @override
  void dispose() {
    _ctxMenu.dismiss();
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    _deviceManager?.packagesReloadedTick.removeListener(_onPackagesReloaded);
    _cmdController.dispose();
    super.dispose();
  }

  void _onDeviceChanged() {
    _loadPackages();
  }

  void _onPackagesReloaded() {
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final dm = _deviceManager ?? context.read<DeviceManagerService>();
    final deviceId = dm.selectedDevice;
    final controller = context.read<AppIconController>();

    if (deviceId == null) {
      controller.resetState();
      return;
    }

    final info = DeviceManagerService.devicesInfo[deviceId];
    if (info == null) return;

    LogService.info(
      'AppDrawer/loadPackages',
      'Loading ${info.packages.length} packages for device=${LogService.sanitizeDevice(deviceId)}',
    );

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
    LogService.info(
      'AppDrawer/fetchMissingInfo',
      'Starting fetch (helperApkAutoInstall=$_helperApkAutoInstall)',
    );
    final controller = context.read<AppIconController>();
    await controller.fetchMissing(
      forceUpdate: true,
      helperApkAutoInstall: _helperApkAutoInstall,
      onError: (message) {
        LogService.error('AppDrawer/fetchMissingInfo', message);
        if (!mounted) return;
        showAppSnackBar(
          context,
          message,
          type: AppSnackBarType.error,
          duration: const Duration(seconds: 6),
        );
      },
    );
  }

  Future<void> _reload() async {
    await _loadPackages();
    await _loadScriptGroups();
  }

  Future<void> _saveCommand() async {
    final controller = context.read<AppIconController>();
    final normalized = AdbService.normalizeScrcpyExecutable(
      _cmdController.text.trim(),
    );
    controller.setAppLaunchCommand(normalized);
    _cmdController.text = normalized;
    setState(() => _cmdDirty = false);
  }

  Future<void> _launchApp(String packageName) async {
    final dm = _deviceManager ?? context.read<DeviceManagerService>();
    final deviceId = dm.selectedDevice;
    if (deviceId == null) {
      LogService.warning(
        'AppDrawer/launchApp',
        'No device connected, cannot launch $packageName',
      );
      if (mounted) {
        showAppSnackBar(
          context,
          'No device connected',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    final controller = context.read<AppIconController>();

    var template = controller.appDrawerSettings.appLaunchCommand.trim();
    if (template.isEmpty) template = AppDrawerSettings.defaultCommand;
    template = AdbService.normalizeScrcpyExecutable(template);

    final buffer = StringBuffer(template);

    if (!template.contains('--serial')) {
      buffer.write(' --serial=$deviceId');
    }
    buffer.write(' --start-app=$packageName');
    if (!template.contains('--window-title')) {
      buffer.write(' --window-title=$packageName');
    }

    if (!mounted) return;
    await CommandExecutor.executeCommand(
      context,
      buffer.toString(),
      source: 'AppDrawer/LaunchApp',
    );
  }

  Future<void> _createDesktopShortcut(
    String packageName,
    AppIconController controller,
  ) async {
    final label = (controller.labels[packageName]?.isNotEmpty == true)
        ? controller.labels[packageName]!
        : packageName;

    // Build the same command as _launchApp, but without --serial
    // (the shortcut should work for any connected device at launch time,
    // or the user can edit it, we omit --serial so it is not device-locked).
    var template = controller.appDrawerSettings.appLaunchCommand.trim();
    if (template.isEmpty) template = AppDrawerSettings.defaultCommand;
    template = AdbService.normalizeScrcpyExecutable(template);
    final buffer = StringBuffer(template);
    buffer.write(' --start-app=$packageName');
    if (!template.contains('--window-title')) {
      buffer.write(' "--window-title=$label"');
    }

    final iconFile = controller.icons[packageName]?.path.isNotEmpty == true
        ? controller.icons[packageName]
        : _scriptCachedIcons[packageName];

    final String? error;
    if (Platform.isLinux) {
      error = await LinuxShortcutService.createAppShortcut(
        packageName: packageName,
        label: label,
        scrcpyCommand: buffer.toString(),
        iconPngFile: iconFile,
      );
    } else if (Platform.isMacOS) {
      error = await MacosShortcutService.createAppShortcut(
        packageName: packageName,
        label: label,
        scrcpyCommand: buffer.toString(),
        iconPngFile: iconFile,
      );
    } else {
      error = await WindowsShortcutService.createAppShortcut(
        packageName: packageName,
        label: label,
        scrcpyCommand: buffer.toString(),
        iconPngFile: iconFile,
      );
    }

    if (!mounted) return;
    if (error == null) {
      LogService.info(
        'AppDrawer/createDesktopShortcut',
        'Created shortcut "$label" for $packageName',
      );
      showAppSnackBar(
        context,
        'Shortcut "$label" created on Desktop',
        type: AppSnackBarType.success,
        duration: const Duration(seconds: 3),
      );
    } else {
      LogService.error(
        'AppDrawer/createDesktopShortcut',
        'Failed to create shortcut "$label": $error',
      );
      showAppSnackBar(
        context,
        error,
        type: AppSnackBarType.error,
        duration: const Duration(seconds: 5),
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

  /// Scans the scripts directory off the build path; sync disk I/O in
  /// build() used to hit the disk on every hover/keystroke rebuild.
  Future<void> _loadScriptGroups() async {
    final dir = SettingsService.currentSettings?.batDirectory ?? '';
    final groups = await ScriptRepository.loadGroups(dir);
    if (mounted) setState(() => _scriptGroups = groups);
  }

  /// [_scriptGroups] filtered by the current search query (in memory).
  List<ScriptGroup> _filteredScriptGroups() {
    if (_searchQuery.isEmpty) return _scriptGroups;
    final q = _searchQuery.toLowerCase();
    final result = <ScriptGroup>[];
    for (final group in _scriptGroups) {
      final files = group.files
          .where((f) => p.basename(f.path).toLowerCase().contains(q))
          .toList();
      if (files.isNotEmpty) {
        result.add(
          ScriptGroup(name: group.name, isRoot: group.isRoot, files: files),
        );
      }
    }
    return result;
  }

  Future<void> _launchScript(File script) async {
    if (!mounted) return;
    await CommandExecutor.executeScriptFile(
      context,
      script.path,
      source: 'AppDrawer/LaunchScript',
    );
  }

  String? _extractScriptPackage(File script) =>
      ScriptRepository.packageForScript(script, _scriptPackageByPath);

  File? _iconFromController(AppIconController controller, String? packageName) {
    if (packageName == null) return null;
    final iconEntry = controller.icons[packageName];
    if (iconEntry?.path.isEmpty == true) return null;
    return iconEntry;
  }

  void _scheduleScriptIconRefresh(
    List<File> scripts,
    AppIconController controller,
  ) {
    if (_scriptIconRefreshScheduled) return;
    _scriptIconRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scriptIconRefreshScheduled = false;
      await _hydrateScriptCachedIcons(scripts, controller);
    });
  }

  Future<void> _hydrateScriptCachedIcons(
    List<File> scripts,
    AppIconController controller,
  ) async {
    final packages = <String>{};
    for (final script in scripts) {
      final packageName = _extractScriptPackage(script);
      if (packageName != null) packages.add(packageName);
    }
    if (packages.isEmpty) return;

    // Only look on disk for packages the controller has no icon for.
    final missing = packages
        .where((pkg) => _iconFromController(controller, pkg) == null);
    final changed =
        await ScriptRepository.hydrateCachedIcons(missing, _scriptCachedIcons);
    if (changed && mounted) {
      setState(() {});
    }
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    String pkg,
    AppIconController controller,
  ) {
    final isFav = controller.isFavorite(pkg);
    final currentGroupIndex = controller.groupIndexOf(pkg);

    _ctxMenu.show(context, position, [
      CtxMenuItem(
        icon: isFav ? Icons.favorite : Icons.favorite_border,
        iconColor: isFav ? Colors.pinkAccent : null,
        label: isFav ? 'Remove from Favorites' : 'Add to Favorites',
        onTap: () => controller.toggleFavorite(pkg),
      ),
      CtxMenuItem(
        icon: Icons.copy,
        label: 'Copy Package Name',
        onTap: () {
          Clipboard.setData(ClipboardData(text: pkg));
          showAppSnackBar(
            this.context,
            'Copied: $pkg',
            type: AppSnackBarType.neutral,
            duration: const Duration(seconds: 1),
          );
        },
      ),
      CtxMenuItem(
        icon: Icons.drive_file_move_outline,
        label: 'Move to Group',
        showChevron: true,
        onTap: () => _showMoveToGroupMenu(position, pkg, controller),
      ),
      if (currentGroupIndex >= 0)
        CtxMenuItem(
          icon: Icons.remove_circle_outline,
          label: 'Remove from Group',
          onTap: () => controller.removeFromGroup(pkg),
        ),
      CtxMenuItem(
        icon: Icons.desktop_windows_outlined,
        label: 'Create Desktop Shortcut',
        onTap: () => _createDesktopShortcut(pkg, controller),
      ),
    ]);
  }

  void _showMoveToGroupMenu(
    Offset position,
    String pkg,
    AppIconController controller,
  ) {
    final groups = controller.appDrawerSettings.groups;

    _ctxMenu.show(context, position + const Offset(12, 0), [
      for (var i = 0; i < groups.length; i++)
        CtxMenuItem(
          icon: Icons.folder_outlined,
          iconColor: context.appPrimary,
          label: groups[i].name,
          onTap: () => controller.moveToGroup(pkg, i),
        ),
      CtxMenuItem(
        icon: Icons.create_new_folder_outlined,
        iconColor: context.appPrimary,
        label: 'New Group...',
        onTap: () =>
            showCreateGroupDialog(context, controller, movePackage: pkg),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DeviceManagerService, AppIconController>(
      builder: (context, dm, controller, _) {
        final hasDevice = dm.selectedDevice != null;
        final packages = _filteredPackages(controller);

        return Scaffold(
          backgroundColor: context.appBackground,
          body: Column(
            children: [
              _buildHeader(hasDevice, controller, packages.length),
              if (hasDevice) _buildCommandBar(),
              if (controller.isLoading) _buildLoadingBanner(controller),
              if (!hasDevice)
                _buildNoDevice()
              else if (controller.labels.isEmpty && !controller.isLoading)
                _buildEmpty()
              else if (_isAwaitingFirstLoad(controller))
                _buildManualLoadEmptyState(controller)
              else
                Expanded(child: _buildGroupedContent(controller, packages)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupedContent(
    AppIconController controller,
    List<String> visible,
  ) {
    if (visible.isEmpty) {
      return Center(
        child: Text(
          'No apps match "$_searchQuery"',
          style: TextStyle(color: context.appTextSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gridPadding = 16.0;
        const spacing = 8.0;
        final crossAxisCount = (constraints.maxWidth / _kGridMinTileWidth)
            .floor()
            .clamp(3, 12);
        final tileWidth =
            (constraints.maxWidth -
                gridPadding * 2 -
                spacing * (crossAxisCount - 1)) /
            crossAxisCount;

        final visibleSet = visible.toSet();

        final favPackages = controller.appDrawerSettings.favorites
            .where((pkg) => visibleSet.contains(pkg))
            .toList();

        final groups = controller.appDrawerSettings.groups;
        final groupedPackages = <String>{};
        for (final group in groups) {
          groupedPackages.addAll(group.items);
        }

        final ungrouped = visible
            .where((pkg) => !groupedPackages.contains(pkg))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(gridPadding),
          children: [
            if (favPackages.isNotEmpty) ...[
              _buildPanelSection(
                icon: Icons.favorite,
                title: 'Favorites',
                count: favPackages.length,
                accentColor: Colors.pinkAccent,
                collapsed: false,
                onToggle: null,
                child: _buildWrappedGrid(
                  controller,
                  favPackages,
                  crossAxisCount,
                  spacing,
                  tileWidth,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (controller.appDrawerSettings.showScripts) ...[
              () {
                final scriptGroups = _filteredScriptGroups();
                if (scriptGroups.isEmpty) return const SizedBox.shrink();
                final totalScripts = scriptGroups.fold<int>(
                  0,
                  (sum, g) => sum + g.files.length,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPanelSection(
                      icon: Icons.description_outlined,
                      title: 'Scripts',
                      count: totalScripts,
                      accentColor: context.appPrimary,
                      collapsed: controller.appDrawerSettings.scriptsCollapsed,
                      onToggle: controller.toggleScriptsCollapsed,
                      child: _buildScriptGroupedGrid(
                        controller,
                        scriptGroups,
                        crossAxisCount,
                        spacing,
                        tileWidth,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }(),
            ],
            for (final group in groups) ...[
              () {
                final groupVisible = group.items
                    .where((pkg) => visibleSet.contains(pkg))
                    .toList();
                if (groupVisible.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPanelSection(
                      icon: Icons.folder,
                      title: group.name,
                      count: groupVisible.length,
                      accentColor: context.appPrimary,
                      collapsed: group.collapsed,
                      onToggle: () {
                        final idx = controller.appDrawerSettings.groups.indexOf(
                          group,
                        );
                        if (idx >= 0) controller.toggleGroupCollapsed(idx);
                      },
                      onRename: () {
                        final idx = controller.appDrawerSettings.groups.indexOf(
                          group,
                        );
                        if (idx >= 0) {
                          showRenameGroupDialog(
                            context,
                            controller,
                            idx,
                            (fn) => setState(fn),
                          );
                        }
                      },
                      onDelete: () {
                        final idx = controller.appDrawerSettings.groups.indexOf(
                          group,
                        );
                        if (idx >= 0) {
                          controller.deleteGroup(idx);
                        }
                      },
                      onMoveUp:
                          controller.appDrawerSettings.groups.indexOf(group) > 0
                          ? () {
                              final idx = controller.appDrawerSettings.groups
                                  .indexOf(group);
                              controller.reorderGroup(idx, idx - 1);
                            }
                          : null,
                      onMoveDown:
                          controller.appDrawerSettings.groups.indexOf(group) <
                              controller.appDrawerSettings.groups.length - 1
                          ? () {
                              final idx = controller.appDrawerSettings.groups
                                  .indexOf(group);
                              controller.reorderGroup(idx, idx + 1);
                            }
                          : null,
                      child: _buildWrappedGrid(
                        controller,
                        groupVisible,
                        crossAxisCount,
                        spacing,
                        tileWidth,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }(),
            ],
            if (ungrouped.isNotEmpty && groups.isNotEmpty) ...[
              _buildPanelSection(
                icon: Icons.apps,
                title: 'Other',
                count: ungrouped.length,
                accentColor: context.appPrimary,
                collapsed: controller.appDrawerSettings.otherCollapsed,
                onToggle: controller.toggleOtherCollapsed,
                child: _buildWrappedGrid(
                  controller,
                  ungrouped,
                  crossAxisCount,
                  spacing,
                  tileWidth,
                ),
              ),
            ] else if (ungrouped.isNotEmpty && groups.isEmpty) ...[
              _buildPanelSection(
                icon: Icons.apps,
                title: 'Apps',
                count: ungrouped.length,
                accentColor: context.appPrimary,
                collapsed: false,
                onToggle: null,
                child: _buildWrappedGrid(
                  controller,
                  ungrouped,
                  crossAxisCount,
                  spacing,
                  tileWidth,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildScriptGroupedGrid(
    AppIconController controller,
    List<ScriptGroup> groups,
    int crossAxisCount,
    double spacing,
    double tileWidth,
  ) {
    final allFiles = groups.expand((g) => g.files).toList();
    _scheduleScriptIconRefresh(allFiles, controller);
    final showHeaders =
        groups.length > 1 || (groups.isNotEmpty && !groups.first.isRoot);

    final visibleGroups = groups.where((g) => g.files.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visibleGroups.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildScriptSubGroupColumn(
            controller,
            visibleGroups[i],
            crossAxisCount,
            spacing,
            tileWidth,
            showHeaders,
          ),
        ],
      ],
    );
  }

  Widget _buildScriptSubGroupColumn(
    AppIconController controller,
    ScriptGroup group,
    int cols,
    double spacing,
    double tileWidth,
    bool showHeaders,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.appTextSecondary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeaders)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
              child: Row(
                children: [
                  Icon(
                    group.isRoot
                        ? Icons.folder_special_outlined
                        : Icons.folder_outlined,
                    size: 15,
                    color: context.appTextPrimary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      group.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${group.files.length}',
                    style: TextStyle(
                      color: context.appTextSecondary.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildScriptGrid(
              controller,
              group.files,
              cols.clamp(1, 12),
              spacing,
              tileWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptGrid(
    AppIconController controller,
    List<File> scripts,
    int crossAxisCount,
    double spacing,
    double tileWidth,
  ) {
    final tileHeight = tileWidth / 1.0;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: scripts.map((script) {
        final name = p.basenameWithoutExtension(script.path);
        final packageName = _extractScriptPackage(script);
        final iconFile =
            _iconFromController(controller, packageName) ??
            _scriptCachedIcons[packageName];
        return SizedBox(
          width: tileWidth,
          height: tileHeight,
          child: ScriptTile(
            name: name,
            tileWidth: tileWidth,
            iconFile: iconFile,
            onTap: () => _launchScript(script),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPanelSection({
    required IconData icon,
    required String title,
    required int count,
    required bool collapsed,
    required VoidCallback? onToggle,
    required Widget child,
    required Color accentColor,
    VoidCallback? onRename,
    VoidCallback? onDelete,
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
  }) {
    final headerColor = accentColor;
    final isCollapsible = onToggle != null;
    final showExpandedContent = !isCollapsible || !collapsed;
    final borderRadius = BorderRadius.circular(_kGroupHeaderBorderRadius);

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: headerColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: borderRadius,
            child: Container(
              padding: const EdgeInsets.all(_kGroupHeaderPadding),
              decoration: BoxDecoration(
                color: headerColor.withValues(alpha: 0.1),
                borderRadius: showExpandedContent
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(_kGroupHeaderBorderRadius),
                        topRight: Radius.circular(_kGroupHeaderBorderRadius),
                      )
                    : borderRadius,
                border: showExpandedContent
                    ? Border(
                        bottom: BorderSide(
                          color: headerColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: headerColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.appTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: headerColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: headerColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onRename != null || onDelete != null)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: headerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: headerColor,
                        ),
                        color: context.appSurface,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'rename':
                              onRename?.call();
                              break;
                            case 'delete':
                              onDelete?.call();
                              break;
                            case 'up':
                              onMoveUp?.call();
                              break;
                            case 'down':
                              onMoveDown?.call();
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          if (onMoveUp != null)
                            const PopupMenuItem(
                              value: 'up',
                              child: Text('Move Up'),
                            ),
                          if (onMoveDown != null)
                            const PopupMenuItem(
                              value: 'down',
                              child: Text('Move Down'),
                            ),
                          if (onRename != null)
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                          if (onDelete != null)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red.shade300),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (isCollapsible)
                    Icon(
                      collapsed ? Icons.expand_more : Icons.expand_less,
                      size: 20,
                      color: headerColor,
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ConstrainedBox(
              constraints: showExpandedContent
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 0),
              child: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 12,
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrappedGrid(
    AppIconController controller,
    List<String> packages,
    int crossAxisCount,
    double spacing,
    double tileWidth,
  ) {
    final tileHeight = tileWidth / 1.0;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: packages.map((pkg) {
        final iconEntry = controller.icons[pkg];
        final isSentinel = iconEntry?.path.isEmpty == true;
        return SizedBox(
          width: tileWidth,
          height: tileHeight,
          child: AppTile(
            packageName: pkg,
            label: (controller.labels[pkg]?.isNotEmpty == true)
                ? controller.labels[pkg]!
                : pkg,
            iconFile: isSentinel ? null : iconEntry,
            iconLoading: !controller.icons.containsKey(pkg),
            tileWidth: tileWidth,
            isFavorite: controller.isFavorite(pkg),
            onTap: () => _launchApp(pkg),
            onSecondaryTap: (position) =>
                _showContextMenu(context, position, pkg, controller),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(
    bool hasDevice,
    AppIconController controller,
    int filteredCount,
  ) {
    final totalCount = controller.labels.length;
    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // [LEFT SECTION - Icon, Title, Count]
          Icon(Icons.grid_view, color: context.appPrimary, size: 22),
          const SizedBox(width: 10),
          Text(
            'App Drawer',
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          if (totalCount > 0)
            Text(
              '$filteredCount / $totalCount apps',
              style: TextStyle(color: context.appTextSecondary, fontSize: 13),
            ),

          // [CENTER SPACING]
          const Spacer(),

          // [LOADING INDICATOR]
          if (controller.isLoading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.appPrimary,
                value: controller.total > 0
                    ? controller.progress / controller.total
                    : null,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // [SEARCH BAR - Centered with larger size]
          if (hasDevice && totalCount > 0)
            SizedBox(
              width: 240,
              height: 40,
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: context.appTextPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  hintStyle: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.appTextSecondary,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: context.appInputFill,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          const SizedBox(width: 12),

          // [Cloud download button]
          if (!controller.isLoading && hasDevice && totalCount > 0)
            Tooltip(
              message: 'Fetch missing icons & labels',
              child: IconButton(
                icon: const Icon(Icons.cloud_download, size: 20),
                color: context.appTextSecondary,
                hoverColor: context.appHover,
                onPressed: () => showFetchMissingDialog(context),
              ),
            ),
          if (!controller.isLoading && hasDevice && totalCount > 0)
            const SizedBox(width: 4),

          // [Manage groups button]
          if (!controller.isLoading && hasDevice && totalCount > 0)
            Tooltip(
              message: 'Manage Groups',
              child: IconButton(
                icon: const Icon(Icons.folder_outlined, size: 20),
                color: context.appTextSecondary,
                hoverColor: context.appHover,
                onPressed: () => showManageGroupsDialog(context, controller),
              ),
            ),
          if (!controller.isLoading && hasDevice && totalCount > 0)
            const SizedBox(width: 8),

          // [Reload button]
          if (hasDevice)
            Tooltip(
              message: 'Reload apps',
              child: IconButton(
                icon: Icon(Icons.refresh, color: context.appTextSecondary),
                onPressed: _reload,
                splashRadius: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingBanner(AppIconController controller) {
    final hasProgress = controller.total > 0;
    final status = controller.progressStatus;
    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hasProgress
                        ? (controller.progress / controller.total).clamp(0.0, 1.0)
                        : null,
                    minHeight: 6,
                    backgroundColor: context.appDivider,
                    valueColor: AlwaysStoppedAnimation(context.appPrimary),
                  ),
                ),
              ),
              if (hasProgress) ...[
                const SizedBox(width: 12),
                Text(
                  '${controller.progress} / ${controller.total}',
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
          if (status.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(color: context.appTextSecondary, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            Icon(
              Icons.phone_android,
              size: 64,
              color: context.appTextSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No device connected',
              style: TextStyle(color: context.appTextSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect an Android device to see its apps here.',
              style: TextStyle(
                color: context.appTextSecondary.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isAwaitingFirstLoad(AppIconController controller) {
    if (controller.isLoading) return false;
    if (controller.labels.isEmpty) return false;
    if (controller.icons.isEmpty) return false;
    return controller.icons.values.every((v) => v == null);
  }

  Widget _buildManualLoadEmptyState(AppIconController controller) {
    return Expanded(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apps_outlined,
                  size: 52,
                  color: context.appPrimary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose how to load app data',
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a method below, then tap Load Apps.',
                  style: TextStyle(
                    color: context.appTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMethodCard(
                        controller: controller,
                        method: IconFetchMethod.helperApk,
                        icon: Icons.android,
                        title: 'Helper APK',
                        description:
                            'Uses a small helper app on your device to extract icons and labels directly. Best icon quality and results.',
                        badge: 'Recommended',
                        checkboxes: [
                          CheckboxRow(
                            label: 'Auto-install via ADB',
                            value: _helperApkAutoInstall,
                            onChanged: (v) => setState(
                              () => _helperApkAutoInstall = v ?? false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://github.com/GeorgeEnglezos/android-icon-label-exporter-apk',
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.open_in_new,
                                  size: 12,
                                  color: context.appTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Source: github.com/GeorgeEnglezos/android-icon-label-exporter-apk',
                                    style: TextStyle(
                                      color: context.appTextSecondary,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMethodCard(
                        controller: controller,
                        method: IconFetchMethod.adbScrape,
                        icon: Icons.terminal,
                        title: 'ADB',
                        description:
                            'Pulls each APK from the device via ADB and extracts the launcher icon by scanning the zip for density-specific PNG/WebP files. Falls back to parsing resources.arsc for apps with obfuscated icon paths. Results may vary; for better coverage, try the Helper APK method.',
                        checkboxes: const [],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCachePathInfo(),
                const SizedBox(height: 28),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: _fetchMissingInfo,
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text(
                      'Load Apps',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.appPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required AppIconController controller,
    required IconFetchMethod method,
    required IconData icon,
    required String title,
    required String description,
    String? badge,
    List<Widget>? checkboxes,
  }) {
    final isSelected = controller.appDrawerSettings.iconFetchMethod == method;
    return GestureDetector(
      onTap: () => controller.setIconFetchMethod(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appPrimary.withValues(alpha: 0.12)
              : context.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.appPrimary.withValues(alpha: 0.6)
                : context.appDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: context.appPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 16, color: context.appPrimary),
              ],
            ),
            if (badge != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.appPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: context.appPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: context.appTextSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (checkboxes != null && checkboxes.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...checkboxes,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCachePathInfo() {
    return FutureBuilder<String>(
      future: AppIconCache.cacheDir().then((d) => d.path),
      builder: (context, snap) {
        final path = snap.data ?? '...';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.appDivider),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 16, color: context.appTextSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual icon folder',
                      style: TextStyle(
                        color: context.appTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      path,
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Drop PNG icons named by package name and edit _labels.json to add app names manually.',
                      style: TextStyle(
                        color: context.appTextSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Open folder',
                child: IconButton(
                  icon: Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: context.appTextSecondary,
                  ),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () => ShellRunner.openFolder(path),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apps,
              size: 64,
              color: context.appTextSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No user apps found',
              style: TextStyle(color: context.appTextSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandBar() {
    const defaultCmd = AppDrawerSettings.defaultCommand;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: Container(
        color: context.appSurface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, thickness: 1, color: context.appDivider),
            InkWell(
              onTap: () => setState(() => _commandExpanded = !_commandExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      size: 16,
                      color: context.appTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'App Launch Command',
                      style: TextStyle(
                        color: context.appTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _commandExpanded ? Icons.expand_less : Icons.expand_more,
                      color: context.appTextSecondary,
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
                            color: context.appTextPrimary,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: defaultCmd,
                            hintStyle: TextStyle(
                              color: context.appTextSecondary,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: context.appInputFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Reset to default',
                      child: IconButton(
                        icon: Icon(
                          Icons.restore,
                          size: 20,
                          color: context.appTextSecondary,
                        ),
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
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
