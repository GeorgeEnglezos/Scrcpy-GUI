import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_icon_cache.dart';
import '../../services/device_manager_service.dart';
import '../../services/command_builder_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/surrounding_panel.dart';

class PackageSelectorPanel extends StatefulWidget {
  final ClearController? clearController;

  const PackageSelectorPanel({super.key, this.clearController});

  @override
  State<PackageSelectorPanel> createState() => _PackageSelectorPanelState();
}

class _PackageSelectorPanelState extends State<PackageSelectorPanel> {
  String selectedPackage = '';
  String selectedAppName = '';
  List<String> packages = [];
  Map<String, String> packageLabels = {}; // package -> app name
  Map<String, String> reverseLabels = {}; // app name -> package
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
    });
  }

  void _onDeviceChanged() {
    _loadPackages();
  }

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

    setState(() {
      packages = info.packages;
      packageLabels = info.packageLabels;
      // Create reverse mapping: app name -> package name
      reverseLabels = {
        for (var entry in info.packageLabels.entries) entry.value: entry.key,
      };
    });

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

  void _updateCommandBuilder() {
    final cmdService = Provider.of<CommandBuilderService>(
      context,
      listen: false,
    );
    cmdService.updateGeneralCastOptions(
      cmdService.generalCastOptions.copyWith(selectedPackage: selectedPackage),
    );
  }

  void _clearAllFields() {
    setState(() {
      selectedPackage = '';
      selectedAppName = '';
    });
    _updateCommandBuilder();
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get list of app names for display
    final appNames = packageLabels.values.toList()..sort();

    return SurroundingPanel(
      title: 'Applications',
      icon: Icons.apps,
      panelType: 'Package Selector',
      showButton: false,
      clearController: widget.clearController,
      onClearPressed: _clearAllFields,
      child: Column(
        children: [
          const SizedBox(height: 20),
          CustomSearchBar(
            hintText: 'Search App...',
            value: selectedAppName,
            suggestions: appNames,
            suggestionLeadingBuilder: (appName) {
              final packageName = reverseLabels[appName];
              final iconFile = packageName != null
                  ? _packageIconByName[packageName]
                  : null;
              return _buildPackageIcon(iconFile);
            },
            onChanged: (value) {
              setState(() {
                selectedAppName = value;
                // Convert app name to package name for the command builder
                selectedPackage = reverseLabels[value] ?? value;
              });
              _updateCommandBuilder();
            },
            onClear: () {
              setState(() {
                selectedPackage = '';
                selectedAppName = '';
              });
              _updateCommandBuilder();
            },
            onReload: _loadPackages,
          ),
        ],
      ),
    );
  }
}
