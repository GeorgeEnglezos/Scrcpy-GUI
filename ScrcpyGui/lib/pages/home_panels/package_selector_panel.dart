import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_icon_cache.dart';
import '../../services/command_notifier.dart';
import '../../services/device_manager_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/surrounding_panel.dart';

class PackageSelectorPanel extends StatefulWidget {
  const PackageSelectorPanel({super.key});

  @override
  State<PackageSelectorPanel> createState() => _PackageSelectorPanelState();
}

class _PackageSelectorPanelState extends State<PackageSelectorPanel> {
  List<String> packages = [];
  Map<String, String> packageLabels = {}; // package -> label
  Map<String, String> reverseLabels = {}; // label -> package
  final Map<String, File?> _packageIconByName = {};
  DeviceManagerService? _deviceManager;

  @override
  void initState() {
    super.initState();
    _loadPackages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceManager = Provider.of<DeviceManagerService>(
        context,
        listen: false,
      );
      _deviceManager?.selectedDeviceNotifier.addListener(_onDeviceChanged);
      _deviceManager?.packagesReloadedTick.addListener(_onPackagesReloaded);
    });
  }

  void _onDeviceChanged() => _loadPackages();

  void _onPackagesReloaded() => _loadPackages();

  Future<void> _loadPackages() async {
    final deviceManager = Provider.of<DeviceManagerService>(
      context,
      listen: false,
    );
    final deviceId = deviceManager.selectedDevice;
    if (deviceId == null) {
      setState(() {
        packages = [];
        packageLabels = {};
        reverseLabels = {};
        _packageIconByName.clear();
      });
      // Don't clear selectedPackage here — there's simply no device to
      // validate against. A real device switch will hit the path below.
      return;
    }

    final info = DeviceManagerService.devicesInfo[deviceId];
    if (info == null) {
      setState(() {
        packages = [];
        packageLabels = {};
        reverseLabels = {};
        _packageIconByName.clear();
      });
      return;
    }

    final cachedLabels = await AppIconCache.loadCachedLabels();
    final mergedLabels = {
      for (var entry in info.packageLabels.entries)
        entry.key: (entry.value == entry.key &&
                cachedLabels[entry.key]?.isNotEmpty == true)
            ? cachedLabels[entry.key]!
            : entry.value,
    };

    setState(() {
      packages = info.packages;
      packageLabels = mergedLabels;
      reverseLabels = {
        for (var entry in mergedLabels.entries) entry.value: entry.key,
      };
    });

    // If a preset/previous device left a selectedPackage that doesn't exist
    // on this device, clear it so the command preview stays in sync.
    if (mounted) {
      final notifier = context.read<CommandNotifier>();
      final current = notifier.current.selectedPackage;
      if (current.isNotEmpty && !info.packages.contains(current)) {
        notifier.update(notifier.current.copyWith(selectedPackage: ''));
      }
    }

    await _hydratePackageIcons(info.packages);
  }

  Future<void> _hydratePackageIcons(List<String> packageNames) async {
    final results = await Future.wait(
      packageNames.map((packageName) async {
        final iconFile = await AppIconCache.getCachedIconIfExists(packageName);
        return MapEntry(packageName, iconFile);
      }),
    );

    if (!mounted) return;

    setState(() {
      _packageIconByName
        ..clear()
        ..addAll(Map.fromEntries(results));
    });
  }

  Widget _buildPackageIcon(File? iconFile) {
    if (iconFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          iconFile,
          width: 18,
          height: 18,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.android, size: 18, color: AppColors.textSecondary),
        ),
      );
    }
    return Icon(Icons.android, size: 18, color: AppColors.textSecondary);
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    _deviceManager?.packagesReloadedTick.removeListener(_onPackagesReloaded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;
    final suggestions = packageLabels.values.toList()..sort();
    // Derive the displayed value from the canonical command state so a
    // preset load or device-switch reset is reflected immediately.
    final displayLabel = cmd.selectedPackage.isEmpty
        ? ''
        : (packageLabels[cmd.selectedPackage] ?? cmd.selectedPackage);

    return SurroundingPanel(
      title: 'Applications',
      icon: Icons.apps,
      panelType: 'Package Selector',
      showButton: false,
      onClearPressed: () =>
          notifier.update(cmd.copyWith(selectedPackage: '')),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CustomSearchBar(
            hintText: 'Search App...',
            value: displayLabel,
            suggestions: suggestions,
            suggestionMatcher: (label, query) {
              final q = query.toLowerCase();
              final pkg = reverseLabels[label] ?? '';
              return label.toLowerCase().contains(q) ||
                  pkg.toLowerCase().contains(q);
            },
            suggestionLeadingBuilder: (appName) {
              final packageName = reverseLabels[appName];
              final iconFile =
                  packageName != null ? _packageIconByName[packageName] : null;
              return _buildPackageIcon(iconFile);
            },
            onChanged: (value) {
              final packageName = reverseLabels[value] ?? value;
              notifier.update(cmd.copyWith(selectedPackage: packageName));
            },
            onClear: () =>
                notifier.update(cmd.copyWith(selectedPackage: '')),
            onReload: _loadPackages,
          ),
        ],
      ),
    );
  }
}
