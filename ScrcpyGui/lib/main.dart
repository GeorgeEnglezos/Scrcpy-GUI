/// Scrcpy GUI Flutter Port
///
/// A comprehensive cross-platform desktop GUI application for managing and controlling
/// Android devices via scrcpy (Screen Copy). This application provides an intuitive
/// interface for building and executing scrcpy commands without memorizing command-line
/// flags and parameters.
///
/// Author: George Englezos
/// Repository: https://github.com/GeorgeEnglezos/Scrcpy-GUI
///
/// Platform Support:
/// - Windows
/// - macOS
/// - Linux
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrcpy_gui_prod/pages/scripts_page.dart';
import 'package:scrcpy_gui_prod/pages/favorites_page.dart';
import 'package:scrcpy_gui_prod/pages/resources_page.dart';
import 'package:scrcpy_gui_prod/pages/settings_page.dart';
import 'package:window_manager/window_manager.dart';

import 'models/settings_model.dart';
import 'pages/home_page.dart';
import 'services/command_builder_service.dart';
import 'services/device_manager_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'widgets/sidebar.dart';

/// Application entry point
///
/// Initializes the desktop window manager, device detection service, and settings,
/// then launches the application with state management providers.
///
/// Initialization sequence:
/// 1. Ensures Flutter bindings are initialized
/// 2. Configures desktop window (size: 1200x900, min: 900x700)
/// 3. Initializes DeviceManagerService (starts ADB polling)
/// 4. Loads user settings from persistent storage
/// 5. Sets up Provider state management
/// 6. Launches the main application
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

  // Initialize the DeviceManagerService before the app starts
  final deviceManager = DeviceManagerService();
  await deviceManager.initialize();

  // Load settings
  final settingsService = SettingsService();
  final settings = await settingsService.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceManagerService>.value(
          value: deviceManager,
        ),
        ChangeNotifierProvider(create: (_) => CommandBuilderService()),
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
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settings;
    // Set initial tab based on bootTab setting
    selectedIndex = _getInitialTabIndex();
    _startSettingsPolling();
  }

  int _getInitialTabIndex() {
    switch (_currentSettings.bootTab) {
      case 'Favorites':
        return 1;
      case 'Scripts':
      case 'Bat Files': // Legacy support
        return _currentSettings.showBatFilesTab ? 2 : 0;
      default:
        return 0; // Home
    }
  }

  void _startSettingsPolling() {
    // Poll for settings changes every 500ms
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        final newSettings = await _settingsService.loadSettings();
        if (newSettings.showBatFilesTab != _currentSettings.showBatFilesTab) {
          setState(() {
            _currentSettings = newSettings;
            // Adjust selectedIndex if Scripts tab was hidden and user was on a tab after it
            if (!newSettings.showBatFilesTab && selectedIndex >= 2) {
              selectedIndex = selectedIndex > 2 ? selectedIndex - 1 : selectedIndex;
            }
          });
        }
        _startSettingsPolling();
      }
    });
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
        HomePage(panelOrder: _currentSettings.panelOrder),
        const FavoritesPage(),
        if (_currentSettings.showBatFilesTab) const ScriptsPage(),
        const ResourcesPage(),
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
              onItemSelected: (index) {
                // Clear command builder when leaving Home page (index 0)
                if (selectedIndex == 0 && index != 0) {
                  final commandService = Provider.of<CommandBuilderService>(context, listen: false);
                  commandService.resetToDefaults();
                }
                setState(() => selectedIndex = index);
              },
            ),
            // Main content area with animated page transitions
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: pages[selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
