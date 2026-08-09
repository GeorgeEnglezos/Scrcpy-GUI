import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scrcpy_gui_prod/models/color_preset.dart';
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/services/adb_service.dart';
import 'package:scrcpy_gui_prod/services/color_theme_notifier.dart';
import 'package:scrcpy_gui_prod/theme/app_theme.dart';
import 'package:scrcpy_gui_prod/widgets/setup_wizard_dialog.dart';

void main() {
  final preset = ColorPreset.fromJson({'name': 'Dark', 'brightness': 'dark'});

  AppSettings? saved;

  setUp(() {
    saved = null;
    // isScrcpyOnPath and checkAdb both spawn real processes otherwise, which
    // the test binding's fake async cannot complete.
    AdbService.debugSkipProcessChecks = true;
  });

  tearDown(() => AdbService.debugSkipProcessChecks = false);

  // Opens the wizard through showDialog rather than pumping it as the home
  // widget, so that its Navigator.pop has a route to pop.
  Future<void> pumpWizard(WidgetTester tester) async {
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
    await tester.pumpAndSettle();
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

  // Skipping still counts as done. Without this the wizard would reopen on
  // every launch for anyone who dismissed it.
  testWidgets('Skip marks setup complete and closes', (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.setupCompleted, isTrue);
    expect(find.text('Welcome to Scrcpy GUI'), findsNothing);
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
}
