import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scrcpy_gui_prod/models/color_preset.dart';
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/services/adb_service.dart';
import 'package:scrcpy_gui_prod/services/color_theme_notifier.dart';
import 'package:scrcpy_gui_prod/theme/app_theme.dart';
import 'package:scrcpy_gui_prod/widgets/directory_row.dart';
import 'package:scrcpy_gui_prod/widgets/setup_wizard_dialog.dart';

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

  setUp(() {
    saved = null;
    // isScrcpyOnPath and checkAdb both spawn real processes otherwise, which
    // the test binding's fake async cannot complete.
    AdbService.debugSkipProcessChecks = true;
  });

  tearDown(() {
    AdbService.debugSkipProcessChecks = false;
    AdbService.debugScrcpyOnPath = null;
    AdbService.debugAdbStatus = null;
  });

  // Opens the wizard through showDialog rather than pumping it as the home
  // widget, so that its Navigator.pop has a route to pop.
  Future<void> pumpWizard(WidgetTester tester, {String scrcpyDirectory = ''}) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ColorThemeNotifier>(
        create: (_) => ColorThemeNotifier(
          presets: [preset],
          selectedName: 'Dark',
        ),
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

    if (scrcpyDirectory.isNotEmpty) {
      // Validating a pinned directory hits the real filesystem, which the fake
      // clock cannot drive. Until it resolves the step shows an animating
      // spinner, so pumpAndSettle alone would spin until it timed out. Build
      // one frame, hand time to the real event loop, then settle.
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }

    await tester.pumpAndSettle();
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

  // Skip moves past one step, it does not dismiss the wizard. Nothing is
  // persisted by skipping, since the step was never configured.
  testWidgets('Skip advances one step and leaves the wizard open', (
    tester,
  ) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Skip this step'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Welcome to Scrcpy GUI'), findsOneWidget);
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
    expect(find.text('Welcome to Scrcpy GUI'), findsNothing);
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
