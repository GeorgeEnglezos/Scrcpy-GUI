import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scrcpy_gui_prod/models/color_preset.dart';
import 'package:scrcpy_gui_prod/pages/app_drawer/ctx_menu.dart';
import 'package:scrcpy_gui_prod/services/color_theme_notifier.dart';
import 'package:scrcpy_gui_prod/widgets/ui_scale.dart';

/// Opens the menu at [at] with the app rendered at [scale], and returns where
/// the menu actually painted in window coordinates.
Future<Offset> menuOriginFor(
  WidgetTester tester, {
  required double scale,
  required Offset at,
}) async {
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final controller = CtxMenuController();
  addTearDown(controller.dismiss);

  // The menu rows read theme colors, which come from this notifier.
  final preset = ColorPreset.fromJson({'name': 'Dark', 'brightness': 'dark'});

  await tester.pumpWidget(
    ChangeNotifierProvider<ColorThemeNotifier>(
      create: (_) => ColorThemeNotifier(presets: [preset], selectedName: 'Dark'),
      child: MaterialApp(
        builder: (context, child) => UiScale(scale: scale, child: child!),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => controller.show(context, at, [
              CtxMenuItem(icon: Icons.star, label: 'Only item', onTap: () {}),
            ]),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pump();

  return tester.getTopLeft(find.byType(Material).last);
}

void main() {
  group('CtxMenuController.show', () {
    // The App Drawer passes a gesture's globalPosition, which is a raw window
    // coordinate, but the overlay paints inside the UI scale transform. Without
    // converting, the menu opens short of the click by the scale factor: a
    // click at (500, 400) at 80% used to open the menu at (400, 320).
    testWidgets('opens at the click point when the app is scaled', (tester) async {
      final origin = await menuOriginFor(
        tester,
        scale: 0.8,
        at: const Offset(500, 400),
      );

      expect(origin.dx, closeTo(500, 1));
      expect(origin.dy, closeTo(400, 1));
    });

    testWidgets('opens at the click point at full size', (tester) async {
      final origin = await menuOriginFor(
        tester,
        scale: 1.0,
        at: const Offset(500, 400),
      );

      expect(origin.dx, closeTo(500, 1));
      expect(origin.dy, closeTo(400, 1));
    });
  });
}
