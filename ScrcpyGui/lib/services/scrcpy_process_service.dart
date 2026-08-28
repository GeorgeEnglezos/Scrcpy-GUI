/// Scrcpy Process Service
///
/// System-wide detection and termination of running scrcpy processes,
/// including ones not started by this app. No Flutter imports.
library;

import 'dart:convert';
import 'dart:io';

import 'log_service.dart';
import 'shell_runner.dart';

class ScrcpyProcessService {
  /// Returns all running scrcpy processes with details.
  ///
  /// Each map contains: pid, name, and, when available, fullCommand,
  /// deviceId, windowTitle, connectionType ('wireless'/'usb'),
  /// startTime (yyyyMMddHHmmss…, Windows only), memoryUsage (MB, Windows
  /// only). Empty list on error.
  static Future<List<Map<String, String>>> getScrcpyProcesses() async {
    try {
      if (Platform.isWindows) return await _getWindowsProcesses();
      if (Platform.isLinux || Platform.isMacOS) return await _getUnixProcesses();
      return [];
    } catch (e) {
      LogService.debug(
        'ScrcpyProcessService/getScrcpyProcesses',
        'Process query failed: $e',
      );
      return [];
    }
  }

  /// Single Get-CimInstance call per refresh; WMIC is removed from recent
  /// Windows 11 builds, and per-process spawns are too slow.
  static Future<List<Map<String, String>>> _getWindowsProcesses() async {
    const psScript =
        'Get-CimInstance Win32_Process -Filter "Name=\'scrcpy.exe\'" | '
        'Select-Object ProcessId,Name,CommandLine,WorkingSetSize,'
        '@{n=\'Start\';e={if (\$_.CreationDate) {\$_.CreationDate.ToString(\'yyyyMMddHHmmss\')}}} | '
        'ConvertTo-Json -Compress';
    final out = await ShellRunner.runOut(
      'powershell',
      ['-NoProfile', '-NonInteractive', '-Command', psScript],
    );
    if (out.isEmpty) return [];

    final decoded = jsonDecode(out);
    // ConvertTo-Json emits a bare object (not a 1-element array) for a
    // single process.
    final items = decoded is List ? decoded : [decoded];

    final processes = <Map<String, String>>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final pid = (item['ProcessId'] ?? '').toString();
      if (pid.isEmpty) continue;

      final details = <String, String>{
        'pid': pid,
        'name': (item['Name'] ?? 'scrcpy.exe').toString(),
      };

      final cmdLine = (item['CommandLine'] ?? '').toString();
      if (cmdLine.isNotEmpty) {
        details['fullCommand'] = cmdLine;
        details.addAll(_parseCommandDetails(cmdLine));
      }

      final start = (item['Start'] ?? '').toString();
      // Format matches WMIC CreationDate's leading yyyyMMddHHmmss, which the
      // Running Instances panel parses positionally.
      if (start.length >= 14) details['startTime'] = start;

      final mem = item['WorkingSetSize'];
      if (mem is num) {
        details['memoryUsage'] = (mem / (1024 * 1024)).toStringAsFixed(1);
      }

      processes.add(details);
    }
    return processes;
  }

  static Future<List<Map<String, String>>> _getUnixProcesses() async {
    final result = await ShellRunner.runCommand(
      'ps aux | grep -w scrcpy | grep -v grep',
    );
    if (result.isEmpty) return [];

    final processes = <Map<String, String>>[];
    for (final line in result.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final pid = parts[1];

      final details = <String, String>{'pid': pid, 'name': 'scrcpy'};
      final psOut =
          await ShellRunner.runOut('ps', ['-p', pid, '-o', 'command=']);
      if (psOut.isNotEmpty) {
        final fullCmd = psOut.split('\n').first;
        details['fullCommand'] = fullCmd;
        details.addAll(_parseCommandDetails(fullCmd));
      }
      processes.add(details);
    }
    return processes;
  }

  /// Extracts deviceId, windowTitle, and connectionType from a scrcpy
  /// command line. Shared by the Windows and Unix branches.
  static Map<String, String> _parseCommandDetails(String cmdLine) {
    final details = <String, String>{};

    // Supports both -s and --serial forms
    final deviceMatch =
        RegExp(r'(?:-s\s+|--serial[=\s]+)([^\s]+)').firstMatch(cmdLine);
    if (deviceMatch != null) {
      details['deviceId'] = deviceMatch.group(1)!;
    }

    // Supports both quoted and unquoted values
    final titleMatch = RegExp(r'--window-title[=\s]+(?:"([^"]+)"|([^\s]+))')
        .firstMatch(cmdLine);
    if (titleMatch != null) {
      details['windowTitle'] = titleMatch.group(1) ?? titleMatch.group(2) ?? '';
    }

    // IP:port pattern = wireless
    final deviceId = details['deviceId'];
    if (deviceId != null) {
      details['connectionType'] = deviceId.contains(':') ? 'wireless' : 'usb';
    }

    return details;
  }

  /// Kills a process by PID: gracefully if this app started it, otherwise
  /// via the platform kill command.
  static Future<void> killProcess(int pid) async {
    try {
      if (ShellRunner.killTrackedProcess(pid)) return;

      if (Platform.isWindows) {
        await ShellRunner.run('taskkill', ['/PID', '$pid', '/F']);
      } else {
        await ShellRunner.run('kill', ['$pid']);
      }
    } catch (e) {
      LogService.error(
        'ScrcpyProcessService/killProcess',
        'Error killing process $pid: $e',
      );
    }
  }
}
