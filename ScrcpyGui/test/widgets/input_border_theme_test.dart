// The shared inputs must take their border from the app's
// InputDecorationTheme instead of declaring their own. A field that redeclares
// one drifts out of sync the next time the theme changes, which is exactly
// what happened to CustomMultiDropdown when the theme was introduced.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:provider/provider.dart';

import 'package:scrcpy_gui_prod/models/color_preset.dart';
import 'package:scrcpy_gui_prod/services/color_theme_notifier.dart';
import 'package:scrcpy_gui_prod/theme/app_theme.dart';
import 'package:scrcpy_gui_prod/widgets/custom_dropdown.dart';
import 'package:scrcpy_gui_prod/widgets/custom_multi_dropdown.dart';
import 'package:scrcpy_gui_prod/widgets/custom_textinput.dart';

void main() {
  final theme = AppTheme.dark(const Color(0xFF00AAFF));
  final preset = ColorPreset.fromJson({'name': 'Dark', 'brightness': 'dark'});

  Future<void> pumpInput(WidgetTester tester, Widget input) {
    return tester.pumpWidget(
      ChangeNotifierProvider<ColorThemeNotifier>(
        create: (_) => ColorThemeNotifier(
          presets: [preset],
          selectedName: 'Dark',
        ),
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(child: SizedBox(width: 300, child: input)),
          ),
        ),
      ),
    );
  }

  /// The decoration the field ends up painting: what it declared, merged with
  /// the app theme the same way InputDecorator merges it at paint time.
  InputDecoration paintedDecoration(WidgetTester tester) {
    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator).first,
    );
    return decorator.decoration.applyDefaults(theme.inputDecorationTheme);
  }

  void expectThemeBorders(WidgetTester tester) {
    final decoration = paintedDecoration(tester);
    expect(decoration.enabledBorder, theme.inputDecorationTheme.enabledBorder);
    expect(decoration.focusedBorder, theme.inputDecorationTheme.focusedBorder);
  }

  testWidgets('CustomTextField borders come from the theme', (tester) async {
    await pumpInput(
      tester,
      CustomTextField(label: 'Port', onChanged: (_) {}),
    );

    expectThemeBorders(tester);
  });

  testWidgets('CustomDropdown borders come from the theme', (tester) async {
    await pumpInput(
      tester,
      CustomDropdown(
        label: 'Video Codec',
        value: 'h264',
        items: const ['h264', 'h265'],
        onChanged: (_) {},
      ),
    );

    expectThemeBorders(tester);
  });

  testWidgets('CustomMultiDropdown borders come from the theme', (tester) async {
    final controller = MultiSelectController<String>();
    addTearDown(controller.dispose);

    await pumpInput(
      tester,
      CustomMultiDropdown(
        label: 'Shortcut Mod Key',
        items: [DropdownItem(label: 'lctrl', value: 'lctrl')],
        controller: controller,
        onSelectionChange: (_) {},
      ),
    );

    expectThemeBorders(tester);
  });
}
