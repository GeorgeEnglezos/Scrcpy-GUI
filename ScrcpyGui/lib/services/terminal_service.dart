/// Terminal Service
///
/// Handles all shell command execution, process management, and system integration.
/// Provides cross-platform support for Windows, macOS, and Linux.
///
/// Key Responsibilities:
/// - Execute shell commands (same terminal or new window)
/// - Manage scrcpy process lifecycle (start, monitor, kill)
/// - ADB integration (device detection, package listing, wireless setup)
/// - Parse scrcpy encoder information
/// - System-wide process detection and monitoring
library;

import 'dart:io';
import '../constants/package_names.dart';

/// Service for executing terminal commands and managing system processes
///
/// This service provides a comprehensive API for interacting with the system shell,
/// managing Android Debug Bridge (ADB) devices, and controlling scrcpy processes.
///
/// All methods are static as this service maintains no instance state beyond
/// process tracking.
class TerminalService {
  // Command templates
  static const adbDevicesCmd = 'adb devices';
  static const adbPackagesCmd = 'adb shell pm list packages';
  static const scrcpyCodecCmd = 'scrcpy --list-encoders';

  /// Track running processes started through the app
  ///
  /// Maps process ID to Process object for lifecycle management
  static final Map<int, Process> _runningProcesses = {};

  /// Runs a command in the same terminal and returns stdout
  ///
  /// Executes a shell command synchronously and waits for completion.
  /// Platform-specific execution:
  /// - Windows: Uses `cmd /c [command]`
  /// - Unix-like: Uses `bash -c [command]`
  ///
  /// [command] The shell command to execute
  ///
  /// Returns the command's stdout output as a trimmed string, or empty string on error
  ///
  /// Example:
  /// ```dart
  /// final devices = await TerminalService.runCommand('adb devices');
  /// ```
  static Future<String> runCommand(String command) async {
    try {
      // On macOS/Linux, we need to ensure the PATH includes common binary locations
      // where adb and scrcpy might be installed (Homebrew, user installations, etc.)
      final environment = Platform.isWindows
          ? null
          : {
              'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${Platform.environment['PATH'] ?? ''}',
            };

      final result = await Process.run(
        Platform.isWindows ? 'cmd' : 'bash',
        Platform.isWindows ? ['/c', command] : ['-c', command],
        environment: environment,
      );
      return result.stdout.toString().trim();
    } catch (e) {
      stderr.writeln('Error running command: $e');
      return '';
    }
  }

  /// Runs a command in a new terminal window (cross-platform)
  ///
  /// Opens a new terminal window and executes the command within it.
  /// The terminal window remains open after command execution.
  ///
  /// Platform-specific behavior:
  /// - Windows: Opens new cmd window with `cmd /k`
  /// - Linux: Auto-detects available terminal (gnome-terminal, konsole, xfce4-terminal, lxterminal)
  /// - macOS: Uses AppleScript to control Terminal.app
  ///
  /// [command] The shell command to execute in the new window
  ///
  /// Process tracking:
  /// - Started processes are tracked in [_runningProcesses]
  /// - stdout/stderr are logged with PID prefix
  /// - Process is auto-removed from tracking on exit
  ///
  /// Example:
  /// ```dart
  /// await TerminalService.runCommandInNewTerminal('scrcpy -s device123');
  /// ```
  static Future<void> runCommandInNewTerminal(String command) async {
    try {
      Process process;

      if (Platform.isWindows) {
        process = await Process.start('cmd', [
          '/c',
          'start',
          'cmd',
          '/k',
          command,
        ]);
      } else if (Platform.isLinux) {
        final terminals = [
          'gnome-terminal',
          'x-terminal-emulator',
          'konsole',
          'xfce4-terminal',
          'lxterminal',
        ];
        String? terminalCmd;
        for (var t in terminals) {
          if (await _isCommandAvailable(t)) {
            terminalCmd = t;
            break;
          }
        }
        if (terminalCmd != null) {
          process = await Process.start(terminalCmd, [
            '--',
            'bash',
            '-c',
            '$command; exec bash',
          ]);
        } else {
          stderr.writeln('No terminal emulator found to run the command.');
          return;
        }
      } else if (Platform.isMacOS) {
        // On macOS, we need to ensure PATH is set when opening a new Terminal window
        // This wraps the command with PATH export to include Homebrew and common locations
        final wrappedCommand = 'export PATH="/opt/homebrew/bin:/usr/local/bin:\$PATH" && $command';
        process = await Process.start('osascript', [
          '-e',
          'tell application "Terminal" to do script "$wrappedCommand"',
        ]);
      } else {
        stderr.writeln('Unsupported platform');
        return;
      }

      _runningProcesses[process.pid] = process;

      // Optional: listen to output
      process.stdout.transform(SystemEncoding().decoder).listen((data) {
        stdout.write('[PID ${process.pid}] $data');
      });
      process.stderr.transform(SystemEncoding().decoder).listen((data) {
        stderr.write('[PID ${process.pid}] $data');
      });

      process.exitCode.then((_) {
        _runningProcesses.remove(process.pid);
      });
    } catch (e) {
      stderr.writeln('Error opening new terminal: $e');
    }
  }

