/// Scrcpy keyboard shortcuts reference page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../theme/app_colors.dart';
import '../widgets/surrounding_panel.dart';

class ShortcutsPage extends StatelessWidget {
  const ShortcutsPage({super.key});

  static const _display = [
    _Shortcut('Switch fullscreen mode', ['MOD+f']),
    _Shortcut('Rotate display left', ['MOD+←']),
    _Shortcut('Rotate display right', ['MOD+→']),
    _Shortcut('Flip display horizontally', ['MOD+Shift+←', 'MOD+Shift+→']),
    _Shortcut('Flip display vertically', ['MOD+Shift+↑', 'MOD+Shift+↓']),
    _Shortcut('Pause or re-pause display', ['MOD+z']),
    _Shortcut('Unpause display', ['MOD+Shift+z']),
    _Shortcut('Reset video capture / encoding', ['MOD+Shift+r']),
  ];

  static const _window = [
    _Shortcut('Resize to 1:1 (pixel-perfect)', ['MOD+g']),
    _Shortcut(
      'Resize to remove black borders',
      ['MOD+w', 'Double-left-click'],
      'Double-click on black borders to remove them.',
    ),
  ];

  static const _deviceButtons = [
    _Shortcut('Click HOME', ['MOD+h', 'Middle-click']),
    _Shortcut(
      'Click BACK',
      ['MOD+b', 'MOD+Backspace', 'Right-click'],
      'Right-click turns the screen on if it was off, presses BACK otherwise.',
    ),
    _Shortcut('Click APP_SWITCH', [
      'MOD+s',
      '4th-click',
    ], '4th and 5th mouse buttons, if your mouse has them.'),
    _Shortcut(
      'Click MENU (unlock screen)',
      ['MOD+m'],
      'For React Native apps in development, MENU triggers the development menu.',
    ),
    _Shortcut('Click VOLUME_UP', ['MOD+↑']),
    _Shortcut('Click VOLUME_DOWN', ['MOD+↓']),
    _Shortcut('Click POWER', ['MOD+p']),
    _Shortcut(
      'Power on',
      ['Right-click'],
      'Right-click turns the screen on if it was off, presses BACK otherwise.',
    ),
  ];

  static const _screenControl = [
    _Shortcut('Turn device screen off (keep mirroring)', ['MOD+o']),
    _Shortcut('Turn device screen on', ['MOD+Shift+o']),
    _Shortcut('Rotate device screen', ['MOD+r']),
  ];

  static const _panels = [
    _Shortcut(
      'Expand notification panel',
      ['MOD+n', '5th-click'],
      '4th and 5th mouse buttons, if your mouse has them.',
    ),
    _Shortcut(
      'Expand settings panel',
      ['MOD+n+n', 'Double-5th-click'],
      '4th and 5th mouse buttons, if your mouse has them.',
    ),
    _Shortcut('Collapse panels', ['MOD+Shift+n']),
  ];

  static const _clipboard = [
    _Shortcut('Copy to clipboard', ['MOD+c'], 'Only on Android >= 7.'),
    _Shortcut('Cut to clipboard', ['MOD+x'], 'Only on Android >= 7.'),
    _Shortcut('Synchronize clipboards and paste', [
      'MOD+v',
    ], 'Only on Android >= 7.'),
    _Shortcut('Inject computer clipboard text', ['MOD+Shift+v']),
    _Shortcut('Open keyboard settings (HID keyboard only)', ['MOD+k']),
  ];

