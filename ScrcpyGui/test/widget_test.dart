// App smoke test: pumps ScrcpyGuiApp with the same providers main() sets up
// and verifies the first frame builds without errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scrcpy_gui_prod/main.dart';
import 'package:scrcpy_gui_prod/models/color_preset.dart';
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/services/app_icon_controller.dart';
import 'package:scrcpy_gui_prod/services/color_theme_notifier.dart';
import 'package:scrcpy_gui_prod/services/command_notifier.dart';
import 'package:scrcpy_gui_prod/services/device_manager_service.dart';
import 'package:scrcpy_gui_prod/services/log_service.dart';
import 'package:scrcpy_gui_prod/services/adb_service.dart';
import 'package:scrcpy_gui_prod/widgets/ui_scale.dart';

Future<void> pumpApp(WidgetTester tester, AppSettings settings) async {
  // fromJson with only name/brightness fills every color with defaults.
  final preset = ColorPreset.fromJson({'name': 'Dark', 'brightness': 'dark'});

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceManagerService>(
          // Not initialize()d, no adb polling in tests.
          create: (_) => DeviceManagerService(),
        ),
        ChangeNotifierProvider<CommandNotifier>(create: (_) => CommandNotifier()),
        ChangeNotifierProvider<AppIconController>(create: (_) => AppIconController()),
        ChangeNotifierProvider<ColorThemeNotifier>(
          create: (_) => ColorThemeNotifier(presets: [preset], selectedName: 'Dark'),
        ),
        ChangeNotifierProvider<LogService>.value(value: LogService.instance),
      ],
      child: ScrcpyGuiApp(settings: settings),
    ),
  );
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Fake async can't complete a real process spawn (HomePage checks
    // whether scrcpy is on PATH at startup).
    AdbService.debugSkipProcessChecks = true;
    // Disable the startup update check: its 2s Future.delayed would leave a
    // pending timer that fails the test, and it hits the network.
    final settings = AppSettings.defaultSettings().copyWith(
      checkForUpdatesOnStartup: false,
    );

    await pumpApp(tester, settings);

    expect(find.byType(ScrcpyGuiApp), findsOneWidget);
  });

  testWidgets('the saved ui scale reaches the widget tree', (tester) async {
    AdbService.debugSkipProcessChecks = true;
    final settings = AppSettings.defaultSettings().copyWith(
      checkForUpdatesOnStartup: false,
      uiScale: 0.85,
    );

    await pumpApp(tester, settings);

    expect(tester.widget<UiScale>(find.byType(UiScale)).scale, 0.85);
  });
}
