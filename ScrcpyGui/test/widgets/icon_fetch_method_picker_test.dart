import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scrcpy_gui_prod/models/color_preset.dart';
import 'package:scrcpy_gui_prod/services/color_theme_notifier.dart';
import 'package:scrcpy_gui_prod/services/icon_fetch_strategy.dart';
import 'package:scrcpy_gui_prod/theme/app_theme.dart';
import 'package:scrcpy_gui_prod/widgets/icon_fetch_method_picker.dart';

void main() {
  final preset = ColorPreset.fromJson({'name': 'Dark', 'brightness': 'dark'});

  IconFetchMethod? picked;

  Future<void> pumpPicker(
    WidgetTester tester, {
    required IconFetchMethod selected,
    List<Widget> helperApkExtras = const [],
  }) async {
    picked = null;
    await tester.pumpWidget(
      // The cards colour themselves through the context extensions, which
      // resolve against this notifier.
      ChangeNotifierProvider<ColorThemeNotifier>(
        create: (_) => ColorThemeNotifier(
          presets: [preset],
          selectedName: 'Dark',
        ),
        child: MaterialApp(
          theme: AppTheme.dark(const Color(0xFF00AAFF)),
          home: Scaffold(
            // Unconstrained height otherwise: the ADB card's description is
            // long enough to overflow the test surface.
            body: SingleChildScrollView(
              child: IconFetchMethodPicker(
                selected: selected,
                onChanged: (method) => picked = method,
                helperApkExtras: helperApkExtras,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('offers both fetch methods', (tester) async {
    await pumpPicker(tester, selected: IconFetchMethod.adbScrape);

    expect(find.text('Helper APK'), findsOneWidget);
    expect(find.text('ADB'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
  });

  testWidgets('reports the method the user tapped', (tester) async {
    await pumpPicker(tester, selected: IconFetchMethod.adbScrape);

    await tester.tap(find.text('Helper APK'));
    await tester.pumpAndSettle();

    expect(picked, IconFetchMethod.helperApk);
  });

  testWidgets('reports ADB when that card is tapped', (tester) async {
    await pumpPicker(tester, selected: IconFetchMethod.helperApk);

    await tester.tap(find.text('ADB'));
    await tester.pumpAndSettle();

    expect(picked, IconFetchMethod.adbScrape);
  });

  // The check mark is the only thing distinguishing the active card, so it has
  // to sit on the selected one rather than merely existing somewhere.
  testWidgets('marks the selected card and only that card', (tester) async {
    Finder checkUnder(String title) => find.ancestor(
          of: find.text(title),
          matching: find.byType(AnimatedContainer),
        );

    await pumpPicker(tester, selected: IconFetchMethod.helperApk);

    expect(
      find.descendant(
        of: checkUnder('Helper APK'),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await pumpPicker(tester, selected: IconFetchMethod.adbScrape);

    expect(
      find.descendant(
        of: checkUnder('ADB'),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('renders caller-supplied extras inside the Helper APK card', (
    tester,
  ) async {
    await pumpPicker(
      tester,
      selected: IconFetchMethod.helperApk,
      helperApkExtras: const [Text('auto-install')],
    );

    expect(find.text('auto-install'), findsOneWidget);
  });
}
