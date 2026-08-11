import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scrcpy_gui_prod/models/color_preset.dart';
import 'package:scrcpy_gui_prod/models/phone_info_model.dart';
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/services/adb_service.dart';
import 'package:scrcpy_gui_prod/services/app_icon_cache.dart';
import 'package:scrcpy_gui_prod/services/app_icon_controller.dart';
import 'package:scrcpy_gui_prod/services/color_theme_notifier.dart';
import 'package:scrcpy_gui_prod/services/device_manager_service.dart';
import 'package:scrcpy_gui_prod/services/icon_fetch_strategy.dart';
import 'package:scrcpy_gui_prod/theme/app_theme.dart';
import 'package:scrcpy_gui_prod/widgets/directory_row.dart';
import 'package:scrcpy_gui_prod/widgets/icon_fetch_method_picker.dart';
import 'package:scrcpy_gui_prod/widgets/setup_wizard_dialog.dart';
import 'package:scrcpy_gui_prod/widgets/ui_scale_dropdown.dart';

/// Records the chosen fetch method without persisting it.
///
/// The real [AppIconController.setIconFetchMethod] writes
/// app_drawer_settings.json under APPDATA, which a widget test has no business
/// touching. Overriding only the setter keeps the notify-and-rebuild path that
/// the wizard actually depends on.
class _FakeIconController extends AppIconController {
  int setCount = 0;
  String? loadedDeviceId;
  List<String>? loadedPackages;
  bool? fetchedWithAutoInstall;

  @override
  void setIconFetchMethod(IconFetchMethod method) {
    setCount++;
    appDrawerSettings = appDrawerSettings.copyWith(iconFetchMethod: method);
    notifyListeners();
  }

  // Overridden rather than driven for real: the genuine pair pulls APKs over
  // ADB and installs a helper app on a phone.
  @override
  Future<void> loadForDevice(String deviceId, List<String> packages) async {
    loadedDeviceId = deviceId;
    loadedPackages = packages;
    for (final pkg in packages) {
      labels[pkg] = pkg;
      icons[pkg] = null;
    }
    notifyListeners();
  }

  @override
  Future<void> fetchMissing({
    bool forceUpdate = true,
    bool helperApkAutoInstall = false,
    void Function(String message)? onError,
  }) async {
    fetchedWithAutoInstall = helperApkAutoInstall;
    for (final pkg in labels.keys) {
      icons[pkg] = File('$pkg.png');
    }
    notifyListeners();
  }
}

/// Fake used to drive [FilePicker.getDirectoryPath] without a real dialog.
/// Extends [FilePicker] (rather than mocking it) so the constructor chain
/// sets the platform-interface token the real setter verifies.
class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this.directoryPath);

  final String? directoryPath;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async =>
      directoryPath;
}

