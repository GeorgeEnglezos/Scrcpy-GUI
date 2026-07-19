/// Command Executor
///
/// The single user-facing choke point for running commands and scripts:
/// logs the source, tracks scrcpy commands in history, respects the
/// open-in-new-window setting, and shows all snackbar/dialog feedback.
/// This is the only execution file that may import Flutter.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../services/adb_service.dart';
import '../services/commands_service.dart';
import '../services/log_service.dart';
import '../services/settings_service.dart';
import '../services/shell_runner.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/app_snackbar.dart';

class CommandExecutor {
  /// Universal entry point for running any shell command string.
  ///
  /// Respects the [SettingsService.currentSettings.openCmdWindows] setting:
  /// - true  → opens in a new terminal window
  /// - false → runs inline and shows output dialog
  ///
  /// Only tracks scrcpy commands in [CommandsService] history.
  /// All snackbar/dialog feedback is handled here — callers show nothing.
  ///
  /// [forceNewTerminal] always opens a new terminal window regardless of the
  /// `openCmdWindows` setting — for commands that need an interactive
  /// terminal (e.g. installers prompting for a sudo password).
  static Future<void> executeCommand(
    BuildContext context,
    String command, {
    String source = 'unknown',
    bool forceNewTerminal = false,
  }) async {
    LogService.info('CommandExecutor/executeCommand',
        'source=$source cmd=${LogService.sanitizeMessage(command)}');
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      'Running command...',
      duration: const Duration(seconds: 1),
    );

    // Track only scrcpy commands (case-insensitive on Windows) so ADB and
    // utility commands don't pollute the history. The executable may appear
    // bare or quoted (paths with spaces).
    final exe = AdbService.scrcpyExecutable;
    final isScrcpy = [exe, '"$exe"'].any(
      (candidate) => Platform.isWindows
          ? command.toLowerCase().startsWith(candidate.toLowerCase())
          : command.startsWith(candidate),
    );
    if (isScrcpy) {
      await CommandsService().trackCommandExecution(command);
    }

    final openInNewWindow = forceNewTerminal ||
        (SettingsService.currentSettings?.openCmdWindows ?? false);

    if (openInNewWindow) {
      await ShellRunner.runCommandInNewTerminal(command);

      if (!context.mounted) return;
      showAppSnackBar(
        context,
        'Started in new window: $command',
        type: AppSnackBarType.success,
        duration: const Duration(seconds: 2),
        clearFirst: true,
      );
    } else {
      final result = await ShellRunner.runCommand(command);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (result.isNotEmpty) {
        _showOutputDialog(context, command, result);
      } else {
        showAppSnackBar(
          context,
          'Failed to run command: $command',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  /// Shows a scrollable output dialog for inline command results.
  static void _showOutputDialog(
    BuildContext context,
    String command,
    String output,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.appSurface,
        titleTextStyle: TextStyle(
          color: dialogContext.appTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        title: Text('Output for: $command'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              output.isNotEmpty ? output : 'No output received.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: dialogContext.appTextPrimary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Close', style: TextStyle(color: dialogContext.appPrimary)),
          ),
        ],
      ),
    );
  }

  /// Runs a script file from disk in a new terminal window.
  ///
  /// Always opens a new window regardless of [SettingsService] settings.
  /// No success snackbar is shown — the terminal window is the feedback.
  /// Shows an error snackbar on failure.
  static Future<void> executeScriptFile(
    BuildContext context,
    String filePath, {
    String source = 'unknown',
  }) async {
    LogService.info(
      'CommandExecutor/executeScriptFile',
      'source=$source path="$filePath"',
    );
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      'Running script...',
      duration: const Duration(seconds: 1),
    );

    try {
      final launched = await ShellRunner.runScriptFileInNewTerminal(filePath);
      if (!launched) {
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          'No terminal emulator found. Install one of: '
          'gnome-terminal, konsole, xfce4-terminal, lxterminal',
          type: AppSnackBarType.error,
        );
      }
    } catch (e) {
      LogService.error(
        'CommandExecutor/executeScriptFile',
        'executeScriptFile failed for "$filePath": $e',
      );
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        'Error running script: $e',
        type: AppSnackBarType.error,
      );
    }
  }

  /// Derives the base filename for a generated script from command flags.
  /// Returns joined name parts from --record and --start-app flags,
  /// falling back to 'scrcpy' if neither is present.
  @visibleForTesting
  static String deriveScriptBaseName(String command) {
    final nameParts = <String>[];

    if (command.contains('--record')) {
      nameParts.add('recording');
    }

    final packageRegex = RegExp(
      r'--start-app[=\s]+(?:\\?"([^"]+)\\?"|([^\s]+))',
    );
    final match = packageRegex.firstMatch(command);
    if (match != null) {
      final packageName = (match.group(1) ?? match.group(2) ?? '')
          .replaceAll(r'\"', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll(r'\', '');
      if (packageName.isNotEmpty) {
        nameParts.add(packageName);
      }
    }

    return nameParts.isEmpty ? 'scrcpy' : nameParts.join('_');
  }

  /// Saves [command] as a platform-appropriate script file in the configured
  /// downloads directory.
  ///
  /// [command] must already contain the full executable path
  /// (as produced by CommandNotifier.fullCommand).
  /// It is written verbatim into the script file.
  static Future<void> generateScript(
    BuildContext context,
    String command,
  ) async {
    final downloadsDir =
        SettingsService.currentSettings?.downloadsDirectory ?? '';

    if (downloadsDir.isEmpty) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        'Downloads directory not configured in settings',
        type: AppSnackBarType.error,
      );
      return;
    }

    try {
      final directory = Directory(downloadsDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final baseFilename = deriveScriptBaseName(command);

      String fileExtension;
      String fileContent;

      if (Platform.isWindows) {
        fileExtension = '.bat';
        fileContent = '@echo off\n$command\npause';
      } else if (Platform.isMacOS) {
        fileExtension = '.command';
        fileContent =
            '#!/bin/bash\n$command\nread -p "Press any key to continue..."';
      } else {
        fileExtension = '.sh';
        fileContent =
            '#!/bin/bash\n$command\nread -p "Press any key to continue..."';
      }

      // Find a free filename: try base first, then base (1), base (2), ...
      String filename = baseFilename;
      int counter = 1;
      while (await File('$downloadsDir/$filename$fileExtension').exists()) {
        filename = '$baseFilename ($counter)';
        counter++;
      }

      final file = File('$downloadsDir/$filename$fileExtension');
      await file.writeAsString(fileContent);

      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', file.path]);
      }

      if (!context.mounted) return;
      showAppSnackBar(
        context,
        'Saved to ${file.path}',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      LogService.error(
          'CommandExecutor/generateScript', 'Failed to save script', err: e);
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        'Error saving script: $e',
        type: AppSnackBarType.error,
      );
    }
  }
}
