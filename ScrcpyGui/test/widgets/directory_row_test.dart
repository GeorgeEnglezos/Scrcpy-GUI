import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:scrcpy_gui_prod/models/color_preset.dart';
import 'package:scrcpy_gui_prod/services/color_theme_notifier.dart';
import 'package:scrcpy_gui_prod/theme/app_theme.dart';
import 'package:scrcpy_gui_prod/widgets/directory_row.dart';

void main() {
  final preset = ColorPreset.fromJson({'name': 'Dark', 'brightness': 'dark'});

  // DirectoryRow reads its colors through the context.appX extensions, which
  // watch a ColorThemeNotifier. Without the provider it throws on build.
  Future<void> pumpRow(WidgetTester tester, Widget row) {
    return tester.pumpWidget(
      ChangeNotifierProvider<ColorThemeNotifier>(
        create: (_) => ColorThemeNotifier(
          presets: [preset],
          selectedName: 'Dark',
        ),
        child: MaterialApp(
          theme: AppTheme.dark(const Color(0xFF00AAFF)),
          home: Scaffold(body: row),
        ),
      ),
    );
  }

  testWidgets('shows the label and the path', (tester) async {
    await pumpRow(
      tester,
      const DirectoryRow(
        label: 'Downloads Directory',
        path: '/tmp/downloads',
        showOpenButton: false,
        showBrowseButton: false,
      ),
    );

    expect(find.text('Downloads Directory'), findsOneWidget);
    expect(find.text('/tmp/downloads'), findsOneWidget);
  });

  testWidgets('hides the buttons the caller turned off', (tester) async {
    await pumpRow(
      tester,
      const DirectoryRow(
        label: 'Settings Location',
        path: '/cfg',
        showOpenButton: false,
        showBrowseButton: false,
      ),
    );

    expect(find.text('Open'), findsNothing);
    expect(find.text('Browse...'), findsNothing);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('reports browse, open and clear taps', (tester) async {
    var browsed = false;
    var opened = false;
    var cleared = false;

    await pumpRow(
      tester,
      DirectoryRow(
        label: 'Scrcpy Directory',
        path: '/opt/scrcpy',
        onBrowse: () => browsed = true,
        onOpen: () => opened = true,
        onClear: () => cleared = true,
      ),
    );

    await tester.tap(find.text('Browse...'));
    await tester.tap(find.text('Open'));
    await tester.tap(find.text('Clear'));

    expect(browsed, isTrue);
    expect(opened, isTrue);
    expect(cleared, isTrue);
  });
}