  static const _gestures = [
    _Shortcut('Enable / disable FPS counter (stdout)', ['MOD+i']),
    _Shortcut('Pinch-to-zoom / rotate', ['Ctrl+click-and-move']),
    _Shortcut('Tilt vertically (slide with 2 fingers)', [
      'Shift+click-and-move',
    ]),
    _Shortcut('Tilt horizontally (slide with 2 fingers)', [
      'Ctrl+Shift+click-and-move',
    ]),
    _Shortcut('Install APK from computer', ['Drag & drop APK']),
    _Shortcut('Push file to device', ['Drag & drop non-APK file']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final int columns = width >= 1100
                      ? 3
                      : (width >= 700 ? 2 : 1);
                  final bool isWide = width >= 900;

                  return StaggeredGrid.count(
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 1,
                        child: _buildCategory(
                          Icons.monitor,
                          'Display',
                          _display,
                          isWide,
                        ),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 1,
                        child: _buildCategory(
                          Icons.crop_free,
                          'Window',
                          _window,
                          isWide,
                        ),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 1,
                        child: _buildCategory(
                          Icons.phone_android,
                          'Device Buttons',
                          _deviceButtons,
                          isWide,
                        ),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 1,
                        child: _buildCategory(
                          Icons.light_mode,
                          'Screen Control',
                          _screenControl,
                          isWide,
                        ),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 1,
                        child: _buildCategory(
                          Icons.content_paste,
                          'Clipboard',
                          _clipboard,
                          isWide,
                        ),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 1,
                        child: _buildCategory(
                          Icons.view_agenda_outlined,
                          'Panels',
                          _panels,
                          isWide,
                        ),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: 1,
                        child: _buildCategory(
                          Icons.touch_app,
                          'Gestures & Other',
                          _gestures,
                          isWide,
                        ),
                      ),
                      StaggeredGridTile.fit(
                        crossAxisCellCount: columns,
                        child: _buildFootnotes(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Scrcpy Shortcuts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'MOD = Left Alt  or  Left Super (Win / Cmd)',
                style: TextStyle(fontSize: 12, color: AppColors.primaryLight),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(
    IconData icon,
    String title,
    List<_Shortcut> shortcuts,
    bool isWide,
  ) {
    return SurroundingPanel(
      icon: icon,
      title: title,
      showButton: false,
      lockedExpanded: true,
      contentPadding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < shortcuts.length; i++)
            _buildShortcutRow(shortcuts[i], i.isEven, isWide),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(_Shortcut shortcut, bool isEven, bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isEven
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.transparent,
      ),
      child: Builder(
        builder: (context) {
          final Widget label = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  shortcut.action,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
              if (shortcut.tooltip != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: shortcut.tooltip!,
                  child: Icon(
                    Icons.info_outline,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: label),
                const SizedBox(width: 16),
                _buildCombos(shortcut.combos),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label,
              const SizedBox(height: 6),
              _buildCombos(shortcut.combos),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCombos(List<String> combos) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < combos.length; i++) ...[
          if (i > 0)
            Text(
              'or',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          _buildSingleCombo(combos[i]),
        ],
      ],
    );
  }

  Widget _buildSingleCombo(String combo) {
    final bool isMouse =
        combo.contains('click') ||
        combo.contains('Drag') ||
        combo.contains('drop');

    if (isMouse) {
      return _buildMouseChip(combo);
    }

    // For combos like "Ctrl+click-and-move", split at the first mouse-action token
    final keys = combo.split('+');
    final List<Widget> chips = [];
    for (int i = 0; i < keys.length; i++) {
      if (i > 0) {
        chips.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
      final key = keys[i];
      if (key.contains('click') || key.contains('move')) {
        chips.add(_buildMouseChip(key));
      } else {
        chips.add(_buildKeyChip(key));
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: chips);
  }

  Widget _buildKeyChip(String key) {
    final bool isMod = key == 'MOD';
    final bool isModifier = key == 'Shift' || key == 'Ctrl' || key == 'Alt';

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isMod) {
      bgColor = AppColors.primary.withValues(alpha: 0.25);
      borderColor = AppColors.primary.withValues(alpha: 0.7);
      textColor = AppColors.primaryLight;
    } else if (isModifier) {
      bgColor = const Color(0xFF2A2A40);
      borderColor = const Color(0xFF5555AA);
      textColor = const Color(0xFFAABBFF);
    } else {
      bgColor = const Color(0xFF252525);
      borderColor = const Color(0xFF505050);
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        key,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildMouseChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2830),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3A5060), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mouse, size: 12, color: Color(0xFF7DBFDF)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7DBFDF),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootnotes() {
    return SurroundingPanel(
      icon: Icons.info_outline,
      title: 'Notes',
      showButton: false,
      lockedExpanded: true,
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNote(
            'Shortcuts with repeated keys (e.g. MOD+n+n): keep MOD held, double-press the last key, then release MOD.',
          ),
          _buildNote(
            'All Ctrl+key shortcuts are forwarded to the device and handled by the active app.',
          ),
          _buildNote(
            'The MOD key can be changed with the settings page. Options: lctrl, rctrl, lalt, ralt, lsuper, rsuper.',
          ),
        ],
      ),
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shortcut {
  final String action;
  final List<String> combos;
  final String? tooltip;

  const _Shortcut(this.action, this.combos, [this.tooltip]);
}
