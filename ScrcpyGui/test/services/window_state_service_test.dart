import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/services/window_state_service.dart';

/// 1920x1080 at 125% scaling, minus the taskbar. This is the display the bug
/// was reported on: the old hardcoded 1200x900 window did not fit it.
const _workArea = Rect.fromLTWH(0, 0, 1536, 824);

WindowState _state(double x, double y, double w, double h) =>
    WindowState(x: x, y: y, width: w, height: h);

void main() {
  group('resolveBounds', () {
    test('shrinks the default size to fit a short work area', () {
      final bounds = WindowStateService.resolveBounds(
        saved: null,
        workArea: _workArea,
      );

      // 900 does not fit, so the height is the work area exactly; the width
      // fits and is left alone.
      expect(bounds.height, _workArea.height);
      expect(bounds.width, kDefaultWindowSize.width);
    });

    test('centers inside the work area when nothing is saved', () {
      const workArea = Rect.fromLTWH(1920, 40, 1536, 824);
      final bounds = WindowStateService.resolveBounds(
        saved: null,
        workArea: workArea,
      );

      expect(bounds.center.dx, closeTo(workArea.center.dx, 0.01));
      expect(bounds.center.dy, closeTo(workArea.center.dy, 0.01));
    });

    test('returns a saved rect that already fits untouched', () {
      final bounds = WindowStateService.resolveBounds(
        saved: _state(100, 50, 1000, 700),
        workArea: _workArea,
      );

      expect(bounds, const Rect.fromLTWH(100, 50, 1000, 700));
    });

    test('clamps a saved size larger than the work area', () {
      final bounds = WindowStateService.resolveBounds(
        saved: _state(0, 0, 3000, 2000),
        workArea: _workArea,
      );

      expect(bounds.width, _workArea.width);
      expect(bounds.height, _workArea.height);
    });

    test('pulls a saved rect left behind on a disconnected monitor back in', () {
      final bounds = WindowStateService.resolveBounds(
        saved: _state(2600, 900, 1000, 700),
        workArea: _workArea,
      );

      expect(_workArea.contains(bounds.topLeft), isTrue);
      expect(_workArea.contains(bounds.bottomRight - const Offset(1, 1)), isTrue);
    });

    test('grows a saved size below the minimum back up to it', () {
      final bounds = WindowStateService.resolveBounds(
        saved: _state(0, 0, 200, 150),
        workArea: _workArea,
      );

      expect(bounds.width, kMinimumWindowSize.width);
      expect(bounds.height, kMinimumWindowSize.height);
    });

    test('the work area wins when it is smaller than the minimum', () {
      const tiny = Rect.fromLTWH(0, 0, 640, 480);
      final bounds = WindowStateService.resolveBounds(
        saved: null,
        workArea: tiny,
      );

      expect(bounds, tiny);
    });
  });

  group('workAreaFor', () {
    const secondary = Rect.fromLTWH(1536, 0, 1920, 1040);

    test('keeps a window left on a second monitor there', () {
      final area = WindowStateService.workAreaFor(
        _state(2000, 200, 1000, 700),
        const [_workArea, secondary],
        _workArea,
      );

      expect(area, secondary);
    });

    test('falls back to primary when that monitor is gone', () {
      final area = WindowStateService.workAreaFor(
        _state(2000, 200, 1000, 700),
        const [_workArea],
        _workArea,
      );

      expect(area, _workArea);
    });
  });

  group('WindowState', () {
    // Persisted inside scrcpy_gui_settings.json — the key names are a contract
    // with every settings file already on disk.
    test('survives a json round-trip', () {
      const state = WindowState(
        x: 12,
        y: 34,
        width: 1000,
        height: 700,
        maximized: true,
      );

      final restored = WindowState.fromJson(state.toJson());
      expect(restored?.x, state.x);
      expect(restored?.y, state.y);
      expect(restored?.width, state.width);
      expect(restored?.height, state.height);
      expect(restored?.maximized, state.maximized);
    });

    // A settings file torn by a crash mid-write must cost the geometry only.
    // This is parsed inside main() before runApp, so a throw here would mean
    // the app never opens at all.
    test('parses to null instead of throwing on a half-written map', () {
      expect(WindowState.fromJson({'x': 10.0, 'y': 20.0}), isNull);
      expect(WindowState.fromJson({}), isNull);
      expect(WindowState.fromJson(null), isNull);
    });

    test('rides along in AppSettings json', () {
      final settings = AppSettings.defaultSettings().copyWith(
        windowState: const WindowState(x: 5, y: 6, width: 900, height: 650),
      );

      final restored = AppSettings.fromJsonString(settings.toJsonString());
      expect(restored.windowState?.width, 900);
      expect(restored.windowState?.y, 6);
    });

    test('defaults to null for settings files written before this existed', () {
      final restored = AppSettings.fromJsonString('{}');
      expect(restored.windowState, isNull);
    });
  });
}
