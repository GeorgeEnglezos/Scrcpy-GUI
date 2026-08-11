import 'package:flutter/material.dart';

/// Unified feedback colors for the app's snackbars.
enum AppSnackBarType {
  /// Green: an action completed.
  success,

  /// Red: an action failed.
  error,

  /// Blue-grey: progress/status notice.
  info,

  /// Orange: completed with caveats, or user attention needed.
  warning,

  /// Theme default background: low-key confirmations (e.g. "Copied").
  neutral,
}

Color? _colorFor(AppSnackBarType type) => switch (type) {
      AppSnackBarType.success => Colors.green.shade700,
      AppSnackBarType.error => Colors.red.shade700,
      AppSnackBarType.info => Colors.blueGrey,
      AppSnackBarType.warning => Colors.orange,
      AppSnackBarType.neutral => null,
    };

/// Shows a snackbar with the app's standard color per [type].
///
/// [clearFirst] removes any currently visible snackbars first (used when a
/// progress notice is superseded by the result message).
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
  Duration duration = const Duration(seconds: 4),
  bool clearFirst = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  if (clearFirst) messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: _colorFor(type),
      duration: duration,
    ),
  );
}
