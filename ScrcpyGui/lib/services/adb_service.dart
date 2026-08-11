/// ADB Service
///
/// Everything that talks to adb or scrcpy as a tool: executable resolution,
/// device queries, package listing, encoder parsing, and wireless setup.
/// No Flutter UI imports; feedback belongs to the widget layer.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'log_service.dart';
import 'settings_service.dart';
import 'shell_runner.dart';

/// Outcome of a quick adb reachability probe. Deliberately data, not a
/// display string: formatting belongs to the widget layer.
class AdbStatus {
  /// True when adb ran and exited cleanly.
  final bool reachable;

  /// Devices `adb devices` listed. Always 0 when [reachable] is false.
  final int deviceCount;

  const AdbStatus({required this.reachable, required this.deviceCount});
}

class AdbService {
  /// Returns the adb executable path.
  ///
  /// Uses the configured scrcpy directory from settings if set,
  /// otherwise falls back to 'adb' (relies on PATH).
  static String get adbExecutable {
    final dir = SettingsService.currentSettings?.scrcpyDirectory ?? '';
    if (dir.isEmpty) return 'adb';
    return p.join(dir, Platform.isWindows ? 'adb.exe' : 'adb');
  }

  /// Returns the scrcpy executable path.
  ///
  /// Uses the configured scrcpy directory from settings if set,
  /// otherwise falls back to 'scrcpy' (relies on PATH).
  static String get scrcpyExecutable {
    final dir = SettingsService.currentSettings?.scrcpyDirectory ?? '';
    if (dir.isEmpty) return 'scrcpy';
    return p.join(dir, Platform.isWindows ? 'scrcpy.exe' : 'scrcpy');
  }

  /// Whether [directory] contains the platform's scrcpy executable.
  ///
  /// Used to reject a folder the user picked before it is persisted, since a
  /// wrong scrcpyDirectory also breaks adb resolution. Goes through
  /// [ShellRunner.hostFileExists] so that under Flatpak the check runs on the
  /// same host that will actually run scrcpy, not the sandbox's limited view.
  static Future<bool> hasScrcpyIn(String directory) {
    final exeName = Platform.isWindows ? 'scrcpy.exe' : 'scrcpy';
    return ShellRunner.hostFileExists(p.join(directory, exeName));
  }

  /// Test-only override for the WinGet packages root, so the on-disk search
  /// can run against a temp directory instead of the developer's real one.
  @visibleForTesting
  static String? debugWingetPackagesRoot;

