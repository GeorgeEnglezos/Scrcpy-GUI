/// App Drawer Page
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../services/app_icon_cache.dart';
import '../services/app_icon_controller.dart';
import '../services/device_manager_service.dart';
import '../services/icon_fetch_strategy.dart';
import '../services/settings_service.dart';
import '../services/terminal_service.dart';
import '../services/linux_shortcut_service.dart';
import '../services/macos_shortcut_service.dart';
import '../services/windows_shortcut_service.dart';
import '../theme/app_colors.dart';
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
  static final RegExp _startAppArgPattern = RegExp(
    r'''(?:^|\s)-{1,2}start-app=(?:"([^"]+)"|'([^']+)'|([^\s]+))''',
    caseSensitive: false,
  );

  String _searchQuery = '';
  DeviceManagerService? _deviceManager;
  bool _commandExpanded = false;
  late TextEditingController _cmdController;
  bool _cmdDirty = false;
  final Map<String, String?> _scriptPackageByPath = {};
  final Map<String, File?> _scriptCachedIcons = {};
  bool _scriptIconRefreshScheduled = false;

  // Session-state checkbox options (not persisted)
  bool _helperApkAutoInstall = false;

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
      _loadPackages();
    });
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    _cmdController.dispose();
    super.dispose();
  }

  void _onDeviceChanged() {
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final dm =
        _deviceManager ??
        Provider.of<DeviceManagerService>(context, listen: false);
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
    await controller.fetchMissing(
      forceUpdate: true,
      helperApkAutoInstall: _helperApkAutoInstall,
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      },
    );
  }

  Future<void> _reload() async {
    _loadPackages();
  }

  Future<void> _saveCommand() async {
    final controller = Provider.of<AppIconController>(context, listen: false);
    controller.appDrawerSettings.appLaunchCommand = _cmdController.text.trim();
    await controller.saveSettings();
    setState(() => _cmdDirty = false);
  }

  Future<void> _launchApp(String packageName) async {
    final dm =
        _deviceManager ??
        Provider.of<DeviceManagerService>(context, listen: false);
    final deviceId = dm.selectedDevice;
    if (deviceId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No device connected'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final controller = Provider.of<AppIconController>(context, listen: false);

    var template = controller.appDrawerSettings.appLaunchCommand.trim();
    if (template.isEmpty) {
      template = 'scrcpy --pause-on-exit=if-error --new-display=1920x1080';
    }

    final buffer = StringBuffer(template);

    if (!template.contains('--serial')) {
      buffer.write(' --serial=$deviceId');
    }
    buffer.write(' --start-app=$packageName');
    if (!template.contains('--window-title')) {
      buffer.write(' --window-title=$packageName');
    }

    if (!mounted) return;
    await TerminalService.executeCommand(context, buffer.toString());
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
    // or the user can edit it — we omit --serial so it is not device-locked).
    var template = controller.appDrawerSettings.appLaunchCommand.trim();
    if (template.isEmpty) {
      template = 'scrcpy --pause-on-exit=if-error --new-display=1920x1080';
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shortcut "$label" created on Desktop'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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

  List<File> _loadScriptFiles() {
    final settings = SettingsService.currentSettings;
    if (settings == null) return [];
    final dir = Directory(settings.batDirectory);
    if (!dir.existsSync()) return [];

    final extensions = Platform.isWindows
        ? ['.bat', '.cmd']
        : Platform.isMacOS
        ? ['.sh', '.command']
        : ['.sh'];

    final files =
        dir
            .listSync()
            .whereType<File>()
            .where(
              (f) =>
                  extensions.any((ext) => f.path.toLowerCase().endsWith(ext)),
            )
            .toList()
          ..sort(
            (a, b) => p
                .basename(a.path)
                .toLowerCase()
                .compareTo(p.basename(b.path).toLowerCase()),
          );

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return files
          .where((f) => p.basename(f.path).toLowerCase().contains(q))
          .toList();
    }
    return files;
  }

  Future<void> _launchScript(File script) async {
    if (!mounted) return;
    await TerminalService.executeScriptFile(context, script.path);
  }

  String? _extractStartAppPackage(String scriptText) {
    final match = _startAppArgPattern.firstMatch(scriptText);
    if (match == null) return null;
    return match.group(1) ?? match.group(2) ?? match.group(3);
  }

  String? _extractScriptPackage(File script) {
    if (_scriptPackageByPath.containsKey(script.path)) {
      return _scriptPackageByPath[script.path];
    }
    try {
      final contents = script.readAsStringSync();
      final packageName = _extractStartAppPackage(contents);
      _scriptPackageByPath[script.path] = packageName;
      return packageName;
    } catch (_) {
      _scriptPackageByPath[script.path] = null;
      return null;
    }
  }

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

    final missing = packages.where((pkg) {
      if (_scriptCachedIcons.containsKey(pkg)) return false;
      return _iconFromController(controller, pkg) == null;
    }).toList();
    if (missing.isEmpty) return;

    var changed = false;
    for (final packageName in missing) {
      final cached = await AppIconCache.getCachedIconIfExists(packageName);
      _scriptCachedIcons[packageName] = cached;
      changed = true;
    }
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

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: AppColors.surface,
      items: [
        PopupMenuItem(
          onTap: () => controller.toggleFavorite(pkg),
          child: Row(
            children: [
              Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: isFav ? Colors.pinkAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                isFav ? 'Remove from Favorites' : 'Add to Favorites',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Clipboard.setData(ClipboardData(text: pkg));
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text('Copied: $pkg'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Row(
            children: [
              Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Copy Package Name',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!mounted) return;
              _showMoveToGroupMenu(position, pkg, controller);
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.drive_file_move_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Move to Group',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        if (currentGroupIndex >= 0)
          PopupMenuItem(
            onTap: () => controller.removeFromGroup(pkg),
            child: Row(
              children: [
                Icon(
                  Icons.remove_circle_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Remove from Group',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
          PopupMenuItem(
            onTap: () {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!mounted) return;
                _createDesktopShortcut(pkg, controller);
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.desktop_windows_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Create Desktop Shortcut',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showScriptContextMenu(
    BuildContext context,
    Offset position,
    File script,
    AppIconController controller,
  ) {
    final isFav = controller.isScriptFavorite(script.path);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: AppColors.surface,
      items: [
        PopupMenuItem(
          onTap: () => controller.toggleScriptFavorite(script.path),
          child: Row(
            children: [
              Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: isFav ? Colors.pinkAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                isFav ? 'Remove from Favorites' : 'Add to Favorites',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!mounted) return;
              _showScriptMoveToGroupMenu(position, script, controller);
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.drive_file_move_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Move to Group',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showScriptMoveToGroupMenu(
    Offset position,
    File script,
    AppIconController controller,
  ) {
    final groups = controller.appDrawerSettings.groups;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 10,
        position.dy,
        position.dx + 10,
        position.dy,
      ),
      color: AppColors.surface,
      items: [
        for (var i = 0; i < groups.length; i++)
          PopupMenuItem(
            onTap: () {
              if (!groups[i].items.contains(script.path)) {
                groups[i].items.add(script.path);
                controller.saveSettings();
              }
            },
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  groups[i].name,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!mounted) return;
              _showCreateGroupDialog(script.path, controller);
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.create_new_folder_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'New Group...',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMoveToGroupMenu(
    Offset position,
    String pkg,
    AppIconController controller,
  ) {
    final groups = controller.appDrawerSettings.groups;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 10,
        position.dy,
        position.dx + 10,
        position.dy,
      ),
      color: AppColors.surface,
      items: [
        for (var i = 0; i < groups.length; i++)
          PopupMenuItem(
            onTap: () => controller.moveToGroup(pkg, i),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  groups[i].name,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        PopupMenuItem(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!mounted) return;
              _showCreateGroupDialog(pkg, controller);
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.create_new_folder_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'New Group...',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateGroupDialog(
    String? movePackage,
    AppIconController controller,
  ) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'New Group',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Group name',
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
          onSubmitted: (_) {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              controller.createGroup(name);
              if (movePackage != null) {
                controller.moveToGroup(
                  movePackage,
                  controller.appDrawerSettings.groups.length - 1,
                );
              }
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                controller.createGroup(name);
                if (movePackage != null) {
                  controller.moveToGroup(
                    movePackage,
                    controller.appDrawerSettings.groups.length - 1,
                  );
                }
                Navigator.pop(ctx);
              }
            },
            child: Text('Create', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showManageGroupsDialog(AppIconController controller) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final groups = controller.appDrawerSettings.groups;
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                Icon(Icons.folder_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Manage Groups',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              height: 400,
              child: Column(
                children: [
                  Expanded(
                    child: groups.isEmpty
                        ? Center(
                            child: Text(
                              'No groups yet. Create one below.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: groups.length,
                            itemBuilder: (ctx, index) {
                              final group = groups[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.folder,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _showRenameGroupDialog(
                                          controller,
                                          index,
                                          setDialogState,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                group.name,
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '(${group.items.length})',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (group.isAutoGenerated) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'auto',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_upward,
                                        size: 18,
                                        color: index > 0
                                            ? AppColors.textSecondary
                                            : AppColors.divider,
                                      ),
                                      onPressed: index > 0
                                          ? () {
                                              controller.reorderGroup(
                                                index,
                                                index - 1,
                                              );
                                              setDialogState(() {});
                                            }
                                          : null,
                                      splashRadius: 16,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_downward,
                                        size: 18,
                                        color: index < groups.length - 1
                                            ? AppColors.textSecondary
                                            : AppColors.divider,
                                      ),
                                      onPressed: index < groups.length - 1
                                          ? () {
                                              controller.reorderGroup(
                                                index,
                                                index + 1,
                                              );
                                              setDialogState(() {});
                                            }
                                          : null,
                                      splashRadius: 16,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red.shade300,
                                      ),
                                      onPressed: () {
                                        controller.deleteGroup(index);
                                        setDialogState(() {});
                                      },
                                      splashRadius: 16,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCreateGroupDialog(
                        null,
                        controller,
                      ).then((_) => setDialogState(() {})),
                      icon: Icon(Icons.add, size: 18, color: AppColors.primary),
                      label: Text(
                        'Add Group',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Done', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRenameGroupDialog(
    AppIconController controller,
    int index,
    void Function(void Function()) setDialogState,
  ) {
    final nameController = TextEditingController(
      text: controller.appDrawerSettings.groups[index].name,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Rename Group',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Group name',
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
          onSubmitted: (_) {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              controller.renameGroup(index, name);
              setDialogState(() {});
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                controller.renameGroup(index, name);
                setDialogState(() {});
                Navigator.pop(ctx);
              }
            },
            child: Text('Rename', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

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
          style: TextStyle(color: AppColors.textSecondary),
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
                final scripts = _loadScriptFiles();
                if (scripts.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPanelSection(
                      icon: Icons.description_outlined,
                      title: 'Scripts',
                      count: scripts.length,
                      accentColor: AppColors.primary,
                      collapsed: controller.appDrawerSettings.scriptsCollapsed,
                      onToggle: () {
                        controller.appDrawerSettings.scriptsCollapsed =
                            !controller.appDrawerSettings.scriptsCollapsed;
                        controller.saveSettings();
                      },
                      child: _buildScriptGrid(
                        controller,
                        scripts,
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
                      accentColor: AppColors.primary,
                      collapsed: group.collapsed,
                      onToggle: () {
                        group.collapsed = !group.collapsed;
                        controller.saveSettings();
                      },
                      onRename: () {
                        final idx = controller.appDrawerSettings.groups.indexOf(
                          group,
                        );
                        if (idx >= 0) {
                          _showRenameGroupDialog(
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
                accentColor: AppColors.primary,
                collapsed: controller.appDrawerSettings.otherCollapsed,
                onToggle: () {
                  controller.appDrawerSettings.otherCollapsed =
                      !controller.appDrawerSettings.otherCollapsed;
                  controller.saveSettings();
                },
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
                accentColor: AppColors.primary,
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

  Widget _buildScriptGrid(
    AppIconController controller,
    List<File> scripts,
    int crossAxisCount,
    double spacing,
    double tileWidth,
  ) {
    _scheduleScriptIconRefresh(scripts, controller);
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
          child: _ScriptTile(
            name: name,
            tileWidth: tileWidth,
            iconFile: iconFile,
            onTap: () => _launchScript(script),
            scriptPath: script.path,
            isFavorite: controller.isScriptFavorite(script.path),
            onSecondaryTap: (position) =>
                _showScriptContextMenu(context, position, script, controller),
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
                              color: AppColors.textPrimary,
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
                        color: AppColors.surface,
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
          child: _AppTile(
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

  Future<void> _showFetchMissingDialog() async {
    final controller = Provider.of<AppIconController>(context, listen: false);

    final missingCount = controller.labels.keys.where((pkg) {
      final hasIcon =
          controller.icons[pkg] != null &&
          controller.icons[pkg]!.path.isNotEmpty;
      final hasLabel = controller.labels[pkg] != pkg;
      return !hasIcon || !hasLabel;
    }).length;

    var autoInstall = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              'Fetch Missing Icons & Labels',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    missingCount > 0
                        ? '$missingCount app${missingCount == 1 ? '' : 's'} '
                            'have missing icons or labels.'
                        : 'All apps are up to date.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fetch method',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:
                            controller.appDrawerSettings.iconFetchMethod.name,
                        isDense: true,
                        isExpanded: true,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        dropdownColor: AppColors.surface,
                        items: const [
                          DropdownMenuItem(
                            value: 'helperApk',
                            child: Text('Helper APK'),
                          ),
                          DropdownMenuItem(
                            value: 'adbScrape',
                            child: Text('ADB'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              controller.appDrawerSettings.iconFetchMethod =
                                  iconFetchMethodFromString(value);
                            });
                            controller.saveSettings();
                          }
                        },
                      ),
                    ),
                  ),
                  if (controller.appDrawerSettings.iconFetchMethod ==
                      IconFetchMethod.helperApk) ...[
                    const SizedBox(height: 10),
                    _buildCheckboxRow(
                      label: 'Auto-install via ADB',
                      value: autoInstall,
                      onChanged: (v) =>
                          setDialogState(() => autoInstall = v ?? false),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => launchUrl(Uri.parse('https://github.com/GeorgeEnglezos/android-icon-label-exporter-apk')),
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Source: github.com/GeorgeEnglezos/android-icon-label-exporter-apk',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: missingCount > 0
                    ? () {
                        Navigator.pop(ctx);
                        controller.fetchMissingOnly(
                          helperApkAutoInstall: autoInstall,
                          onError: (message) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 6),
                              ),
                            );
                          },
                        );
                      }
                    : null,
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: missingCount > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    bool hasDevice,
    AppIconController controller,
    int filteredCount,
  ) {
    final totalCount = controller.labels.length;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // [LEFT SECTION - Icon, Title, Count]
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

          // [CENTER SPACING]
          const Spacer(),

          // [LOADING INDICATOR]
          if (controller.isLoading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
                value: controller.total > 0
                    ? controller.progress / controller.total
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              controller.total > 0
                  ? '${controller.progress} / ${controller.total}'
                  : 'Loading...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
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
          const SizedBox(width: 12),

          // [Cloud download button]
          if (!controller.isLoading && hasDevice && totalCount > 0)
            Tooltip(
              message: 'Fetch missing icons & labels',
              child: IconButton(
                icon: const Icon(Icons.cloud_download, size: 20),
                color: AppColors.textSecondary,
                hoverColor: AppColors.hover,
                onPressed: _showFetchMissingDialog,
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
                color: AppColors.textSecondary,
                hoverColor: AppColors.hover,
                onPressed: () => _showManageGroupsDialog(controller),
              ),
            ),
          if (!controller.isLoading && hasDevice && totalCount > 0)
            const SizedBox(width: 8),

          // [Reload button]
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
            Icon(
              Icons.phone_android,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No device connected',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect an Android device to see its apps here.',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
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
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose how to load app data',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a method below, then tap Load Apps.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
                          _buildCheckboxRow(
                            label: 'Auto-install via ADB',
                            value: _helperApkAutoInstall,
                            onChanged: (v) => setState(
                              () => _helperApkAutoInstall = v ?? false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => launchUrl(Uri.parse('https://github.com/GeorgeEnglezos/android-icon-label-exporter-apk')),
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new, size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Source: github.com/GeorgeEnglezos/android-icon-label-exporter-apk',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
                            'Pulls each APK from the device via ADB and extracts the launcher icon by scanning the zip for density-specific PNG/WebP files. Falls back to parsing resources.arsc for apps with obfuscated icon paths. Results may vary — for better coverage, try the Helper APK method.',
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
                      backgroundColor: AppColors.primary,
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
      onTap: () {
        controller.appDrawerSettings.iconFetchMethod = method;
        controller.saveSettings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 16, color: AppColors.primary),
              ],
            ),
            if (badge != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: AppColors.primary,
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
                color: AppColors.textSecondary,
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

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required void Function(bool?) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppColors.primary,
              side: BorderSide(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual icon folder',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      path,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Drop PNG icons named by package name and edit _labels.json to add app names manually.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
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
                    color: AppColors.textSecondary,
                  ),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: () async {
                    if (Platform.isWindows) {
                      await Process.run('explorer', [path]);
                    } else if (Platform.isMacOS) {
                      await Process.run('open', [path]);
                    }
                  },
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
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
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
    const defaultCmd =
        'scrcpy --pause-on-exit=if-error --new-display=1920x1080';
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
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
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
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
                        icon: Icon(
                          Icons.restore,
                          size: 20,
                          color: AppColors.textSecondary,
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
                        color: AppColors.textSecondary,
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

class _AppTile extends StatefulWidget {
  final String packageName;
  final String label;
  final File? iconFile;
  final bool iconLoading;
  final double tileWidth;
  final bool isFavorite;
  final VoidCallback onTap;
  final void Function(Offset position) onSecondaryTap;

  const _AppTile({
    required this.packageName,
    required this.label,
    required this.iconFile,
    required this.iconLoading,
    required this.tileWidth,
    required this.isFavorite,
    required this.onTap,
    required this.onSecondaryTap,
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
        onSecondaryTapUp: (details) =>
            widget.onSecondaryTap(details.globalPosition),
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
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              if (widget.isFavorite)
                Positioned(
                  top: 0,
                  left: _hovered ? 0 : null,
                  right: _hovered ? null : 0,
                  child: Icon(
                    Icons.favorite,
                    size: 14,
                    color: Colors.pinkAccent,
                  ),
                ),
              if (_hovered)
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTapUp: (details) =>
                        widget.onSecondaryTap(details.globalPosition),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(bottom: 26, child: Center(child: _buildIcon())),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 26,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
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
      child: Icon(
        Icons.android,
        color: AppColors.primary.withValues(alpha: 0.6),
        size: size * 0.6,
      ),
    );
  }
}

class _ScriptTile extends StatefulWidget {
  final String name;
  final double tileWidth;
  final File? iconFile;
  final VoidCallback onTap;
  final String scriptPath;
  final bool isFavorite;
  final void Function(Offset position) onSecondaryTap;

  const _ScriptTile({
    required this.name,
    required this.tileWidth,
    required this.iconFile,
    required this.onTap,
    required this.scriptPath,
    required this.isFavorite,
    required this.onSecondaryTap,
  });

  @override
  State<_ScriptTile> createState() => _ScriptTileState();
}

class _ScriptTileState extends State<_ScriptTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = (widget.tileWidth * 0.55).clamp(32.0, 96.0);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) =>
            widget.onSecondaryTap(details.globalPosition),
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
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 34,
                child: Center(
                  child: widget.iconFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            widget.iconFile!,
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                _scriptPlaceholder(size),
                          ),
                        )
                      : _scriptPlaceholder(size),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 26,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      widget.name,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scriptPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.description_outlined,
        color: Colors.blue.withValues(alpha: 0.7),
        size: size * 0.5,
      ),
    );
  }
}
