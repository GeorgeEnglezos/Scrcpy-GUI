import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../models/settings_model.dart';
import 'log_service.dart';
import 'settings_service.dart';

/// Size the window opens at when nothing has been saved yet, before it is
/// clamped to the display.
const Size kDefaultWindowSize = Size(1200, 900);

/// Floor for both the startup size and manual resizing. Must stay small
/// enough to fit a 1366x768 display, the smallest one reported in use.
const Size kMinimumWindowSize = Size(800, 600);

/// Restores the window geometry saved in [AppSettings] on launch and writes it
/// back as the user moves, resizes, or maximizes the window.
class WindowStateService with WindowListener {
  WindowStateService(this._settingsService);

  final SettingsService _settingsService;

  /// Move and resize fire continuously while dragging, so writes are coalesced
  /// into one per gesture.
  static const _saveDelay = Duration(milliseconds: 500);
  Timer? _saveTimer;

  /// Geometry to return to when the window is unmaximized. Maximized bounds
  /// overshoot the work area on Windows, so they are never what gets saved.
  Rect? _restoredBounds;

  /// The work area the window belongs on: whichever of [workAreas] holds the
  /// center of [saved], falling back to [primary]. Without this a window left
  /// on a second monitor would be dragged back to the primary one on launch.
  @visibleForTesting
  static Rect workAreaFor(
    WindowState? saved,
    List<Rect> workAreas,
    Rect primary,
  ) {
    if (saved == null) return primary;
    final center = Offset(saved.x + saved.width / 2, saved.y + saved.height / 2);
    return workAreas.firstWhere(
      (area) => area.contains(center),
      orElse: () => primary,
    );
  }

  /// The rect the window should open at: [saved] when it still fits the
  /// display, otherwise a size clamped to [workArea] and centered in it.
  static Rect resolveBounds({
    required WindowState? saved,
    required Rect workArea,
    Size fallbackSize = kDefaultWindowSize,
    Size minimumSize = kMinimumWindowSize,
  }) {
    // Available space wins over the minimum: a window bigger than the screen
    // cannot be resized back down by the user.
    double fit(double want, double min, double available) =>
        math.min(math.max(want, min), available);

    final width = fit(
      saved?.width ?? fallbackSize.width,
      minimumSize.width,
      workArea.width,
    );
    final height = fit(
      saved?.height ?? fallbackSize.height,
      minimumSize.height,
      workArea.height,
    );

    if (saved == null) {
      return Rect.fromCenter(
        center: workArea.center,
        width: width,
        height: height,
      );
    }

    // Geometry saved on a monitor that is no longer attached would put the
    // window off-screen, so pull it back inside the work area.
    return Rect.fromLTWH(
      saved.x.clamp(workArea.left, workArea.right - width),
      saved.y.clamp(workArea.top, workArea.bottom - height),
      width,
      height,
    );
  }

  /// Sizes, positions and shows the window. Call once, after settings are
  /// loaded and before [startTracking].
  Future<void> showWindow() async {
    final saved = SettingsService.currentSettings?.windowState;
    final bounds = resolveBounds(saved: saved, workArea: await _workArea(saved));
    _restoredBounds = bounds;

    final options = WindowOptions(
      size: bounds.size,
      // Never above the size we just resolved, or the platform would clamp the
      // window straight back up past the edge of a small screen.
      minimumSize: Size(
        math.min(kMinimumWindowSize.width, bounds.width),
        math.min(kMinimumWindowSize.height, bounds.height),
      ),
      title: 'Scrcpy GUI',
    );

    // Closing is intercepted so a geometry change made in the last few hundred
    // milliseconds still gets written.
    await windowManager.setPreventClose(true);

    await windowManager.waitUntilReadyToShow(options, () async {
      // Position restore is a no-op under Wayland: window_manager's set_bounds
      // uses gtk_window_move, which the compositor ignores. Size and maximized
      // still apply there.
      await windowManager.setBounds(bounds);
      await windowManager.show();
      await windowManager.focus();
      // Maximizing only takes effect once the window is on screen, and the
      // Windows runner had to stop showing it with SW_SHOWNORMAL for this to
      // survive the first frame (windows/runner/win32_window.cpp).
      if (saved?.maximized ?? false) await windowManager.maximize();
    });
  }

  /// Starts persisting geometry changes. Runs for the life of the process.
  void startTracking() => windowManager.addListener(this);

  @override
  void onWindowResize() => _scheduleSave();

  @override
  void onWindowMove() => _scheduleSave();

  @override
  void onWindowMaximize() => _scheduleSave();

  @override
  void onWindowUnmaximize() => _scheduleSave();

  /// Flushes a pending save before letting the window go, then closes it by
  /// hand because [showWindow] turned on prevent-close. The timeout is there so
  /// a stuck write can never leave the user with an unclosable window.
  @override
  void onWindowClose() async {
    _saveTimer?.cancel();
    try {
      await _save().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Losing the last resize is not worth blocking the close on.
    } finally {
      await windowManager.destroy();
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, () => unawaited(_save()));
  }

  Future<void> _save() async {
    try {
      // Windows reports a minimized window at -32000, which is not geometry
      // worth remembering.
      if (await windowManager.isMinimized()) return;

      final maximized = await windowManager.isMaximized();
      if (!maximized) _restoredBounds = await windowManager.getBounds();

      final bounds = _restoredBounds;
      final settings = SettingsService.currentSettings;
      if (bounds == null || settings == null) return;

      await _settingsService.saveSettings(
        settings.copyWith(
          windowState: WindowState(
            x: bounds.left,
            y: bounds.top,
            width: bounds.width,
            height: bounds.height,
            maximized: maximized,
          ),
        ),
        // Nothing renders window geometry, and firing the notifier here would
        // rebuild the app shell and reload the panel list on every drag.
        notify: false,
      );
    } catch (e) {
      LogService.error(
        'WindowStateService/_save',
        'Failed to persist window geometry',
        err: e,
      );
    }
  }

  /// Usable area of the display the window should open on (the screen minus
  /// the taskbar), in logical pixels. screen_retriever divides by the monitor's
  /// scale factor and window_manager multiplies bounds by the same ratio, so
  /// both ends of this already agree on units.
  Future<Rect> _workArea(WindowState? saved) async {
    Rect visibleArea(Display display) =>
        (display.visiblePosition ?? Offset.zero) &
        (display.visibleSize ?? display.size);

    try {
      final primary = visibleArea(await screenRetriever.getPrimaryDisplay());
      if (saved == null) return primary;

      final displays = await screenRetriever.getAllDisplays();
      return workAreaFor(saved, displays.map(visibleArea).toList(), primary);
    } catch (e) {
      LogService.error(
        'WindowStateService/_workArea',
        'Failed to query the primary display, falling back to the default size',
        err: e,
      );
      return Offset.zero & kDefaultWindowSize;
    }
  }
}