  /// Where WinGet extracts portable packages, or null when that cannot apply.
  static String? _wingetPackagesRoot() {
    final override = debugWingetPackagesRoot;
    if (override != null) return override;
    if (!Platform.isWindows) return null;
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null) return null;
    return p.join(localAppData, 'Microsoft', 'WinGet', 'Packages');
  }

  /// Looks on disk for a scrcpy that PATH cannot see, returning the directory
  /// holding the executable, or null.
  ///
  /// A process keeps the PATH it inherited when it launched. WinGet extracts
  /// scrcpy into a directory stamped with the version (`scrcpy-win64-v4.1`)
  /// and rewrites PATH to match, so an app that was already running both
  /// misses the new entry and keeps a stale one pointing at the previous
  /// version's now-deleted folder. PATH therefore cannot confirm an install
  /// the user just performed, however long they wait.
  ///
  /// [wingetPackagesRoot] overrides the search root for tests.
  static Future<String?> findScrcpyDirectory({
    String? wingetPackagesRoot,
  }) async {
    final root = wingetPackagesRoot ?? _wingetPackagesRoot();
    if (root == null) return null;

    final rootDir = Directory(root);
    if (!await rootDir.exists()) return null;

    final matches = <Directory>[];
    await for (final package in rootDir.list()) {
      if (package is! Directory) continue;
      if (!p.basename(package.path).startsWith('Genymobile.scrcpy')) continue;

      // The executable sits one level down, in the version folder, but check
      // the package root too in case that layout ever changes.
      if (await hasScrcpyIn(package.path)) matches.add(package);
      await for (final version in package.list()) {
        if (version is Directory && await hasScrcpyIn(version.path)) {
          matches.add(version);
        }
      }
    }

    if (matches.isEmpty) return null;

    // An upgrade can leave an older version folder behind, so prefer the most
    // recently written one.
    matches.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return matches.first.path;
  }

  /// Wraps [executable] in double quotes when it contains spaces, so that
  /// user-facing command strings survive tokenization and `bash -c`
  /// (e.g. a scrcpy directory under "C:\Program Files").
  static String quoteExecutable(String executable) =>
      executable.contains(' ') ? '"$executable"' : executable;

  /// Rewrites the scrcpy executable prefix in a command to match the
  /// current configured [scrcpyExecutable]. Handles bare names and full
  /// paths; the emitted executable is quoted when it contains spaces.
  static String normalizeScrcpyExecutable(String cmd) {
    final exe = quoteExecutable(scrcpyExecutable);
    final normalized = cmd.replaceFirst(
      RegExp(r'^"[^"]*[/\\]scrcpy(?:\.exe)?"(?=\s|$)', caseSensitive: false),
      exe,
    );
    if (normalized != cmd) return normalized;
    return cmd.replaceFirst(
      RegExp(
        r'^(?:"[^"]*"|[^\s"]+[/\\])?scrcpy(?:\.exe)?(?=\s|$)',
        caseSensitive: false,
      ),
      exe,
    );
  }

  /// Replaces the full scrcpy executable path in a command string with just
  /// "scrcpy". Used for display; the full path is preserved for execution
  /// and clipboard.
  static String toDisplayCommand(String cmd) {
    final exe = scrcpyExecutable;
    if (exe == 'scrcpy') return _stripSerial(cmd);

    // Normalise both sides for comparison so that mixed separators and
    // casing differences on Windows don't prevent the match.
    // Checks the bare executable and the quoted form: "C:\path\scrcpy.exe".
    final normalizedCmd = p.normalize(cmd);
    for (final candidate in [exe, '"$exe"']) {
      final normalized = p.normalize(candidate);
      final matches = Platform.isWindows
          ? normalizedCmd.toLowerCase().startsWith(normalized.toLowerCase())
          : normalizedCmd.startsWith(normalized);
      if (matches) {
        return _stripSerial('scrcpy${cmd.substring(candidate.length)}');
      }
    }

    return _stripSerial(cmd);
  }

  /// Strips `--serial <value>` / `--serial=<value>` / `-s <value>` from a
  /// command string so device identifiers are not shown in the UI.
  static String _stripSerial(String cmd) {
    // --serial=value  or  --serial value  (with optional quotes)
    cmd = cmd.replaceAll(
      RegExp(r'\s*--serial(?:=|[ \t]+)"[^"]*"', caseSensitive: false),
      '',
    );
    cmd = cmd.replaceAll(
      RegExp(r"\s*--serial(?:=|[ \t]+)'[^']*'", caseSensitive: false),
      '',
    );
    cmd = cmd.replaceAll(
      RegExp(r'\s*--serial(?:=|[ \t]+)\S+', caseSensitive: false),
      '',
    );
    // -s value  (with optional quotes)
    cmd = cmd.replaceAll(RegExp(r'\s+-s[ \t]+"[^"]*"'), '');
    cmd = cmd.replaceAll(RegExp(r"\s+-s[ \t]+'[^']*'"), '');
    cmd = cmd.replaceAll(RegExp(r'\s+-s[ \t]+\S+'), '');
    return cmd.trim();
  }

  /// Targets [command] at [serial]: any existing `--serial`/`-s` is removed
  /// first so a stored device never lingers, then `--serial=<serial>` is
  /// appended. A null/empty [serial] returns the command serial-free, which
  /// lets scrcpy auto-select when exactly one device is connected.
  ///
  /// Favorites, Last Command and Most Used are stored device-agnostic; this
  /// injects the currently selected device when they are run or downloaded.
  static String applySerial(String command, String? serial) {
    final stripped = _stripSerial(command);
    if (serial == null || serial.isEmpty) return stripped;
    return '$stripped --serial=$serial';
  }

  /// Widget tests run under fake async, which cannot complete a real process
  /// spawn, set true there so [isScrcpyOnPath] short-circuits.
  @visibleForTesting
  static bool debugSkipProcessChecks = false;

  /// Test-only override for [isScrcpyOnPath]. When non-null it is returned
  /// directly, so both the found and not-found branches are reachable without
  /// spawning a process.
  @visibleForTesting
  static bool? debugScrcpyOnPath;

  /// Test-only override for [checkAdb]. When non-null it is returned directly,
  /// so both the reachable and the missing branch are exercisable without
  /// spawning a process.
  @visibleForTesting
  static AdbStatus? debugAdbStatus;

  /// Returns true if scrcpy is resolvable on the system PATH.
  static Future<bool> isScrcpyOnPath() async {
    if (debugScrcpyOnPath != null) return debugScrcpyOnPath!;
    if (debugSkipProcessChecks) return true;
    try {
      final result = Platform.isWindows
          ? await ShellRunner.run('cmd', ['/c', 'where', 'scrcpy'])
          : await ShellRunner.run('scrcpy', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Runs adb with an explicit argument list (no shell), with Flatpak routing.
  static Future<ProcessResult> runAdbProcess(
    List<String> args, {
    Duration? timeout,
  }) =>
      ShellRunner.run(adbExecutable, args, timeout: timeout);

  /// Runs a command in the device shell and returns trimmed stdout
  /// ('' on failure).
  static Future<String> _deviceShell(
    String deviceId,
    List<String> deviceArgs,
  ) =>
      ShellRunner.runOut(
        adbExecutable,
        ['-s', deviceId, 'shell', ...deviceArgs],
      );

  /// Returns a list of connected device IDs via `adb devices`.
  /// Works with both USB and wireless (IP:port) connections.
  static Future<List<String>> adbDevices() async {
    // Timeout: a device showing the "Allow USB debugging?" prompt can hang
    // adb; without it the 2s poll piles up stuck calls.
    final output = await ShellRunner.runOut(
      adbExecutable,
      ['devices'],
      timeout: const Duration(seconds: 10),
    );
    final lines = output.split('\n');
    return lines
        .skip(1)
        .map((l) => l.split('\t').first.trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Probes whether adb is usable, and how many devices it sees.
  ///
  /// Two calls rather than one: [adbDevices] returns an empty list both when
  /// adb is missing and when adb works with nothing plugged in, so it cannot
  /// tell "broken" from "idle" on its own.
  static Future<AdbStatus> checkAdb() async {
    final override = debugAdbStatus;
    if (override != null) return override;
    if (debugSkipProcessChecks) {
      return const AdbStatus(reachable: true, deviceCount: 0);
    }

    try {
      // A missing executable raises ProcessException instead of returning a
      // non-zero exit code, so the catch is load-bearing, not defensive.
      final result = await runAdbProcess(
        ['version'],
        timeout: const Duration(seconds: 10),
      );
      if (result.exitCode != 0) {
        return const AdbStatus(reachable: false, deviceCount: 0);
      }
    } catch (_) {
      return const AdbStatus(reachable: false, deviceCount: 0);
    }

    final devices = await adbDevices();
    return AdbStatus(reachable: true, deviceCount: devices.length);
  }

  /// Lists installed packages on a device via `pm list packages`.
  ///
  /// [includeSystemApps] false (default) shows only user-installed apps
  /// (adds the -3 flag).
  static Future<List<String>> listPackages({
    required String deviceId,
    bool includeSystemApps = false,
  }) async {
    final args = ['pm', 'list', 'packages'];
    if (!includeSystemApps) args.add('-3');
    final result = await _deviceShell(deviceId, args);
    return result
        .split('\n')
        .map((line) => line.replaceAll('package:', '').trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Loads raw `scrcpy --list-encoders` output for a device.
  /// Parse it with [parseVideoEncoders] / [parseAudioEncoders].
  static Future<String> loadScrcpyEncoders({required String deviceId}) {
    return ShellRunner.runOut(
      scrcpyExecutable,
      ['--list-encoders', '-s', deviceId],
    );
  }

  /// Extracts video encoder flags from `scrcpy --list-encoders` output.
  static List<String> parseVideoEncoders(String scrcpyOutput) =>
      _parseEncoders(scrcpyOutput, 'video');

  /// Extracts audio encoder flags from `scrcpy --list-encoders` output.
  static List<String> parseAudioEncoders(String scrcpyOutput) =>
      _parseEncoders(scrcpyOutput, 'audio');

  static List<String> _parseEncoders(String scrcpyOutput, String keyword) {
    return scrcpyOutput
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('--') && l.toLowerCase().contains(keyword))
        .map((l) {
          final index = l.indexOf('(');
          final cleanLine = (index != -1 ? l.substring(0, index) : l).trim();
          return cleanLine.replaceAll(RegExp(r'\s+'), ' ');
        })
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// Validates an IPv4 address string.
  ///
  /// Returns null if valid, or an error message string if invalid.
  /// Accepts dotted-decimal notation only (e.g. '192.168.1.100').
  static String? validateIpAddress(String ipAddress) {
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ipAddress)) {
      return 'Invalid IP address format: $ipAddress';
    }
    final octets = ipAddress.split('.').map(int.parse).toList();
    if (octets.any((o) => o > 255)) {
      return 'Invalid IP address: each octet must be 0-255';
    }
    return null;
  }

  /// Enables TCP/IP mode on a USB-connected device.
  /// Returns the confirmation output, or '' on failure.
  static Future<String> enableTcpip(String deviceId, int port) async {
    // adb tcpip writes its confirmation to stderr on modern adb versions.
    // Check exit code instead of stdout content.
    try {
      final result = await ShellRunner.run(
        adbExecutable,
        ['-s', deviceId, 'tcpip', '$port'],
      );
      if (result.exitCode != 0) return '';
      final combined = '${result.stdout}${result.stderr}'.trim();
      return combined.isEmpty ? 'ok' : combined;
    } catch (e) {
      LogService.error('AdbService/enableTcpip', 'tcpip failed: $e');
      return '';
    }
  }

  /// Gets the device's WiFi IP address, trying several strategies for
  /// maximum compatibility across Android versions.
  /// Returns null if not found or device not on WiFi.
  static Future<String?> getDeviceIpAddress(String deviceId) async {
    // Parse IP address from output (looking for inet xxx.xxx.xxx.xxx)
    final ipRegex = RegExp(r'inet\s+(\d+\.\d+\.\d+\.\d+)');

    Future<String> shell(List<String> deviceArgs) =>
        _deviceShell(deviceId, deviceArgs);

    // Strategy 1: Preferred method with -f inet flag for IPv4 only
    var result = await shell(['ip', '-f', 'inet', 'addr', 'show', 'wlan0']);
    var ipMatch = ipRegex.firstMatch(result);
    if (ipMatch != null) {
      return ipMatch.group(1);
    }

    // Strategy 2: Fallback to original method without -f flag
    result = await shell(['ip', 'addr', 'show', 'wlan0']);
    ipMatch = ipRegex.firstMatch(result);
    if (ipMatch != null) {
      return ipMatch.group(1);
    }

    // Strategy 3: Try other common wireless interface names
    final interfaces = ['wlan1', 'wlan2', 'wlan3'];
    for (var iface in interfaces) {
      result = await shell(['ip', '-f', 'inet', 'addr', 'show', iface]);
      ipMatch = ipRegex.firstMatch(result);
      if (ipMatch != null) {
        return ipMatch.group(1);
      }

      result = await shell(['ip', 'addr', 'show', iface]);
      ipMatch = ipRegex.firstMatch(result);
      if (ipMatch != null) {
        return ipMatch.group(1);
      }
    }

    // Strategy 4: Try using ifconfig instead of ip command
    result = await shell(['ifconfig', 'wlan0']);
    final ifconfigRegex = RegExp(r'inet addr:(\d+\.\d+\.\d+\.\d+)');
    ipMatch = ifconfigRegex.firstMatch(result);
    if (ipMatch != null) {
      return ipMatch.group(1);
    }

    // Strategy 5: Try dumpsys wifi (Android-specific)
    result = await shell(['dumpsys', 'wifi']);
    final lines = result.split('\n');
    final wifiInfoLine = lines.firstWhere(
      (line) => line.contains('mWifiInfo'),
      orElse: () => '',
    );

    final dumpsysRegex = RegExp(r'(?:ip[=:\s]+|")(\d+\.\d+\.\d+\.\d+)');
    ipMatch = dumpsysRegex.firstMatch(wifiInfoLine);
    if (ipMatch != null) {
      final foundIp = ipMatch.group(1)!;
      if (foundIp != '0.0.0.0') {
        return foundIp;
      }
    }

    // Strategy 6: Try getprop command
    result = await shell(['getprop', 'dhcp.wlan0.ipaddress']);
    ipMatch = ipRegex.firstMatch(result);
    if (ipMatch != null) {
      return ipMatch.group(1);
    }

    return null;
  }

  /// Connects to a device via TCP/IP. Device must already be in TCP/IP mode
  /// (see [enableTcpip]).
  static Future<String> connectWireless(String ipAddress, int port) {
    return ShellRunner.runOut(adbExecutable, ['connect', '$ipAddress:$port']);
  }

  /// Disconnects a wireless ADB connection, optionally switching the device
  /// back to USB mode first.
  ///
  /// Returns a map with 'success' (bool) and 'message' (String).
  static Future<Map<String, dynamic>> disconnectWireless(
    String deviceId, {
    bool switchToUsb = true,
  }) async {
    try {
      // Step 1: Switch back to USB mode if requested
      if (switchToUsb) {
        await ShellRunner.runOut(adbExecutable, ['-s', deviceId, 'usb']);
      }

      // Step 2: Disconnect the wireless connection
      final disconnectResult =
          await ShellRunner.runOut(adbExecutable, ['disconnect', deviceId]);

      if (disconnectResult.contains('disconnected') ||
          disconnectResult.isEmpty) {
        return {
          'success': true,
          'message': 'Successfully disconnected from $deviceId',
        };
      } else {
        return {'success': false, 'message': disconnectResult};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error disconnecting: $e'};
    }
  }

  /// Complete wireless connection setup for a device.
  ///
  /// Workflow:
  /// 1. Resolves the device IP, auto-detected via [getDeviceIpAddress] when
  ///    [ipAddress] is null, otherwise the provided address is validated and
  ///    used as-is (manual mode).
  /// 2. Enables TCP/IP mode on the USB-connected device.
  /// 3. Waits for TCP/IP initialization (1.5 seconds).
  /// 4. Connects to the device wirelessly.
  ///
  /// Returns a map with 'success' (bool), 'message' (String), and
  /// 'ipAddress' (String, on success).
  static Future<Map<String, dynamic>> setupWirelessConnection(
    String deviceId,
    int port, {
    String? ipAddress,
  }) async {
    final String resolvedIp;
    if (ipAddress != null) {
      // Validate IP address format and octet ranges (0-255)
      final ipError = validateIpAddress(ipAddress);
      if (ipError != null) {
        return {'success': false, 'message': ipError};
      }
      resolvedIp = ipAddress;
    } else {
      // Get device IP address BEFORE enabling TCP/IP
      // (Important: device disconnects after tcpip command on some devices)
      final detected = await getDeviceIpAddress(deviceId);
      if (detected == null) {
        return {
          'success': false,
          'message':
              'Could not determine device IP address. Make sure device is connected to WiFi.',
        };
      }
      resolvedIp = detected;
    }

    final tcpipResult = await enableTcpip(deviceId, port);
    if (tcpipResult.isEmpty || tcpipResult.toLowerCase().contains('error')) {
      return {
        'success': false,
        'message': 'Failed to enable TCP/IP mode: $tcpipResult',
      };
    }

    // Wait for TCP/IP to initialize
    await Future.delayed(const Duration(milliseconds: 1500));

    final connectResult = await connectWireless(resolvedIp, port);
    if (connectResult.contains('connected') ||
        connectResult.contains('already connected')) {
      return {
        'success': true,
        'message': 'Successfully connected to $resolvedIp:$port',
        'ipAddress': resolvedIp,
      };
    } else {
      return {'success': false, 'message': 'Connection failed: $connectResult'};
    }
  }
}