  /// Returns all running process IDs started via app
  ///
  /// Returns a list of PIDs for processes tracked in [_runningProcesses].
  /// Only includes processes started through [runCommandInNewTerminal].
  static List<int> getRunningProcessIds() => _runningProcesses.keys.toList();

  /// Get all running scrcpy processes from the system with detailed information
  ///
  /// Performs system-wide detection of scrcpy processes, even those not started
  /// by this application. Extracts detailed information from each process.
  ///
  /// Platform-specific detection:
  /// - Windows: Uses `tasklist | findstr /I scrcpy.exe` with WMIC for details
  /// - Linux/macOS: Uses `ps aux | grep scrcpy` for process enumeration
  ///
  /// Extracted information:
  /// - pid: Process ID
  /// - name: Process name (scrcpy.exe or scrcpy)
  /// - fullCommand: Complete command line with all arguments
  /// - deviceId: Extracted from `-s` flag
  /// - windowTitle: Extracted from `--window-title` flag
  /// - connectionType: 'wireless' (IP:port) or 'usb' (device ID)
  /// - startTime: Process creation timestamp (Windows only)
  /// - memoryUsage: Working set size in MB (Windows only)
  ///
  /// Returns a list of maps containing process details, or empty list on error
  ///
  /// Example output:
  /// ```dart
  /// [
  ///   {
  ///     'pid': '12345',
  ///     'deviceId': '192.168.1.100:5555',
  ///     'windowTitle': 'MyApp',
  ///     'connectionType': 'wireless',
  ///     'memoryUsage': '45.2'
  ///   }
  /// ]
  /// ```
  static Future<List<Map<String, String>>> getScrcpyProcesses() async {
    try {
      String command;
      if (Platform.isWindows) {
        command = 'tasklist | findstr /I scrcpy.exe';
      } else if (Platform.isLinux || Platform.isMacOS) {
        command = 'ps aux | grep -w scrcpy | grep -v grep';
      } else {
        return [];
      }

      final result = await runCommand(command);
      if (result.isEmpty) return [];

      final List<Map<String, String>> processes = [];

      if (Platform.isWindows) {
        final lines = result.split('\n');

        for (var line in lines) {
          if (line.trim().isEmpty) continue;

          final parts = line.trim().split(RegExp(r'\s+'));

          if (parts.length >= 2) {
            final name = parts[0].trim();
            final pid = parts[1].trim();

            // Only include if it's actually scrcpy (not flutter app)
            if (name.toLowerCase().startsWith('scrcpy')) {
              // Get detailed info for this process
              final details = await _getProcessDetails(pid);

              processes.add({
                'pid': pid,
                'name': name,
                ...details,
              });
            }
          }
        }
      } else {
        final lines = result.split('\n');
        for (var line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final pid = parts[1];
            final details = await _getProcessDetails(pid);

            processes.add({
              'pid': pid,
              'name': 'scrcpy',
              ...details,
            });
          }
        }
      }

      return processes;
    } catch (e) {
      return [];
    }
  }

  /// Get detailed information about a process
  ///
  /// Retrieves comprehensive process information by PID.
  /// Uses platform-specific tools (WMIC on Windows, ps on Unix).
  ///
  /// [pid] Process ID to query
  ///
  /// Returns a map with process details (may be empty if process not accessible)
  static Future<Map<String, String>> _getProcessDetails(String pid) async {
    final details = <String, String>{};

    try {
      if (Platform.isWindows) {
        // Get full command line using WMIC
        final cmdResult = await runCommand(
          'wmic process where processid=$pid get commandline /format:list'
        );

        if (cmdResult.isNotEmpty) {
          final cmdLine = cmdResult.split('\n')
              .firstWhere(
                (line) => line.startsWith('CommandLine='),
                orElse: () => '',
              )
              .replaceFirst('CommandLine=', '')
              .trim();

          if (cmdLine.isNotEmpty) {
            details['fullCommand'] = cmdLine;

            // Parse device ID from command (supports both -s and --serial)
            final deviceMatch = RegExp(r'(?:-s\s+|--serial[=\s]+)([^\s]+)').firstMatch(cmdLine);
            if (deviceMatch != null) {
              details['deviceId'] = deviceMatch.group(1)!;
            }

            // Parse window title (supports both quoted and unquoted values)
            final titleMatch = RegExp(r'--window-title[=\s]+(?:"([^"]+)"|([^\s]+))')
                .firstMatch(cmdLine);
            if (titleMatch != null) {
              details['windowTitle'] = titleMatch.group(1) ?? titleMatch.group(2) ?? '';
            }

            // Determine connection type (IP address pattern = wireless)
            if (details['deviceId']?.contains(':') ?? false) {
              details['connectionType'] = 'wireless';
            } else if (details['deviceId'] != null) {
              details['connectionType'] = 'usb';
            }
          }
        }

        // Get process start time using WMIC
        final timeResult = await runCommand(
          'wmic process where processid=$pid get creationdate /format:list'
        );

        if (timeResult.isNotEmpty) {
          final creationDate = timeResult.split('\n')
              .firstWhere(
                (line) => line.startsWith('CreationDate='),
                orElse: () => '',
              )
              .replaceFirst('CreationDate=', '')
              .trim();

          if (creationDate.isNotEmpty && creationDate.length >= 14) {
            // Format: YYYYMMDDHHMMSS.mmmmmm+TZN
            details['startTime'] = creationDate;
          }
        }

        // Get CPU and memory usage
        final perfResult = await runCommand(
          'wmic process where processid=$pid get workingsetsize /format:list'
        );

        if (perfResult.isNotEmpty) {
          final memBytes = perfResult.split('\n')
              .firstWhere(
                (line) => line.startsWith('WorkingSetSize='),
                orElse: () => '',
              )
              .replaceFirst('WorkingSetSize=', '')
              .trim();

          if (memBytes.isNotEmpty) {
            final memMB = (int.tryParse(memBytes) ?? 0) / (1024 * 1024);
            details['memoryUsage'] = memMB.toStringAsFixed(1);
          }
        }
      } else {
        // Linux/macOS: use ps to get command line and details
        final psResult = await runCommand('ps -p $pid -o command=,lstart=,rss=');

        if (psResult.isNotEmpty) {
          final lines = psResult.split('\n');
          if (lines.isNotEmpty) {
            final fullCmd = lines.first;
            details['fullCommand'] = fullCmd;

            // Parse similar patterns as Windows (supports both -s and --serial)
            final deviceMatch = RegExp(r'(?:-s\s+|--serial[=\s]+)([^\s]+)').firstMatch(fullCmd);
            if (deviceMatch != null) {
              details['deviceId'] = deviceMatch.group(1)!;
            }

            final titleMatch = RegExp(r'--window-title[=\s]+(?:"([^"]+)"|([^\s]+))')
                .firstMatch(fullCmd);
            if (titleMatch != null) {
              details['windowTitle'] = titleMatch.group(1) ?? titleMatch.group(2) ?? '';
            }

            if (details['deviceId']?.contains(':') ?? false) {
              details['connectionType'] = 'wireless';
            } else if (details['deviceId'] != null) {
              details['connectionType'] = 'usb';
            }
          }
        }
      }
    } catch (_) {
      // Silently fail
    }

    return details;
  }


  /// Kill a process by PID
  ///
  /// Terminates a process gracefully if tracked, or forcefully using system commands.
  ///
  /// [pid] Process ID to terminate
  ///
  /// Behavior:
  /// 1. If process is in [_runningProcesses], sends SIGTERM and removes from tracking
  /// 2. Otherwise, uses platform-specific kill command:
  ///    - Windows: `taskkill /PID [pid] /F`
  ///    - Unix: `kill [pid]`
  static Future<void> killProcess(int pid) async {
    try {
      // First check if it's in our tracked processes
      final process = _runningProcesses[pid];
      if (process != null) {
        process.kill(ProcessSignal.sigterm);
        _runningProcesses.remove(pid);
        return;
      }

      // Otherwise, kill it using system command
      if (Platform.isWindows) {
        await runCommand('taskkill /PID $pid /F');
      } else {
        await runCommand('kill $pid');
      }
    } catch (e) {
      stderr.writeln('Error killing process $pid: $e');
    }
  }

  /// Check if a process is running
  ///
  /// [pid] Process ID to check
  ///
  /// Returns true if the process is tracked in [_runningProcesses]
  /// Note: This only tracks processes started through this app
  static bool isRunning(int pid) => _runningProcesses.containsKey(pid);

  /// Checks if a command exists on Linux
  ///
  /// [cmd] Command name to check (e.g., 'gnome-terminal')
  ///
  /// Returns true if the command is available in PATH
  static Future<bool> _isCommandAvailable(String cmd) async {
    try {
      final result = await Process.run('which', [cmd]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Returns a list of connected device IDs via adb
  ///
  /// Executes `adb devices` and parses the output to extract device IDs.
  /// Works with both USB and wireless (IP:port) connections.
  ///
  /// Returns a list of device IDs (e.g., ['abc123', '192.168.1.100:5555'])
  ///
  /// Example:
  /// ```dart
  /// final devices = await TerminalService.adbDevices();
  /// // ['emulator-5554', '192.168.1.50:5555']
  /// ```
  static Future<List<String>> adbDevices() async {
    final output = await runCommand(adbDevicesCmd);
    final lines = output.split('\n');
    return lines
        .skip(1)
        .map((l) => l.split('\t').first.trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Lists installed packages on a device
  ///
  /// Executes `adb shell pm list packages` to retrieve installed apps.
  ///
  /// [deviceId] Target device ID
  /// [includeSystemApps] If false (default), only shows user-installed apps (uses -3 flag)
  ///
  /// Returns a list of package names (e.g., ['com.example.app', 'com.android.chrome'])
  ///
  /// Example:
  /// ```dart
  /// final packages = await TerminalService.listPackages(
  ///   deviceId: 'abc123',
  ///   includeSystemApps: false,
  /// );
  /// ```
  static Future<List<String>> listPackages({
    required String deviceId,
    bool includeSystemApps = false,
  }) async {
    var cmd = 'adb -s $deviceId shell pm list packages';
    if (!includeSystemApps) cmd += ' -3';
    final result = await runCommand(cmd);
    return result
        .split('\n')
        .map((line) => line.replaceAll('package:', '').trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Get the display label for a specific package
  ///
  /// Uses a hybrid approach:
  /// 1. Checks common package names dictionary (fast, from constants file)
  /// 2. Falls back to showing the complete package name
  ///
  /// [deviceId] Target device ID (not used in current implementation)
  /// [packageName] Package name to query (e.g., 'com.android.chrome')
  ///
  /// Returns the app's display name or full package name if not recognized
  ///
  /// Example:
  /// ```dart
  /// final label = await TerminalService.getPackageLabel('abc123', 'com.android.chrome');
  /// // Returns: 'Chrome' (from dictionary)
  ///
  /// final label2 = await TerminalService.getPackageLabel('abc123', 'com.unknown.app');
  /// // Returns: 'com.unknown.app' (fallback to full package name)
  /// ```
  static Future<String> getPackageLabel(
    String deviceId,
    String packageName,
  ) async {
    // Check common packages first
    if (commonPackageNames.containsKey(packageName)) {
      return commonPackageNames[packageName]!;
    }

    // Fallback: Return full package name
    return packageName;
  }

  /// Lists installed packages with their display labels
  ///
  /// Retrieves both package names and user-facing app names.
  /// This is slower than [listPackages] as it queries each package individually.
  ///
  /// [deviceId] Target device ID
  /// [includeSystemApps] If false (default), only shows user-installed apps
  ///
  /// Returns a map of package name to display label
  ///
  /// Example:
  /// ```dart
  /// final packages = await TerminalService.listPackagesWithLabels('abc123');
  /// // {'com.android.chrome': 'Chrome', 'com.whatsapp': 'WhatsApp'}
  /// ```
  static Future<Map<String, String>> listPackagesWithLabels({
    required String deviceId,
    bool includeSystemApps = false,
  }) async {
    final packages = await listPackages(
      deviceId: deviceId,
      includeSystemApps: includeSystemApps,
    );

    final Map<String, String> packageLabels = {};

    for (var package in packages) {
      final label = await getPackageLabel(deviceId, package);
      packageLabels[package] = label;
    }

    return packageLabels;
  }

  /// Loads scrcpy encoders once for a device
  ///
  /// Executes `scrcpy --list-encoders -s [deviceId]` to retrieve available
  /// video and audio codecs/encoders for the device.
  ///
  /// [deviceId] Target device ID
  ///
  /// Returns raw scrcpy encoder output containing video and audio encoder lists
  ///
  /// Note: Output should be parsed using [parseVideoEncoders] and [parseAudioEncoders]
  static Future<String> loadScrcpyEncoders({required String deviceId}) async {
    stdout.writeln('Executing: $scrcpyCodecCmd -s $deviceId');
    return await runCommand('$scrcpyCodecCmd -s $deviceId');
  }

  /// Extracts video encoders from scrcpy output
  ///
  /// Parses the output of `scrcpy --list-encoders` to extract video codec options.
  /// Filters for lines starting with '--' and containing 'video'.
  ///
  /// [scrcpyOutput] Raw output from [loadScrcpyEncoders]
  ///
  /// Returns a list of video encoder command flags (e.g., ['--video-codec=h264', '--video-codec=h265'])
  ///
  /// Example:
  /// ```dart
  /// final encoders = TerminalService.parseVideoEncoders(rawOutput);
  /// // ['--video-codec=h264', '--video-encoder=OMX.qcom.video.encoder.avc']
  /// ```
  static List<String> parseVideoEncoders(String scrcpyOutput) {
    final lines = scrcpyOutput.split('\n');
    return lines
        .map((l) => l.trim())
        .where((l) => l.startsWith('--') && l.toLowerCase().contains('video'))
        .map((l) {
          final index = l.indexOf('(');
          final cleanLine = (index != -1 ? l.substring(0, index) : l).trim();
          return cleanLine.replaceAll(RegExp(r'\s+'), ' ');
        })
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// Extracts audio encoders from scrcpy output
  ///
  /// Parses the output of `scrcpy --list-encoders` to extract audio codec options.
  /// Filters for lines starting with '--' and containing 'audio'.
  ///
  /// [scrcpyOutput] Raw output from [loadScrcpyEncoders]
  ///
  /// Returns a list of audio encoder command flags (e.g., ['--audio-codec=aac', '--audio-codec=opus'])
  static List<String> parseAudioEncoders(String scrcpyOutput) {
    final lines = scrcpyOutput.split('\n');
    return lines
        .map((l) => l.trim())
        .where((l) => l.startsWith('--') && l.toLowerCase().contains('audio'))
        .map((l) {
          final index = l.indexOf('(');
          final cleanLine = (index != -1 ? l.substring(0, index) : l).trim();
          return cleanLine.replaceAll(RegExp(r'\s+'), ' ');
        })
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// Enable TCP/IP mode on a device
  ///
  /// Switches the device from USB-only to TCP/IP mode, allowing wireless ADB connections.
  /// Device must be connected via USB when this command is executed.
  ///
  /// [deviceId] Target device ID (USB connection)
  /// [port] TCP/IP port to use (typically 5555)
  ///
  /// Returns the command output (typically "restarting in TCP mode port: [port]")
  ///
  /// Example:
  /// ```dart
  /// await TerminalService.enableTcpip('abc123', 5555);
  /// ```
  static Future<String> enableTcpip(String deviceId, int port) async {
    final command = 'adb -s $deviceId tcpip $port';
    return await runCommand(command);
  }

  /// Get device IP address from wlan0 interface
  ///
  /// Retrieves the device's WiFi IP address by querying the wlan0 network interface.
  /// Uses multiple fallback strategies for maximum compatibility:
  /// 1. Preferred: `ip -f inet addr show wlan0` (IPv4 only, most reliable)
  /// 2. Fallback 1: `ip addr show wlan0` (original method)
  /// 3. Fallback 2: Try wlan1 interface
  /// 4. Fallback 3: Try other common interfaces (wlan2, wlan3)
  ///
  /// [deviceId] Target device ID
  ///
  /// Returns the IP address (e.g., '192.168.1.100') or null if not found or device not on WiFi
  ///
  /// Example:
  /// ```dart
  /// final ip = await TerminalService.getDeviceIpAddress('abc123');
  /// // '192.168.1.100'
  /// ```
  static Future<String?> getDeviceIpAddress(String deviceId) async {
    // Parse IP address from output (looking for inet xxx.xxx.xxx.xxx)
    final ipRegex = RegExp(r'inet\s+(\d+\.\d+\.\d+\.\d+)');

    // Strategy 1: Preferred method with -f inet flag for IPv4 only
    var result = await runCommand('adb -s $deviceId shell ip -f inet addr show wlan0');
    var ipMatch = ipRegex.firstMatch(result);
    if (ipMatch != null) return ipMatch.group(1);

    // Strategy 2: Fallback to original method without -f flag
    result = await runCommand('adb -s $deviceId shell ip addr show wlan0');
    ipMatch = ipRegex.firstMatch(result);
    if (ipMatch != null) return ipMatch.group(1);

    // Strategy 3: Try other common wireless interface names
    final interfaces = ['wlan1', 'wlan2', 'wlan3'];
    for (var iface in interfaces) {
      // Try with -f inet first
      result = await runCommand('adb -s $deviceId shell ip -f inet addr show $iface');
      ipMatch = ipRegex.firstMatch(result);
      if (ipMatch != null) return ipMatch.group(1);

      // Try without -f inet
      result = await runCommand('adb -s $deviceId shell ip addr show $iface');
      ipMatch = ipRegex.firstMatch(result);
      if (ipMatch != null) return ipMatch.group(1);
    }

    // Strategy 4: Try using ifconfig instead of ip command
    result = await runCommand('adb -s $deviceId shell ifconfig wlan0');
    final ifconfigRegex = RegExp(r'inet addr:(\d+\.\d+\.\d+\.\d+)');
    ipMatch = ifconfigRegex.firstMatch(result);
    if (ipMatch != null) return ipMatch.group(1);

    // Strategy 5: Try dumpsys wifi (Android-specific)
    result = await runCommand('adb -s $deviceId shell dumpsys wifi');
    final lines = result.split('\n');
    final wifiInfoLine = lines.firstWhere(
      (line) => line.contains('mWifiInfo'),
      orElse: () => '',
    );

    final dumpsysRegex = RegExp(r'(?:ip[=:\s]+|")(\d+\.\d+\.\d+\.\d+)');
    ipMatch = dumpsysRegex.firstMatch(wifiInfoLine);
    if (ipMatch != null) {
      final foundIp = ipMatch.group(1)!;
      if (foundIp != '0.0.0.0') return foundIp;
    }

    // Strategy 6: Try getprop command
    result = await runCommand('adb -s $deviceId shell getprop dhcp.wlan0.ipaddress');
    ipMatch = ipRegex.firstMatch(result);
    if (ipMatch != null) return ipMatch.group(1);

    return null;
  }

  /// Connect to a device via TCP/IP
  ///
  /// Establishes a wireless ADB connection to a device.
  /// Device must be in TCP/IP mode (via [enableTcpip]) before connecting.
  ///
  /// [ipAddress] Device IP address
  /// [port] TCP/IP port (typically 5555)
  ///
  /// Returns the connection result (e.g., "connected to 192.168.1.100:5555")
  ///
  /// Example:
  /// ```dart
  /// await TerminalService.connectWireless('192.168.1.100', 5555);
  /// ```
  static Future<String> connectWireless(String ipAddress, int port) async {
    final command = 'adb connect $ipAddress:$port';
    return await runCommand(command);
  }

  /// Disconnect from a wireless device
  ///
  /// Disconnects from a wireless ADB connection and optionally switches back to USB mode.
  /// Uses a two-step process for clean disconnection:
  /// 1. Switch device back to USB mode (if switchToUsb is true)
  /// 2. Disconnect the wireless connection
  ///
  /// [deviceId] Wireless device ID (format: IP:port, e.g., '192.168.1.100:5555')
  /// [switchToUsb] If true, switches device back to USB mode before disconnecting (default: true)
  ///
  /// Returns a map with:
  /// - 'success' (bool): Whether the disconnection succeeded
  /// - 'message' (String): Disconnection message
  ///
  /// Example:
  /// ```dart
  /// final result = await TerminalService.disconnectWireless('192.168.1.100:5555');
  /// if (result['success']) {
  ///   print('Disconnected successfully');
  /// }
  /// ```
  static Future<Map<String, dynamic>> disconnectWireless(
    String deviceId, {
    bool switchToUsb = true,
  }) async {
    try {
      // Step 1: Switch back to USB mode if requested
      if (switchToUsb) {
        await runCommand('adb -s $deviceId usb');
      }

      // Step 2: Disconnect the wireless connection
      final disconnectResult = await runCommand('adb disconnect $deviceId');

      if (disconnectResult.contains('disconnected') ||
          disconnectResult.isEmpty) {
        return {
          'success': true,
          'message': 'Successfully disconnected from $deviceId',
        };
      } else {
        return {
          'success': true,
          'message': disconnectResult,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error disconnecting: $e',
      };
    }
  }

  /// Complete wireless connection setup for a device (Auto Mode)
  ///
  /// Performs the full workflow to establish a wireless ADB connection:
  /// 1. Enables TCP/IP mode on the device
  /// 2. Retrieves the device's WiFi IP address automatically
  /// 3. Waits for TCP/IP initialization (1.5 seconds)
  /// 4. Connects to the device wirelessly
  ///
  /// [deviceId] Target device ID (must be connected via USB initially)
  /// [port] TCP/IP port to use (typically 5555)
  ///
  /// Returns a map with:
  /// - 'success' (bool): Whether the setup succeeded
  /// - 'message' (String): Success or error message
  /// - 'ipAddress' (String, optional): Device IP if successful
  ///
  /// Example:
  /// ```dart
  /// final result = await TerminalService.setupWirelessConnection('abc123', 5555);
  /// if (result['success']) {
  ///   print('Connected to ${result['ipAddress']}');
  /// } else {
  ///   print('Error: ${result['message']}');
  /// }
  /// ```
  static Future<Map<String, dynamic>> setupWirelessConnection(
    String deviceId,
    int port,
  ) async {
    // Step 1: Get device IP address BEFORE enabling TCP/IP
    // (Important: device disconnects after tcpip command on some devices)
    final ipAddress = await getDeviceIpAddress(deviceId);

    if (ipAddress == null) {
      return {
        'success': false,
        'message':
            'Could not determine device IP address. Make sure device is connected to WiFi.',
      };
    }

    // Step 2: Enable TCP/IP on the device
    final tcpipResult = await enableTcpip(deviceId, port);

    if (tcpipResult.isEmpty || tcpipResult.toLowerCase().contains('error')) {
      return {
        'success': false,
        'message': 'Failed to enable TCP/IP mode: $tcpipResult',
      };
    }

    // Step 3: Wait for TCP/IP to initialize
    await Future.delayed(const Duration(milliseconds: 1500));

    // Step 4: Connect to the device wirelessly
    final connectResult = await connectWireless(ipAddress, port);

    if (connectResult.contains('connected') ||
        connectResult.contains('already connected')) {
      return {
        'success': true,
        'message': 'Successfully connected to $ipAddress:$port',
        'ipAddress': ipAddress,
      };
    } else {
      return {
        'success': false,
        'message': 'Connection failed: $connectResult',
      };
    }
  }

  /// Manual wireless connection setup (Manual Mode)
  ///
  /// Connects to a device using a manually provided IP address.
  /// User must provide the device's IP address directly instead of auto-detection.
  ///
  /// Workflow:
  /// 1. Enables TCP/IP mode on the USB-connected device
  /// 2. Waits for initialization
  /// 3. Connects using the provided IP address
  ///
  /// [deviceId] Target device ID (must be connected via USB initially)
  /// [ipAddress] Manual IP address (e.g., '192.168.1.100')
  /// [port] TCP/IP port to use (typically 5555)
  ///
  /// Returns a map with:
  /// - 'success' (bool): Whether the setup succeeded
  /// - 'message' (String): Success or error message
  /// - 'ipAddress' (String): The IP address used
  ///
  /// Example:
  /// ```dart
  /// final result = await TerminalService.setupWirelessConnectionManual(
  ///   'abc123',
  ///   '192.168.1.100',
  ///   5555,
  /// );
  /// ```
  static Future<Map<String, dynamic>> setupWirelessConnectionManual(
    String deviceId,
    String ipAddress,
    int port,
  ) async {
    // Validate IP address format
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ipAddress)) {
      return {
        'success': false,
        'message': 'Invalid IP address format: $ipAddress',
      };
    }

    // Step 1: Enable TCP/IP on the device
    final tcpipResult = await enableTcpip(deviceId, port);

    if (tcpipResult.isEmpty || tcpipResult.toLowerCase().contains('error')) {
      return {
        'success': false,
        'message': 'Failed to enable TCP/IP mode: $tcpipResult',
      };
    }

    // Wait a moment for TCP/IP to initialize
    await Future.delayed(const Duration(milliseconds: 1500));

    // Step 2: Connect to the device wirelessly using manual IP
    final connectResult = await connectWireless(ipAddress, port);

    if (connectResult.contains('connected') ||
        connectResult.contains('already connected')) {
      return {
        'success': true,
        'message': 'Successfully connected to $ipAddress:$port',
        'ipAddress': ipAddress,
      };
    } else {
      return {
        'success': false,
        'message': 'Connection failed: $connectResult',
      };
    }
  }
}
