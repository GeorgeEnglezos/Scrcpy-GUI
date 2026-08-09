import 'package:flutter/material.dart';

/// Shrinks the whole app so more content fits in the same window.
///
/// Lays the child out against a canvas enlarged by `1 / scale`, then paints it
/// at [scale], so text, icons, padding and panel widths shrink together. A
/// [scale] of 1.0 is a pass-through.
///
/// [scale] must be greater than 0. Values coming from settings are already
/// clamped to the supported range; the assert is there so a bad call site fails
/// with a clear message instead of dividing by zero and crashing deep inside
/// the layout pipeline.
class UiScale extends StatelessWidget {
  const UiScale({super.key, required this.scale, required this.child})
    : assert(scale > 0, 'scale must be greater than 0');

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (scale == 1.0) return child;

    final mq = MediaQuery.of(context);
    final size = Size(mq.size.width / scale, mq.size.height / scale);

    return MediaQuery(
      data: mq.copyWith(size: size),
      // FittedBox, not Transform+OverflowBox: OverflowBox reports its own
      // hit-test size as the real (small) window, not the enlarged canvas it
      // forces on its child, so taps anywhere in the overflowed region never
      // reach the child. FittedBox scales the same way but keeps its size
      // gate on the child's actual (enlarged) bounds, so hit-testing stays
      // correct everywhere the content is painted.
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(width: size.width, height: size.height, child: child),
      ),
    );
  }
}
