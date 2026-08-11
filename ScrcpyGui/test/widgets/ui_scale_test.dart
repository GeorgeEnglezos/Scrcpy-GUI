import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/widgets/ui_scale.dart';

void main() {
  group('UiScale', () {
    testWidgets('lays the child out against an enlarged canvas', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late Size seen;
      await tester.pumpWidget(
        MediaQuery.fromView(
          view: tester.view,
          child: UiScale(
            scale: 0.8,
            child: Builder(
              builder: (context) {
                seen = MediaQuery.of(context).size;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      // This is the whole point of the feature: the app believes it has 25%
      // more room in each dimension, so 25% more content fits.
      expect(seen.width, closeTo(1250, 0.01));
      expect(seen.height, closeTo(1000, 0.01));
    });

    testWidgets('adds nothing to the tree at 1.0', (tester) async {
      await tester.pumpWidget(
        MediaQuery.fromView(
          view: tester.view,
          child: const UiScale(scale: 1.0, child: SizedBox.expand()),
        ),
      );

      // FittedBox is the wrapper this widget actually adds, so this is what
      // goes red if the pass-through is ever dropped.
      expect(find.byType(FittedBox), findsNothing);
    });

    testWidgets('taps still land on the right widget when scaled', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var tapped = false;
      await tester.pumpWidget(
        MediaQuery.fromView(
          view: tester.view,
          child: UiScale(
            scale: 0.8,
            child: Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                // opaque: an unpainted, childless SizedBox has nothing to
                // hit-test against on its own (GestureDetector's default
                // behavior defers to the child), which would make this test
                // fail regardless of UiScale. This is the real behavior of
                // any painted control (button, icon) placed here.
                behavior: HitTestBehavior.opaque,
                onTap: () => tapped = true,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      // The target occupies (1150..1250, 900..1000) on the enlarged canvas,
      // which the transform paints at (920..1000, 720..800) in the window.
      await tester.tapAt(const Offset(960, 760));
      expect(tapped, isTrue);
    });
  });
}
