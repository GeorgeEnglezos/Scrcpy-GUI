/// Reusable panel wrapper with consistent styling and header.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/settings_service.dart';

class PanelTheme {
  final Color primary;
  final Color secondary;

  const PanelTheme({required this.primary, required this.secondary});
}

class SurroundingPanel extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool showButton;
  final IconData? buttonIcon;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onClearPressed;
  /// Async callback for the "save as default" button. Should return true if
  /// persistence succeeded, false otherwise. The button awaits this and
  /// shows a success or failure snackbar based on the result.
  final Future<bool> Function()? onSaveDefaultPressed;
  final double topContentPadding;
  final EdgeInsets? contentPadding;
  final String panelType;
  final String? panelId;
  final bool lockedExpanded;

  const SurroundingPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.showButton = true,
    this.buttonIcon = Icons.cleaning_services,
    this.onButtonPressed,
    this.onClearPressed,
    this.onSaveDefaultPressed,
    this.topContentPadding = 0.0,
    this.contentPadding,
    this.panelType = 'Default',
    this.panelId,
    this.lockedExpanded = false,
  });

  @override
  State<SurroundingPanel> createState() => _SurroundingPanelState();
}

class _SurroundingPanelState extends State<SurroundingPanel> {
  bool isExpanded = true;

  bool get _isLockedExpanded {
    if (widget.lockedExpanded) return true;

    if (widget.panelId != null) {
      final settings = SettingsService.currentSettings;
      if (settings != null) {
        for (final panel in settings.panelOrder) {
          if (panel.id == widget.panelId) return panel.lockedExpanded;
        }
      }
    }

    return false;
  }

  static final Map<String, PanelTheme> themeMap = {
    'Default': PanelTheme(
      primary: AppColors.primary,
      secondary: AppColors.primaryDark,
    ),
    'Recording': PanelTheme(
      primary: AppColors.recordingPrimary,
      secondary: AppColors.recordingSecondary,
    ),
    'Virtual Display': PanelTheme(
      primary: AppColors.virtualDisplayPrimary,
      secondary: AppColors.virtualDisplaySecondary,
    ),
    'General': PanelTheme(
      primary: AppColors.generalPrimary,
      secondary: AppColors.generalSecondary,
    ),
    'Audio': PanelTheme(
      primary: AppColors.audioPrimary,
      secondary: AppColors.audioSecondary,
    ),
    'Package Selector': PanelTheme(
      primary: AppColors.packagePrimary,
      secondary: AppColors.packageSecondary,
    ),
    'Display/Window': PanelTheme(
      primary: AppColors.displayWindowPrimary,
      secondary: AppColors.displayWindowSecondary,
    ),
    'Network/Connection': PanelTheme(
      primary: AppColors.networkConnectionPrimary,
      secondary: AppColors.networkConnectionSecondary,
    ),
  };

  PanelTheme get currentTheme =>
      themeMap[widget.panelType] ?? themeMap['Default']!;

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
                  if (widget.onSaveDefaultPressed != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        onPressed: () async {
                          final ok = await widget.onSaveDefaultPressed!();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Saved as default'
                                    : 'Failed to save default',
                              ),
                              backgroundColor: ok ? null : Colors.red.shade700,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.save_outlined,
                          color: currentTheme.primary,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              currentTheme.primary.withValues(alpha: 0.2),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(32, 32),
                        ),
                        tooltip: 'Save as default',
                      ),
                    ),
                  if (widget.showButton)
                    IconButton(
                      onPressed: widget.onClearPressed ??
                          widget.onButtonPressed ??
                          () {},
                      icon: Icon(
                        widget.buttonIcon!,
                        color: currentTheme.primary,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            currentTheme.primary.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  if (!_isLockedExpanded)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
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
