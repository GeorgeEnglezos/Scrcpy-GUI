import 'dart:io';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:path/path.dart' as p;

import 'settings_service.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String source;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
  });
}

/// Singleton logging service.
///
/// Logging is off by default. Enable via Settings → "Enable logging".
/// File logging is a secondary toggle — also off by default.
///
/// Usage:
///   LogService.info('TerminalService/executeCommand', 'Running: $cmd');
///   LogService.error('TerminalService/executeCommand', 'exitCode=$code — $err');
class LogService extends ChangeNotifier {
  LogService._();

  static final LogService _instance = LogService._();
  static LogService get instance => _instance;

  // ── Internal state ────────────────────────────────────────────────────────

  static const int _maxEntries = 500;

  final List<LogEntry> _entries = [];
  bool _loggingEnabled = false;
  IOSink? _fileSink;
  String? _logFolderPath;

  // ── Public static API ─────────────────────────────────────────────────────

  /// Call once from main() after settings have been loaded.
  static Future<void> init() async {
    final i = _instance;

    // Resolve the logs folder
    final settingsDir = await SettingsService().getSettingsDirectory();
    final logsDir = p.join(settingsDir, 'logs');
    i._logFolderPath = logsDir;
    await Directory(logsDir).create(recursive: true);

    // Run file rotation (keep 7 most recent)
    await i._rotate(logsDir);

    i._loggingEnabled =
        SettingsService.currentSettings?.loggingEnabled ?? false;

    if (i._loggingEnabled) {
      await i._openFileSink(logsDir);
    }
  }

  static List<LogEntry> get entries => List.unmodifiable(_instance._entries);

  static String? get logFolderPath => _instance._logFolderPath;

  static bool get loggingEnabled => _instance._loggingEnabled;

  static void debug(String source, String message) =>
      _instance._log(LogLevel.debug, source, message);

  static void info(String source, String message) =>
      _instance._log(LogLevel.info, source, message);

  static void warning(String source, String message) =>
      _instance._log(LogLevel.warning, source, message);

  static void error(String source, String message, {Object? err}) {
    final full = err != null ? '$message\n$err' : message;
    _instance._log(LogLevel.error, source, full);
  }

  static void clear() {
    _instance._entries.clear();
    _instance.notifyListeners();
  }

  /// Toggle logging on/off live. Caller handles persistence.
  static Future<void> setLoggingEnabled(bool enabled) async {
    final i = _instance;
    i._loggingEnabled = enabled;
    if (!enabled) {
      await i._closeFileSink();
    } else if (i._logFolderPath != null && i._fileSink == null) {
      await i._openFileSink(i._logFolderPath!);
    }
    i.notifyListeners();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _log(LogLevel level, String source, String message) {
    if (!_loggingEnabled) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      source: source,
      message: message,
    );

    if (_entries.length >= _maxEntries) _entries.removeAt(0);
    _entries.add(entry);

    _fileSink?.writeln(_format(entry));

    notifyListeners();
  }

  /// Sanitizes a device ID for logging.
  /// USB serial numbers are passed through unchanged.
  /// Wireless IDs (IP:port) are partially masked: 192.168.x.x:5xxx
  static String sanitizeDevice(String? deviceId) {
    if (deviceId == null) return 'null';
    final match = RegExp(r'^(\d+\.\d+)\.\d+\.\d+:(\d)\d*$').firstMatch(deviceId);
    if (match != null) return '${match.group(1)}.x.x:${match.group(2)}xxx';
    return deviceId;
  }

  /// Sanitizes an arbitrary message string by masking any IP:port patterns.
  static String sanitizeMessage(String message) {
    return message.replaceAllMapped(
      RegExp(r'\d+\.\d+\.\d+\.\d+:\d+'),
      (m) => sanitizeDevice(m.group(0)),
    );
  }

  String _format(LogEntry e) {
    final ts = e.timestamp.toIso8601String().replaceFirst('T', ' ').substring(0, 23);
    final level = e.level.name.toUpperCase().padRight(7);
    return '$ts [$level] ${e.source}: ${e.message}';
  }

  Future<void> _openFileSink(String logsDir) async {
    final now = DateTime.now();
    final name =
        'session_${now.year.toString().padLeft(4, '0')}'
        '-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '-${now.minute.toString().padLeft(2, '0')}'
        '-${now.second.toString().padLeft(2, '0')}.log';
    final file = File(p.join(logsDir, name));
    _fileSink = file.openWrite(mode: FileMode.append);
  }

  Future<void> _closeFileSink() async {
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;
  }

  Future<void> _rotate(String logsDir) async {
    final dir = Directory(logsDir);
    if (!await dir.exists()) return;

    final files = await dir
        .list()
        .where((e) => e is File && p.basename(e.path).startsWith('session_'))
        .cast<File>()
        .toList();

    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    if (files.length >= 10) {
      for (final f in files.sublist(0, files.length - 9)) {
        await f.delete();
      }
    }
  }
}
