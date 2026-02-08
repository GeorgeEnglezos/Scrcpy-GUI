import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/device_manager_service.dart';
import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';
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
  // Local state for packages is fine as it's data source, not configuration state
  List<String> packages = [];
  Map<String, String> packageLabels = {}; // package -> app name
  Map<String, String> reverseLabels = {}; // app name -> package
  DeviceManagerService? _deviceManager;

  @override
  void initState() {
    super.initState();
    _loadPackages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
      if (mounted) {
        setState(() {
          packages = [];
          packageLabels = {};
          reverseLabels = {};
        });
      }
      return;
    }
    final info = DeviceManagerService.devicesInfo[deviceId];
    if (info != null) {
      if (mounted) {
        setState(() {
          packages = info.packages;
          packageLabels = info.packageLabels;
          // Create reverse mapping: app name -> package name
          reverseLabels = {
            for (var entry in info.packageLabels.entries) entry.value: entry.key
          };
        });
      }
    } else {
      if (mounted) {
        setState(() {
          packages = [];
          packageLabels = {};
          reverseLabels = {};
        });
      }
    }
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

    final opts = context.select<CommandBuilderService, GeneralCastOptions>(
      (s) => s.generalCastOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    final selectedPackage = opts.selectedPackage;
    // Derive the app name from the selected package, or use the package name if not found
    final selectedAppName = packageLabels[selectedPackage] ?? selectedPackage;

    return SurroundingPanel(
      title: "Applications",
      icon: Icons.apps,
      panelType: "Package Selector",
      showButton: false,
      clearController: widget.clearController,
      onClearPressed: () {
        cmdService.updateGeneralCastOptions(
          opts.copyWith(selectedPackage: ''),
        );
        debugPrint('[PackageSelectorPanel] Fields cleared!');
      },
      child: Column(
        children: [
          const SizedBox(height: 20),
          CustomSearchBar(
            hintText: "Search App...",
            value: selectedAppName,
            suggestions: appNames,
            onChanged: (value) {
              // If the user types an app name, try to find its package
              // If not found in reverseLabels, assume it's a raw package name (or partial)
              // The CustomSearchBar likely returns the text in the field.
              // If the user selected from suggestions, value will be an App Name.
              // If the user typed manually, it might be anything.

              // Ideally, we want to map back to package name.
              final pkg = reverseLabels[value] ?? value;

              cmdService.updateGeneralCastOptions(
                opts.copyWith(selectedPackage: pkg),
              );
              debugPrint('[PackageSelectorPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
            },
            onClear: () {
              cmdService.updateGeneralCastOptions(
                opts.copyWith(selectedPackage: ''),
              );
              debugPrint('[PackageSelectorPanel] Updated GeneralCastOptions → ${cmdService.fullCommand}');
            },
            onReload: _loadPackages,
          ),
        ],
      ),
    );
  }
}