void main() {
  final preset = ColorPreset.fromJson({'name': 'Dark', 'brightness': 'dark'});

  // These commands are quoted from Official-docs/{windows,macos,linux}.md.
  // The point of pinning them is that the obvious guesses are wrong: upstream
  // marks the Debian/Ubuntu apt package and the snap as obsolete, and WinGet
  // takes --exact rather than --id.
  group('scrcpyInstallHint', () {
    test('every platform offers at least one command and a note', () {
      for (final os in HostOs.values) {
        final hint = scrcpyInstallHint(os);
        expect(hint.commands, isNotEmpty, reason: '$os has no command');
        expect(hint.note, isNotEmpty, reason: '$os has no note');
      }
    });

    test('Windows uses the documented WinGet invocation', () {
      expect(
        scrcpyInstallHint(HostOs.windows).commands,
        ['winget install --exact Genymobile.scrcpy'],
      );
    });

    test('macOS installs adb alongside scrcpy', () {
      final hint = scrcpyInstallHint(HostOs.macos);
      expect(hint.commands.first, 'brew install scrcpy');
      expect(hint.copyText, contains('android-platform-tools'));
    });

    test('Linux never suggests the obsolete apt or snap packages', () {
      final text = scrcpyInstallHint(HostOs.linux).copyText;
      expect(text, isNot(contains('apt install scrcpy')));
      expect(text, isNot(contains('snap install scrcpy')));
      expect(text, contains('pacman -S scrcpy'));
    });

    // The Linux lines target different distributions, so running them in
    // sequence would invoke the wrong package manager. Nothing to automate.
    test('Linux offers no runnable command', () {
      expect(scrcpyInstallHint(HostOs.linux).runnable, isNull);
    });

    test('Windows and macOS each run every command they list', () {
      for (final os in [HostOs.windows, HostOs.macos]) {
        final hint = scrcpyInstallHint(os);
        final runnable = hint.runnable;
        expect(runnable, isNotNull, reason: '$os has no runnable command');
        for (final command in hint.commands) {
          expect(runnable, contains(command), reason: '$os drops $command');
        }
      }
    });

    test('copyText joins multiple commands one per line', () {
      final hint = scrcpyInstallHint(HostOs.macos);
      expect(hint.copyText.split('\n').length, hint.commands.length);
    });
  });

  AppSettings? saved;
  late Directory packagesRoot;
  late _FakeIconController iconController;
  late DeviceManagerService deviceManager;

  setUp(() {
    saved = null;
    iconController = _FakeIconController();
    deviceManager = DeviceManagerService();
    // isScrcpyOnPath and checkAdb both spawn real processes otherwise, which
    // the test binding's fake async cannot complete.
    AdbService.debugSkipProcessChecks = true;
    // Point the on-disk search at an empty temp folder. Without this it scans
    // the real WinGet packages directory, so these tests would pass or fail
    // depending on whether the developer happens to have scrcpy installed.
    packagesRoot = Directory.systemTemp.createTempSync('winget_packages_root');
    AdbService.debugWingetPackagesRoot = packagesRoot.path;
  });

  tearDown(() {
    // Static registry: a device left here would make the app-icons step show
    // up in every later test.
    DeviceManagerService.devicesInfo.clear();
    AdbService.debugSkipProcessChecks = false;
    AdbService.debugScrcpyOnPath = null;
    AdbService.debugAdbStatus = null;
    AdbService.debugWingetPackagesRoot = null;
    packagesRoot.deleteSync(recursive: true);
  });

  /// Creates a WinGet-shaped package holding scrcpy, and returns the folder
  /// the executable ends up in.
  Directory installIntoPackagesRoot() {
    final versionDir = Directory(
      p.join(packagesRoot.path, 'Genymobile.scrcpy_Source', 'scrcpy-win64-v4.1'),
    )..createSync(recursive: true);
    File(p.join(versionDir.path, Platform.isWindows ? 'scrcpy.exe' : 'scrcpy'))
        .createSync();
    return versionDir;
  }

  /// Lets work that touches the real filesystem finish.
  ///
  /// Resolving scrcpy chains several real IO calls (list the packages root,
  /// test each candidate, save, re-probe adb). Each one needs real time to
  /// complete AND a pump to run its continuation, and the next call only
  /// starts once the previous continuation has run, so a single delay advances
  /// the chain by one step. Alternating the two drains it. Meanwhile the step
  /// shows an animating spinner, so pumpAndSettle on its own would spin until
  /// it timed out.
  Future<void> settleRealIo(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pumpAndSettle();
  }

  // Opens the wizard through showDialog rather than pumping it as the home
  // widget, so that its Navigator.pop has a route to pop.
  /// Registers a connected device, which is what makes the app-icons step
  /// appear. [devicesInfo] is static, so the teardown below clears it.
  void connectDevice({List<String> packages = const ['com.example.app']}) {
    DeviceManagerService.devicesInfo['device-1'] = PhoneInfoModel(
      deviceId: 'device-1',
      packages: packages,
    );
    deviceManager.selectedDevice = 'device-1';
  }

  Future<void> pumpWizard(WidgetTester tester, {String scrcpyDirectory = ''}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ColorThemeNotifier>(
            create: (_) => ColorThemeNotifier(
              presets: [preset],
              selectedName: 'Dark',
            ),
          ),
          ChangeNotifierProvider<AppIconController>.value(value: iconController),
          ChangeNotifierProvider<DeviceManagerService>.value(
            value: deviceManager,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(const Color(0xFF00AAFF)),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => SetupWizardDialog(
                    initialSettings: AppSettings.defaultSettings().copyWith(
                      recordingsDirectory: '/cfg/Recordings',
                      downloadsDirectory: '/cfg/Downloads',
                      batDirectory: '/cfg/Downloads',
                      appIconsDirectory: '/cfg',
                      scrcpyDirectory: scrcpyDirectory,
                    ),
                    onSave: (settings) async => saved = settings,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));

    await settleRealIo(tester);
  }

  /// A folder that looks like an extracted scrcpy release.
  Directory makeScrcpyDir() {
    final dir = Directory.systemTemp.createTempSync('wizard_scrcpy_dir');
    File(p.join(dir.path, Platform.isWindows ? 'scrcpy.exe' : 'scrcpy'))
        .createSync();
    return dir;
  }

  testWidgets('opens on step 1 and reports scrcpy found on PATH', (
    tester,
  ) async {
    await pumpWizard(tester);

    expect(find.text('Welcome to Scrcpy GUI'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(
      find.textContaining('scrcpy found on your system PATH'),
      findsOneWidget,
    );
  });

  testWidgets('Next reaches the last step, where the button reads Finish', (
    tester,
  ) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('/cfg/Downloads'), findsWidgets);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
  });

  // The heading names the step rather than repeating a greeting, so the user
  // can tell what they are looking at without reading the body.
  testWidgets('each step is titled for what it configures', (tester) async {
    connectDevice();
    await pumpWizard(tester);

    expect(find.text('Welcome to Scrcpy GUI'), findsOneWidget);

    for (final title in ['Directories', 'App Drawer', 'UI Preferences']) {
      await tester.tap(find.text('Skip this step').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: 'missing $title');
    }
  });

  // The app-icons step can do nothing without a device, so it is not offered
  // when there is none: the wizard is three steps, not a four-step one with a
  // dead page in the middle.
  testWidgets('the app icons step is absent when no device is connected', (
    tester,
  ) async {
    await pumpWizard(tester);

    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    expect(find.byType(IconFetchMethodPicker), findsNothing);
    expect(find.byType(UiScaleDropdown), findsOneWidget);
  });

  testWidgets('connecting a device adds the app icons step', (tester) async {
    connectDevice();
    await pumpWizard(tester);

    expect(find.text('Step 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 4'), findsOneWidget);
    expect(find.byType(IconFetchMethodPicker), findsOneWidget);
  });

  // The step appears mid-setup when a phone is plugged in, so the wizard has
  // to renumber rather than keep claiming three steps.
  testWidgets('plugging in a device while the wizard is open renumbers it', (
    tester,
  ) async {
    await pumpWizard(tester);
    expect(find.text('Step 1 of 3'), findsOneWidget);

    connectDevice();
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 4'), findsOneWidget);
  });

  // Unplugging while standing on the app-icons step must not strand the user
  // on a step that is no longer in the list.
  testWidgets('unplugging while on the app icons step falls back', (
    tester,
  ) async {
    connectDevice();
    await pumpWizard(tester);
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    expect(find.byType(IconFetchMethodPicker), findsOneWidget);

    DeviceManagerService.devicesInfo.clear();
    deviceManager.selectedDevice = null;
    await tester.pumpAndSettle();

    expect(find.byType(IconFetchMethodPicker), findsNothing);
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.byType(UiScaleDropdown), findsOneWidget);
  });

  // Skip moves past one step, it does not dismiss the wizard. Nothing is
  // persisted by skipping, since the step was never configured.
  testWidgets('Skip advances one step and leaves the wizard open', (
    tester,
  ) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 3'), findsOneWidget);
    // Still open, now titled for the step it moved to.
    expect(find.text('Directories'), findsOneWidget);
    expect(saved, isNull);
  });

  // On the last step, skipping and finishing would be the same action, so
  // only Finish is offered.
  testWidgets('the last step offers Back and Finish but no Skip', (
    tester,
  ) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Skip this step'), findsNothing);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
  });

  testWidgets('Finish marks setup complete and closes', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.setupCompleted, isTrue);
    // The title of the step Finish was pressed on, so this goes red if the
    // dialog stays open rather than passing because the heading changed.
    expect(find.text('UI Preferences'), findsNothing);
  });

  testWidgets(
    'when scrcpy is not on PATH, the Scrcpy Directory row and the '
    'not-found message both show',
    (tester) async {
      AdbService.debugScrcpyOnPath = false;
      await pumpWizard(tester);

      expect(
        find.textContaining('not on your system PATH'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(DirectoryRow, 'Scrcpy Directory'),
        findsOneWidget,
      );
      // Both ways to get scrcpy live in one labelled box.
      final hint = scrcpyInstallHint(currentHostOs);
      expect(find.text('Install scrcpy'), findsOneWidget);
      expect(find.text('Option 1: Manual download'), findsOneWidget);
      expect(find.text('Get scrcpy'), findsOneWidget);
      expect(find.text('Option 2: Run a command'), findsOneWidget);
      expect(find.text(hint.copyText), findsOneWidget);
      // Rendered once, by the panel, not also by the command block.
      expect(find.text(hint.note), findsOneWidget);
    },
  );

  // AdbService.adbExecutable derives adb's path from scrcpyDirectory, so the
  // adb result goes stale the instant that directory changes. Choosing the
  // extracted scrcpy folder must re-probe, or step 1 keeps insisting adb is
  // missing while sitting right next to the adb.exe that shipped in the zip.
  testWidgets('choosing a scrcpy directory re-probes adb', (tester) async {
    final dir = Directory.systemTemp.createTempSync('wizard_scrcpy');
    addTearDown(() => dir.deleteSync(recursive: true));
    File(p.join(dir.path, Platform.isWindows ? 'scrcpy.exe' : 'scrcpy'))
        .createSync();

    AdbService.debugScrcpyOnPath = false;
    AdbService.debugAdbStatus =
        const AdbStatus(reachable: false, deviceCount: 0);
    FilePicker.platform = _FakeFilePicker(dir.path);

    await pumpWizard(tester);
    expect(find.text('adb not found'), findsOneWidget);

    // The zip ships adb.exe beside scrcpy.exe, so adb resolves from the folder
    // the user just chose.
    AdbService.debugAdbStatus =
        const AdbStatus(reachable: true, deviceCount: 0);

    // The install panel pushes the Browse row below the fold, so the step
    // scrolls. Bring it into view the way a user would.
    await tester.ensureVisible(find.text('Browse...'));
    await tester.pumpAndSettle();

    // runAsync because picking validates the folder with real filesystem I/O,
    // which the fake async clock cannot complete on its own.
    await tester.runAsync(() async {
      await tester.tap(find.text('Browse...'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('adb responding, no devices connected'), findsOneWidget);
    expect(find.text('adb not found'), findsNothing);
  });

  // A pinned directory is how the wizard records an install that PATH cannot
  // see, so it has to read as success rather than leaving the install panel up.
  testWidgets(
    'a configured directory counts as found even when PATH does not resolve',
    (tester) async {
      final dir = makeScrcpyDir();
      addTearDown(() => dir.deleteSync(recursive: true));

      AdbService.debugScrcpyOnPath = false;
      await pumpWizard(tester, scrcpyDirectory: dir.path);

      expect(
        find.textContaining('scrcpy found at ${dir.path}'),
        findsOneWidget,
      );
      expect(find.text('Install scrcpy'), findsNothing);
      expect(find.widgetWithText(DirectoryRow, 'Scrcpy Directory'), findsNothing);
    },
  );

  // The bug this guards: opening the wizard used to consult PATH only, while
  // the Check for installation button also searched disk. A WinGet install
  // leaves PATH stale in an already-running app, so a perfectly good scrcpy
  // read as missing on open and then appeared the instant the user clicked.
  // Opening must resolve exactly the way the button does.
  testWidgets(
    'an install only findable on disk is resolved when the wizard opens',
    (tester) async {
      final versionDir = installIntoPackagesRoot();
      AdbService.debugScrcpyOnPath = false;

      await pumpWizard(tester);

      expect(
        find.textContaining('scrcpy found at ${versionDir.path}'),
        findsOneWidget,
      );
      expect(find.text('Install scrcpy'), findsNothing);
      expect(saved?.scrcpyDirectory, versionDir.path);
    },
  );

  // A pinned path is just a string in a settings file. If scrcpy is deleted
  // out from under it, claiming success sends the user to a Home page whose
  // every run button fails.
  testWidgets(
    'a configured directory whose scrcpy was deleted is not counted as found',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('wizard_emptied');
      addTearDown(() => dir.deleteSync(recursive: true));

      AdbService.debugScrcpyOnPath = false;
      await pumpWizard(tester, scrcpyDirectory: dir.path);

      expect(find.textContaining('scrcpy found at'), findsNothing);
      expect(find.text('Install scrcpy'), findsOneWidget);
      expect(
        find.widgetWithText(DirectoryRow, 'Scrcpy Directory'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the run button is offered only where a command is safe to automate',
    (tester) async {
      AdbService.debugScrcpyOnPath = false;
      await pumpWizard(tester);

      final expected = scrcpyInstallHint(currentHostOs).runnable == null
          ? findsNothing
          : findsOneWidget;
      expect(find.text('Run in terminal'), expected);
      expect(find.text('Check for installation'), expected);
      // Copy is always available, whichever platform this runs on.
      expect(find.byTooltip('Copy'), findsOneWidget);
    },
  );

  testWidgets(
    'when scrcpy is on PATH, the found message shows and there is no '
    'Browse row',
    (tester) async {
      AdbService.debugScrcpyOnPath = true;
      await pumpWizard(tester);

      expect(
        find.textContaining('scrcpy found on your system PATH'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(DirectoryRow, 'Scrcpy Directory'),
        findsNothing,
      );
      // The whole install panel would be noise on a step the user should pass
      // straight through.
      expect(find.text('Install scrcpy'), findsNothing);
      expect(find.text('Get scrcpy'), findsNothing);
      expect(find.text('Run in terminal'), findsNothing);
    },
  );

  testWidgets('picking a directory in step 2 reaches onSave', (tester) async {
    // FilePicker.platform is a late field with no default under flutter
    // test (nothing registers a real plugin instance), so there is no prior
    // value to save and restore; only this test reads it.
    FilePicker.platform = _FakeFilePicker('/picked/Downloads');

    await pumpWizard(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Browse...').first);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.downloadsDirectory, '/picked/Downloads');
  });

  testWidgets('the app icons step offers both methods and the folder', (
    tester,
  ) async {
    connectDevice();
    await pumpWizard(tester);
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    expect(find.byType(IconFetchMethodPicker), findsOneWidget);
    expect(
      find.widgetWithText(DirectoryRow, 'App Icons & Labels'),
      findsOneWidget,
    );
    expect(find.text(AppIconCache.cachePathIn('/cfg')), findsOneWidget);
  });

  // Tapping a card has to move the check mark and retitle the run button,
  // which is the only feedback that the choice registered.
  testWidgets('tapping a method card selects it', (tester) async {
    connectDevice();
    await pumpWizard(tester);
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    expect(
      iconController.appDrawerSettings.iconFetchMethod,
      IconFetchMethod.adbScrape,
    );

    await tester.tap(find.text('Helper APK'));
    await tester.pumpAndSettle();

    expect(iconController.setCount, 1);
    expect(
      iconController.appDrawerSettings.iconFetchMethod,
      IconFetchMethod.helperApk,
    );
    expect(
      find.descendant(
        // The card itself, not any Column around it: the confirmation line
        // below the picker carries a check mark of its own.
        of: find.ancestor(
          of: find.text('Helper APK'),
          matching: find.byType(AnimatedContainer),
        ),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    // The run button names the method, so the choice is legible without
    // hunting for the check mark.
    expect(find.text('Load apps with Helper APK'), findsOneWidget);
  });

  // The step exists to run the fetch, so the button has to be there and has to
  // name the method it will use.
  testWidgets('the app icons step offers a run button for the chosen method', (
    tester,
  ) async {
    connectDevice();
    await pumpWizard(tester);
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    expect(find.text('Load apps with ADB'), findsOneWidget);

    await tester.tap(find.text('Helper APK'));
    await tester.pumpAndSettle();

    expect(find.text('Load apps with Helper APK'), findsOneWidget);
  });

  // The whole point of the step: the button runs the fetch there and then,
  // against the connected device, instead of sending the user elsewhere.
  testWidgets('the run button fetches icons for the connected device', (
    tester,
  ) async {
    connectDevice(packages: ['com.a', 'com.b']);
    await pumpWizard(tester);
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    // The method cards push the button below the fold of the dialog.
    await tester.ensureVisible(find.text('Load apps with ADB'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load apps with ADB'));
    await tester.pumpAndSettle();

    expect(iconController.loadedDeviceId, 'device-1');
    expect(iconController.loadedPackages, ['com.a', 'com.b']);
    // The button says it installs the helper app, so the run must not fail
    // demanding a checkbox the wizard never shows.
    expect(iconController.fetchedWithAutoInstall, isTrue);
    expect(find.textContaining('2 of 2'), findsOneWidget);
  });

  testWidgets('picking an app icons directory reaches onSave', (tester) async {
    FilePicker.platform = _FakeFilePicker('/picked/icons');

    connectDevice();
    await pumpWizard(tester);
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    // The two method cards push the row below the fold of the dialog.
    await tester.ensureVisible(find.text('Browse...'));
    await tester.pumpAndSettle();

    // runAsync because picking copies the existing cache across with real
    // filesystem I/O, which the fake async clock cannot complete on its own.
    await tester.runAsync(() async {
      await tester.tap(find.text('Browse...'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.appIconsDirectory, '/picked/icons');
  });

  testWidgets('the appearance step offers both the theme and the scale', (
    tester,
  ) async {
    await pumpWizard(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Skip this step'));
      await tester.pumpAndSettle();
    }

    expect(find.byType(UiScaleDropdown), findsOneWidget);
    expect(find.text('Color Theme'), findsOneWidget);
  });

  // The wizard is the first thing a user sees, so a scale chosen here has to
  // survive to the app shell that reads it back out of settings.
  testWidgets('choosing a UI scale persists it', (tester) async {
    await pumpWizard(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Skip this step'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byType(UiScaleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90%').last);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.uiScale, 0.90);
  });

  group('SetupWizardGate', () {
    // Only the disabled case is covered here. Enabling the gate calls
    // getSettingsDirectory, which creates a real directory under APPDATA, and
    // a widget test has no business touching the user's filesystem.
    testWidgets('renders its child and opens nothing when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ColorThemeNotifier>(
          create: (_) => ColorThemeNotifier(
            presets: [preset],
            selectedName: 'Dark',
          ),
          child: MaterialApp(
            theme: AppTheme.dark(const Color(0xFF00AAFF)),
            home: const SetupWizardGate(
              enabled: false,
              child: Scaffold(body: Text('the app')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('the app'), findsOneWidget);
      expect(find.text('Welcome to Scrcpy GUI'), findsNothing);
    });
  });
}
