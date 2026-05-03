/// Scrcpy GUI - Cross-platform GUI for scrcpy
/// Author: George Englezos
/// https://github.com/GeorgeEnglezos/Scrcpy-GUI
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrcpy_gui_prod/pages/app_drawer_page.dart';
import 'package:scrcpy_gui_prod/pages/scripts_page.dart';
import 'package:scrcpy_gui_prod/pages/favorites_page.dart';
import 'package:scrcpy_gui_prod/pages/resources_page.dart';
import 'package:scrcpy_gui_prod/pages/shortcuts_page.dart';
import 'package:scrcpy_gui_prod/pages/settings_page.dart';
import 'package:window_manager/window_manager.dart';

import 'models/settings_model.dart';
import 'pages/home_page.dart';
import 'pages/logs_page.dart';
import 'services/app_icon_controller.dart';
import 'services/log_service.dart';
import 'services/command_notifier.dart';
import 'services/device_manager_service.dart';
import 'services/settings_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/sidebar.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop
  await windowManager.ensureInitialized();

  // Configure window options
  const windowOptions = WindowOptions(
    size: Size(1200, 900),
    minimumSize: Size(900, 700),
    center: true,
    title: "Scrcpy GUI",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Load settings
  final settingsService = SettingsService();
  final settings = await settingsService.loadSettings();
  final appDrawerSettings = await settingsService.loadAppDrawerSettings();

  // Initialize logging (must be after loadSettings — depends on currentSettings being populated)
  await LogService.init();

  // Initialize the DeviceManagerService before the app starts
  final deviceManager = DeviceManagerService();
  await deviceManager.initialize();

  // Initialize CommandNotifier — unified state for the new architecture
  final commandNotifier = CommandNotifier();
  commandNotifier.setDeviceManager(deviceManager);
  commandNotifier.loadDefault();

  final iconController = AppIconController(
    appDrawerSettings: appDrawerSettings,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceManagerService>.value(
          value: deviceManager,
        ),
        ChangeNotifierProvider<CommandNotifier>.value(value: commandNotifier),
        ChangeNotifierProvider<AppIconController>.value(value: iconController),
        ChangeNotifierProvider<LogService>.value(value: LogService.instance),
      ],
      child: ScrcpyGuiApp(settings: settings),
    ),
  );
}

/// Main application widget
///
/// Root widget that manages navigation between the four main pages:
/// - Home: Command builder with configurable panels
/// - Favorites: Saved commands and usage history
/// - Resources: Help, documentation, and useful links
/// - Settings: Application configuration
///
/// The initial page is determined by the [settings.bootTab] preference.
class ScrcpyGuiApp extends StatefulWidget {
  /// Application settings loaded from persistent storage
  final AppSettings settings;

  const ScrcpyGuiApp({super.key, required this.settings});

  @override
  State<ScrcpyGuiApp> createState() => _ScrcpyGuiAppState();
}

