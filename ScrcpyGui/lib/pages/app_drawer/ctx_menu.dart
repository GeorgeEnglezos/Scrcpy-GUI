/// Custom overlay context menu for the App Drawer.
library;

import 'package:flutter/material.dart';

import '../../theme/app_theme_colors.dart';

/// A single row in the custom overlay context menu.
class CtxMenuItem {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final bool showChevron;
  final VoidCallback onTap;

  CtxMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.showChevron = false,
  });
}

/// Draws context menus directly into the root [Overlay].
///
/// We do not use [showMenu]/[PopupRoute] here: on the Linux/Flatpak build
/// that route never paints (the menu is "reached" but nothing appears).
/// A self-managed [OverlayEntry] with a dismiss barrier works reliably.
class CtxMenuController {
  OverlayEntry? _entry;

  /// Dismisses the context-menu overlay if one is showing.
  void dismiss() {
    _entry?.remove();
    _entry = null;
  }

  /// [position] is a global (window) coordinate, typically a gesture's
  /// globalPosition.
  void show(BuildContext context, Offset position, List<CtxMenuItem> items) {
    dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);

    // The overlay paints inside the app's UI scale transform, so a global
    // position used as a raw Positioned offset lands short of the click by the
    // scale factor. globalToLocal undoes every ancestor transform, and the
    // clamp below then compares like with like by measuring the overlay itself.
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final local = overlayBox?.globalToLocal(position) ?? position;
    final screen = overlayBox?.size ?? MediaQuery.sizeOf(context);

    const menuWidth = 240.0;
    final estHeight = items.length * 42.0 + 8;
    var left = local.dx;
    var top = local.dy;
    if (left + menuWidth > screen.width - 8) {
      left = screen.width - menuWidth - 8;
    }
    if (top + estHeight > screen.height - 8) top = screen.height - estHeight - 8;
    if (left < 8) left = 8;
    if (top < 8) top = 8;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: dismiss,
              onSecondaryTap: dismiss,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: menuWidth,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.appDivider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in items)
                      InkWell(
                        onTap: () {
                          dismiss();
                          item.onTap();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 18,
                                color:
                                    item.iconColor ?? context.appTextSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: context.appTextPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (item.showChevron)
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: context.appTextSecondary,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
  }
}
