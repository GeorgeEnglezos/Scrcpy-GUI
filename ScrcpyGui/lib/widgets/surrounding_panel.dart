/// Reusable panel wrapper with consistent styling and header.
///
/// This widget provides a standardized container for content panels with
/// a titled header, optional action buttons, and category-specific theming.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/clear_notifier.dart';
import '../services/settings_service.dart';

/// Theme configuration for panel styling.
///
/// Defines primary and secondary colors for panel headers and accents.
class PanelTheme {
  /// Primary color for the panel theme
  final Color primary;

  /// Secondary color for the panel theme
  final Color secondary;

  /// Creates a panel theme with primary and secondary colors.
  const PanelTheme({required this.primary, required this.secondary});
}

/// A container widget that wraps content with a themed header and optional controls.
///
/// The [SurroundingPanel] provides a consistent UI pattern for grouping related
/// content with a header showing an icon, title, and optional action buttons.
/// Different panel types can have different color themes.
///
/// Example:
/// ```dart
/// SurroundingPanel(
///   icon: Icons.settings,
///   title: 'Advanced Settings',
///   panelType: 'Advanced',
///   showButton: true,
///   onClearPressed: () => clearFields(),
///   child: Column(children: [...]),
/// )
/// ```
class SurroundingPanel extends StatefulWidget {
  /// Icon displayed in the panel header
  final IconData icon;

  /// Title text displayed in the panel header
  final String title;

  /// The content widget displayed inside the panel
  final Widget child;

  /// Whether to show the action button
  final bool showButton;

  /// Icon for the optional action button
  final IconData? buttonIcon;

  /// Callback for the action button press
  final VoidCallback? onButtonPressed;

  /// Callback for the clear button press
  final VoidCallback? onClearPressed;

  /// Optional controller for coordinated clear operations
  final ClearController? clearController;

  /// Whether to show a "Clear All" button
  final bool showClearAllButton;

  /// Top padding for the content area
  final double topContentPadding;

  /// Custom padding for the content area
  final EdgeInsets? contentPadding;

  /// Panel type identifier for theme selection
  final String panelType;

  /// Panel ID to look up settings (e.g., 'actions', 'package', etc.)
  final String? panelId;

  /// Whether the panel is locked in expanded state and cannot be collapsed
  final bool lockedExpanded;

  /// Creates a surrounding panel with header and content.
  const SurroundingPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.showButton = true,
    this.buttonIcon = Icons.cleaning_services,
    this.onButtonPressed,
    this.onClearPressed,
    this.clearController,
    this.showClearAllButton = false,
    this.topContentPadding = 0.0,
    this.contentPadding,
    this.panelType = "Default",
    this.panelId,
    this.lockedExpanded = false,
  });

  @override
  State<SurroundingPanel> createState() => _SurroundingPanelState();
}

class _SurroundingPanelState extends State<SurroundingPanel> {
  bool isExpanded = true;

  bool get _isLockedExpanded {
    // Check if explicitly set to locked
    if (widget.lockedExpanded) return true;

    // Check settings if panelId is provided
    if (widget.panelId != null) {
      final settings = SettingsService.currentSettings;
      if (settings != null) {
        final panel = settings.panelOrder.firstWhere(
          (p) => p.id == widget.panelId,
          orElse: () => settings.panelOrder.first,
        );
        return panel.lockedExpanded;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    widget.clearController?.addListener(_onClearAll);
    // If locked expanded, ensure it starts expanded
    if (_isLockedExpanded) {
      isExpanded = true;
    }
  }

  @override
  void dispose() {
    widget.clearController?.removeListener(_onClearAll);
    super.dispose();
  }

  void _onClearAll() {
    widget.onClearPressed?.call();
  }

  static final Map<String, PanelTheme> themeMap = {
    "Default": PanelTheme(
      primary: AppColors.primary,
      secondary: AppColors.primaryDark,
    ),
    "Recording": PanelTheme(
      primary: AppColors.recordingPrimary,
      secondary: AppColors.recordingSecondary,
    ),
    "Virtual Display": PanelTheme(
      primary: AppColors.virtualDisplayPrimary,
      secondary: AppColors.virtualDisplaySecondary,
    ),
    "General": PanelTheme(
      primary: AppColors.generalPrimary,
      secondary: AppColors.generalSecondary,
    ),
    "Audio": PanelTheme(
      primary: AppColors.audioPrimary,
      secondary: AppColors.audioSecondary,
    ),
    "Package Selector": PanelTheme(
      primary: AppColors.packagePrimary,
      secondary: AppColors.packageSecondary,
    ),
  };

  PanelTheme get currentTheme =>
      themeMap[widget.panelType] ?? themeMap["Default"]!;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _isLockedExpanded
                ? null
                : () => setState(() => isExpanded = !isExpanded),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: currentTheme.primary.withValues(alpha: 0.1),
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                    : BorderRadius.circular(12),
                border: isExpanded
                    ? Border(
                        bottom: BorderSide(
                          color: currentTheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: currentTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: currentTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (widget.showClearAllButton)
                    TextButton.icon(
                      onPressed: () {
                        widget.clearController?.clearAll();
                      },
                      icon: Icon(
                        Icons.clear_all,
                        color: currentTheme.primary,
                        size: 18,
                      ),
                      label: Text(
                        'Clear All',
                        style: TextStyle(color: currentTheme.primary),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: currentTheme.primary.withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  if (widget.showButton && !widget.showClearAllButton)
                    IconButton(
                      onPressed:
                          widget.onClearPressed ??
                          widget.onButtonPressed ??
                          () {},
                      icon: Icon(
                        widget.buttonIcon!,
                        color: currentTheme.primary,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: currentTheme.primary.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  Icon(
                    _isLockedExpanded
                        ? Icons.lock
                        : (isExpanded ? Icons.expand_less : Icons.expand_more),
                    color: currentTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: ConstrainedBox(
              constraints: isExpanded
                  ? const BoxConstraints()
                  : const BoxConstraints(maxHeight: 0),
              child: ClipRect(
                child: Padding(
                  padding: widget.contentPadding ??
                      EdgeInsets.only(
                        top: widget.topContentPadding,
                        left: 24,
                        right: 24,
                        bottom: 24,
                      ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
