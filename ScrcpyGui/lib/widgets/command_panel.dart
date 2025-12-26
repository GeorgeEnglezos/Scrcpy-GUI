/// Widget for displaying scrcpy commands with syntax highlighting and actions.
///
/// This widget shows command strings with color-coded syntax highlighting
/// and provides actions like copy, delete, and download.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../utils/command_syntax_highlighter.dart';

/// A display panel for scrcpy commands with syntax highlighting and actions.
///
/// The [CommandPanel] renders command strings with syntax highlighting
/// using [CommandSyntaxHighlighter] and provides interactive buttons for
/// common operations like copying to clipboard, deleting, and downloading.
///
/// Features:
/// - Syntax-highlighted command display
/// - Copy to clipboard functionality
/// - Optional delete action
/// - Optional download action
/// - Tap interaction support
///
/// Example:
/// ```dart
/// CommandPanel(
///   command: 'scrcpy --record output.mp4 --audio-codec opus',
///   onTap: () => executeCommand(),
///   onDelete: () => deleteCommand(),
///   showDelete: true,
/// )
/// ```
class CommandPanel extends StatelessWidget {
  /// The scrcpy command string to display
  final String command;

  /// Callback when the panel is tapped
  final VoidCallback? onTap;

  /// Callback for the delete button
  final VoidCallback? onDelete;

  /// Callback for the download button
  final VoidCallback? onDownload;

  /// Whether to show the delete button
  final bool showDelete;

  /// Creates a command display panel.
  const CommandPanel({
    super.key,
    required this.command,
    this.onTap,
    this.onDelete,
    this.onDownload,
    this.showDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.commandGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.commandGrey),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.commandGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: RichText(
                  text: TextSpan(
                    children: CommandSyntaxHighlighter.getColorizedSpans(
                      command,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: "Copy to clipboard",
                  iconSize: 20,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: command));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Command copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                if (onDownload != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: "Download BAT",
                    iconSize: 20,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: onDownload,
                  ),
                ],
                if (showDelete && onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: "Delete",
                    iconSize: 20,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