class _ScrcpyGuiAppState extends State<ScrcpyGuiApp> {
  /// Currently selected page index (0: Home, 1: Favorites, 2: Resources, 3: Settings)
  late int selectedIndex;
  late AppSettings _currentSettings;
  UpdateService? _updateResult;
  bool _hideBanner = false;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settings;
    selectedIndex = _getInitialTabIndex();
    SettingsService().appSettingsNotifier.addListener(_onSettingsChanged);
    _checkUpdateOnStartup();
  }

  @override
  void dispose() {
    SettingsService().appSettingsNotifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    final newSettings = SettingsService.currentSettings;
    if (newSettings == null || !mounted) return;

    final tabsVisibilityChanged =
        newSettings.showBatFilesTab != _currentSettings.showBatFilesTab ||
        newSettings.showAppDrawerTab != _currentSettings.showAppDrawerTab ||
        newSettings.loggingEnabled != _currentSettings.loggingEnabled;

    int newIndex = selectedIndex;
    if (tabsVisibilityChanged) {
      final currentTabs = _visibleTabLabelsFor(_currentSettings);
      final label = selectedIndex < currentTabs.length
          ? currentTabs[selectedIndex]
          : 'Home';
      final newTabs = _visibleTabLabelsFor(newSettings);
      final idx = newTabs.indexOf(label);
      newIndex = idx >= 0 ? idx : 0;
    }

    setState(() {
      _currentSettings = newSettings;
      selectedIndex = newIndex;
    });
  }

  Future<void> _checkUpdateOnStartup() async {
    if (!_currentSettings.checkForUpdatesOnStartup) return;

    // Small delay to allow app to settle
    await Future.delayed(const Duration(seconds: 2));

    final updateResult = await UpdateService.checkForUpdate();

    if (mounted && updateResult.hasUpdate) {
      setState(() {
        _updateResult = updateResult;
      });
    }
  }

  int _getInitialTabIndex() {
    final visibleTabs = _visibleTabLabelsFor(_currentSettings);
    final normalizedBootTab = _normalizeBootTab(_currentSettings.bootTab);
    final index = visibleTabs.indexOf(normalizedBootTab);
    return index >= 0 ? index : 0;
  }

  String _normalizeBootTab(String bootTab) {
    // Legacy support for older persisted value.
    if (bootTab == 'Bat Files') return 'Scripts';
    return bootTab;
  }

  List<String> _visibleTabLabelsFor(AppSettings settings) {
    return [
      'Home',
      'Favorites',
      if (settings.showAppDrawerTab) 'App Drawer',
      if (settings.showBatFilesTab) 'Scripts',
      'Resources',
      'Shortcuts',
      if (settings.loggingEnabled) 'Logs',
      'Settings',
    ];
  }

  /// List of available pages in the application
  ///
  /// Index mapping (when Scripts tab is shown):
  /// - 0: HomePage - Command builder with configurable panels
  /// - 1: FavoritesPage - Saved commands and most used commands
  /// - 2: ScriptsPage - File explorer for scripts (.bat/.cmd on Windows, .sh/.command on macOS/Linux)
  /// - 3: ResourcesPage - Documentation, links, and helpful commands
  /// - 4: SettingsPage - Application preferences and panel customization
  ///
  /// Index mapping (when Scripts tab is hidden):
  /// - 0: HomePage - Command builder with configurable panels
  /// - 1: FavoritesPage - Saved commands and most used commands
  /// - 2: ResourcesPage - Documentation, links, and helpful commands
  /// - 3: SettingsPage - Application preferences and panel customization
  List<Widget> get pages => [
    HomePage(
      panelOrder: _currentSettings.panelOrder,
      onNavigateToSettings: () {
        final tabs = _visibleTabLabelsFor(_currentSettings);
        final idx = tabs.indexOf('Settings');
        if (idx >= 0) setState(() => selectedIndex = idx);
      },
    ),
    const FavoritesPage(),
    if (_currentSettings.showAppDrawerTab) const AppDrawerPage(),
    if (_currentSettings.showBatFilesTab) const ScriptsPage(),
    const ResourcesPage(),
    const ShortcutsPage(),
    if (_currentSettings.loggingEnabled) const LogsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scrcpy GUI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Row(
          children: [
            // Vertical navigation sidebar
            Sidebar(
              selectedIndex: selectedIndex,
              showBatFilesTab: _currentSettings.showBatFilesTab,
              showAppDrawerTab: _currentSettings.showAppDrawerTab,
              showLogsTab: _currentSettings.loggingEnabled,
              onItemSelected: (index) {
                final notifier = Provider.of<CommandNotifier>(
                  context,
                  listen: false,
                );
                if (selectedIndex == 0 && index != 0) {
                  notifier.reset();
                } else if (index == 0 && selectedIndex != 0) {
                  notifier.loadDefault();
                }
                setState(() => selectedIndex = index);
              },
            ),
            // Main content area with animated page transitions
            Expanded(
              child: Column(
                children: [
                  if (_updateResult != null && !_hideBanner) _buildUpdateBanner(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: pages[selectedIndex],
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

  Widget _buildUpdateBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.update,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const Text(
                  'Update Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'v${_updateResult!.latestVersion}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => UpdateService.launchReleasePage(_updateResult?.downloadUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Download Update'),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => setState(() => _hideBanner = true),
            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

}
