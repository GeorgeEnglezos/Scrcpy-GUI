/// A labelled directory path with optional Open, Browse and Clear buttons.
///
/// Shared by the Settings page and the first-run wizard. Purely presentational:
/// opening a folder and picking one both arrive as callbacks, so the widget
/// pulls in no services.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';

class DirectoryRow extends StatelessWidget {
  /// Field name shown above the path.
  final String label;

  /// The path to display. Shown verbatim, ellipsised when it overflows.
  final String path;

  /// Invoked by the Browse button. Ignored when [showBrowseButton] is false.
  final VoidCallback? onBrowse;

  /// Invoked by the Open button. Ignored when [showOpenButton] is false.
  final VoidCallback? onOpen;

  /// When non-null, a Clear button is shown that invokes this.
  final VoidCallback? onClear;

  final bool showOpenButton;
  final bool showBrowseButton;

  const DirectoryRow({
    super.key,
    required this.label,
    required this.path,
    this.onBrowse,
    this.onOpen,
    this.onClear,
    this.showOpenButton = true,
    this.showBrowseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.appTextSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.appTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.appInputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: textColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  path,
                  style: TextStyle(color: textColor, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            if (showOpenButton) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onOpen,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text(
                  'Open',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],

            if (showBrowseButton) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onBrowse,
                child: Text(
                  'Browse...',
                  style: TextStyle(color: context.appOnPrimary),
                ),
              ),
            ],

            if (onClear != null) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onClear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
