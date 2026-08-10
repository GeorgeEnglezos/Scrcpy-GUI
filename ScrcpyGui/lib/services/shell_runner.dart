/// Shell Runner
///
/// Single owner of process spawning: argv execution (the default), shell
/// *string* execution (only where a string is inherent), new-terminal
/// launches, and Flatpak host routing. No Flutter imports; UI feedback
/// belongs to the widget layer.
library;

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';

import 'log_service.dart';

class ShellRunner {
  /// Bin directories prepended to PATH on Unix, because GUI-launched apps
  /// (macOS especially) don't inherit the login-shell PATH. Covers Homebrew
  /// (Apple Silicon and Intel) and MacPorts for scrcpy/adb, plus the Android
  /// SDK platform-tools directory that Android Studio installs adb into.
  static List<String> get _unixExtraBins {
    final home = Platform.environment['HOME'];
    final androidTools = home == null || home.isEmpty
        ? null
        : Platform.isMacOS
            ? '$home/Library/Android/sdk/platform-tools'
            : Platform.isLinux
                ? '$home/Android/Sdk/platform-tools'
                : null;
    return [
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/opt/local/bin',
      if (androidTools != null) androidTools,
    ];
  }

  /// Environment for Unix child processes with the package-manager and common
  /// system bin directories prepended to PATH.
  static Map<String, String> get _unixEnv => {
        ...Platform.environment,
        'PATH':
            '${_unixExtraBins.join(':')}:/usr/bin:/bin:/usr/sbin:/sbin:${Platform.environment['PATH'] ?? ''}',
      };

  static bool get _canSpawnHostProcesses =>
      Platform.isLinux && File('/.flatpak-info').existsSync();

  static String _shellQuote(String value) =>
      "'${value.replaceAll("'", "'\"'\"'")}'";

  /// Track running processes started through the app
  ///
  /// Maps process ID to Process object for lifecycle management
  static final Map<int, Process> _runningProcesses = {};

  /// Sends SIGTERM to a process this app started, if tracked.
  /// Returns true when the pid was tracked (and is now removed).
  static bool killTrackedProcess(int pid) {
    final process = _runningProcesses.remove(pid);
    if (process == null) return false;
    process.kill(ProcessSignal.sigterm);
    return true;
  }

  /// Default execution primitive: runs [exe] with an explicit argument list.
  ///
  /// No shell, no re-parsing, no quoting; stderr and exit code are always
  /// available in the result. Owns Flatpak host routing and the Unix PATH
  /// fix, so callers never assemble either themselves.
  static Future<ProcessResult> run(
    String exe,
    List<String> args, {
    Duration? timeout,
  }) {
    final future = _canSpawnHostProcesses
        ? Process.run('flatpak-spawn', ['--host', exe, ...args])
        : Process.run(
            exe,
            args,
            environment: Platform.isWindows ? null : _unixEnv,
          );
    // ponytail: timeout abandons the await but leaves a hung child running
    // (killing it would need Process.start); fine for the stuck-adb case.
    return timeout == null ? future : future.timeout(timeout);
  }

  /// Whether a file exists at [path], checked on the host that will run it.
  ///
  /// Under Flatpak the app's own filesystem view is limited to the granted
  /// directories, so `File(...).exists()` reports a scrcpy outside $HOME as
  /// missing even though `flatpak-spawn --host` can run it. Routing the check
  /// through the host keeps directory validation consistent with execution.
  /// Off Flatpak (Windows, macOS, plain Linux) it is a plain File check.
  static Future<bool> hostFileExists(String path) async {
    try {
      if (_canSpawnHostProcesses) {
        final result =
            await Process.run('flatpak-spawn', ['--host', 'test', '-f', path]);
        return result.exitCode == 0;
      }
      return await File(path).exists();
    } catch (e) {
      LogService.error(
        'ShellRunner/hostFileExists',
        'Existence check failed for $path: $e',
      );
      return false;
    }
  }

  /// Runs [exe] with [args] and returns trimmed stdout, or '' on any
  /// failure (logged). The argv counterpart of [runCommand].
  static Future<String> runOut(
    String exe,
    List<String> args, {
    Duration? timeout,
  }) async {
    try {
      final result = await run(exe, args, timeout: timeout);
      return result.stdout.toString().trim();
    } catch (e) {
      LogService.error('ShellRunner/runOut', 'Error running $exe: $e');
      return '';
    }
  }

  /// Runs a command string in the platform shell and returns trimmed
  /// stdout, or '' on error. Prefer [runOut] unless the string is inherent.
  static Future<String> runCommand(String command) async {
    try {
      final result = await runShell(command);
      return result.stdout.toString().trim();
    } catch (e) {
      LogService.error('ShellRunner/runCommand', 'Error running command: $e');
      return '';
    }
  }

  /// Runs a command *string* through the platform shell.
  ///
  /// Use only where a string is inherent: replaying user-facing full
  /// commands (favorites, the Home command) and Unix `ps | grep` pipelines.
  /// Everything else should use [run]; the argv primitive has no quoting
  /// rules to get wrong.
  static Future<ProcessResult> runShell(String command) async {
    if (Platform.isWindows) {
      return Process.run('cmd', ['/c', ...tokenizeCommand(command)]);
    }
    if (_canSpawnHostProcesses) {
      return Process.run('flatpak-spawn', ['--host', 'bash', '-c', command]);
    }
    return Process.run('bash', ['-c', command], environment: _unixEnv);
  }

  /// Splits a command string into argv tokens, respecting double-quoted
  /// segments so values with spaces stay together.
  ///
  /// Only needed where a command *string* meets a Windows process spawn:
  /// [runShell] and [runCommandInNewTerminal]. Argv-based callers use [run]
  /// and never tokenize.
  ///
  /// On Windows we must NOT pass the whole command as a single string to
  /// `cmd /c "<string>"`: that string is parsed twice (once by cmd, once by
  /// the target program's own argv parser) which cancels out every form of
  /// quoting and splits quoted values like `--window-title="A B"` at the
  /// space. Passing each token as a separate process argument lets Dart
  /// escape them correctly so the target receives them intact.
  ///
  /// Quoting rules:
  /// - A double quote toggles quoting; the quote characters are removed.
  /// - `\"` is a literal double quote (does not toggle).
  /// - Unquoted whitespace separates tokens; all other backslashes (e.g.
  ///   Windows paths) are preserved verbatim.
  static List<String> tokenizeCommand(String command) {
    final tokens = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;
    bool hasToken = false;
    for (int i = 0; i < command.length; i++) {
      final c = command[i];
      if (c == '\\' && i + 1 < command.length && command[i + 1] == '"') {
        sb.write('"');
        hasToken = true;
        i++;
      } else if (c == '"') {
        inQuotes = !inQuotes;
        hasToken = true;
      } else if (c == ' ' && !inQuotes) {
        if (hasToken) {
          tokens.add(sb.toString());
          sb.clear();
          hasToken = false;
        }
      } else {
        sb.write(c);
        hasToken = true;
      }
    }
    if (hasToken) tokens.add(sb.toString());
    return tokens;
  }

  /// Opens [path] in the system file manager (Windows, macOS, Linux).
  /// Throws on failure; callers decide how to surface errors.
  static Future<void> openFolder(String path) async {
    if (path.isEmpty) return;
    if (Platform.isWindows) {
      final normalized = path.replaceAll('/', '\\');
      // `start` treats its first QUOTED argument as the window title, so pass
      // an empty title and the path unquoted.
      await Process.run('cmd', [
        '/c',
        'start',
        '',
        normalized,
      ], runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  /// Runs a command in a new terminal window (cross-platform).
  ///
  /// The terminal window remains open after command execution.
  /// - Windows: `cmd /c start cmd /k <tokens>`
  /// - Linux: auto-detects an available terminal emulator
  /// - macOS: AppleScript-controlled Terminal.app
  ///
  /// Returns true when a terminal was actually launched, false when none was
  /// available (no Linux terminal emulator), the AppleScript failed, or the
  /// launch threw. Callers must branch their feedback on the result: reporting
  /// success unconditionally would tell the user a window opened when none did.
  ///
  /// The Windows and Linux launcher processes are tracked so
  /// [killTrackedProcess] can stop them. macOS is not tracked: osascript is a
  /// throwaway launcher, not the Terminal window, so there is nothing useful to
  /// kill, and its exit code is what tells us whether the window actually
  /// opened (Process.start would succeed even when Terminal Automation
  /// permission is denied, wrongly reporting success on first run).
  static Future<bool> runCommandInNewTerminal(String command) async {
    try {
      if (Platform.isMacOS) {
        final result = await Process.run(
          'osascript',
          ['-e', macTerminalDoScript(command)],
        );
        if (result.exitCode != 0) {
          LogService.warning(
            'ShellRunner/runCommandInNewTerminal',
            'osascript exited ${result.exitCode}: ${result.stderr}',
          );
          return false;
        }
        return true;
      }

      Process process;

      if (Platform.isWindows) {
        process = await Process.start('cmd', [
          '/c',
          'start',
          'cmd',
          '/k',
          ...tokenizeCommand(command),
        ]);
      } else if (Platform.isLinux) {
        final launched = await _startLinuxTerminal('$command; exec bash');
        if (launched == null) {
          LogService.warning(
            'ShellRunner/runCommandInNewTerminal',
            'No terminal emulator found to run the command.',
          );
          return false;
        }
        process = launched;
      } else {
        LogService.warning(
          'ShellRunner/runCommandInNewTerminal',
          'Unsupported platform: ${Platform.operatingSystem}',
        );
        return false;
      }

      _runningProcesses[process.pid] = process;

      process.stdout.transform(SystemEncoding().decoder).listen((data) {
        stdout.write('[PID ${process.pid}] $data');
      });
      process.stderr.transform(SystemEncoding().decoder).listen((data) {
        stderr.write('[PID ${process.pid}] $data');
      });

      unawaited(process.exitCode.then((_) {
        _runningProcesses.remove(process.pid);
      }));
      return true;
    } catch (e) {
      LogService.error(
        'ShellRunner/runCommandInNewTerminal',
        'Error opening new terminal: $e',
      );
      return false;
    }
  }

  /// Builds the `osascript -e` argument that runs [shellCommand] in a new
  /// Terminal.app window, prepending the package-manager bin dirs to PATH
  /// (GUI-launched apps don't inherit the login-shell PATH).
  ///
  /// AppleScript string metacharacters in the command are escaped, so a quoted
  /// argument like `--window-title="A B"` reaches the shell intact instead of
  /// terminating the AppleScript string at the first inner quote.
  @visibleForTesting
  static String macTerminalDoScript(String shellCommand) {
    final wrapped =
        'export PATH="${_unixExtraBins.join(':')}:\$PATH" && $shellCommand';
    final escaped = wrapped.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    return 'tell application "Terminal" to do script "$escaped"';
  }

  /// Launches a script file from disk in a new terminal window.
  ///
  /// Returns false when no Linux terminal emulator is available; throws on
  /// other failures; the caller surfaces both to the user.
  static Future<bool> runScriptFileInNewTerminal(String filePath) async {
    if (Platform.isWindows) {
      // Use backslashes so cmd.exe resolves the path correctly.
      final winPath = filePath.replaceAll('/', '\\');
      await Process.start('cmd', ['/c', 'start', 'cmd', '/k', winPath]);
      return true;
    }

    if (Platform.isMacOS) {
      await Process.run('chmod', ['+x', filePath]);

      if (filePath.endsWith('.command')) {
        await Process.start('open', [filePath]);
      } else {
        // .sh: open in Terminal via osascript. Shell-quote the path so spaces
        // survive, then let macTerminalDoScript add the PATH export and the
        // AppleScript escaping.
        await Process.start('osascript', [
          '-e',
          macTerminalDoScript(_shellQuote(filePath)),
        ]);
      }
      return true;
    }

    if (Platform.isLinux) {
      await Process.run('chmod', ['+x', filePath]);
      final quotedPath = _shellQuote(filePath);
      final launched = await _startLinuxTerminal('$quotedPath; exec bash');
      if (launched == null) {
        LogService.warning(
          'ShellRunner/runScriptFileInNewTerminal',
          'No Linux terminal emulator available for script launch',
        );
        return false;
      }
      LogService.info(
        'ShellRunner/runScriptFileInNewTerminal',
        'Linux script launched via terminal pid=${launched.pid}',
      );
    }
    return true;
  }

  static const List<String> _linuxTerminalCandidates = [
    'ptyxis',
    'gnome-terminal',
    'x-terminal-emulator',
    'konsole',
    'xfce4-terminal',
    'lxterminal',
  ];

  /// Test-only override for the terminal search list, so the "no terminal
  /// found" branch is exercisable without a real desktop. Set it to names that
  /// resolve to nothing to force [runCommandInNewTerminal] down its false path.
  @visibleForTesting
  static List<String>? debugLinuxTerminalCandidates;

  static Future<String?> _findLinuxTerminalCommand() async {
    for (final terminal
        in debugLinuxTerminalCandidates ?? _linuxTerminalCandidates) {
      if (await _isCommandAvailable(terminal)) {
        return terminal;
      }
    }
    return null;
  }

  static Future<Process?> _startLinuxTerminal(String shellCommand) async {
    LogService.debug(
      'ShellRunner/_startLinuxTerminal',
      'Starting Linux terminal. hostSpawn=$_canSpawnHostProcesses '
      'command="$shellCommand"',
    );
    final terminalCmd = await _findLinuxTerminalCommand();
    if (terminalCmd == null) {
      LogService.debug(
        'ShellRunner/_startLinuxTerminal',
        'No terminal command found for Linux launch',
      );
      return null;
    }

    final args = _linuxTerminalArgs(terminalCmd, shellCommand);
    LogService.debug(
      'ShellRunner/_startLinuxTerminal',
      'Using terminal "$terminalCmd" with args=$args',
    );
    if (_canSpawnHostProcesses) {
      final process = await Process.start('flatpak-spawn', [
        '--host',
        terminalCmd,
        ...args,
      ]);
      LogService.debug(
        'ShellRunner/_startLinuxTerminal',
        'Spawned host terminal via flatpak-spawn pid=${process.pid}',
      );
      return process;
    }
    final process = await Process.start(terminalCmd, args);
    LogService.debug(
      'ShellRunner/_startLinuxTerminal',
      'Spawned local terminal pid=${process.pid}',
    );
    return process;
  }

  static List<String> _linuxTerminalArgs(
    String terminalCmd,
    String shellCommand,
  ) {
    switch (terminalCmd) {
      case 'ptyxis':
        return [
          '--standalone',
          '--new-window',
          '--',
          'bash',
          '-lc',
          shellCommand,
        ];
      case 'gnome-terminal':
        return ['--', 'bash', '-lc', shellCommand];
      case 'konsole':
        return ['-e', 'bash', '-lc', shellCommand];
      case 'xfce4-terminal':
        return ['-x', 'bash', '-lc', shellCommand];
      case 'lxterminal':
      case 'x-terminal-emulator':
        return ['-e', 'bash', '-lc', shellCommand];
      default:
        return ['--', 'bash', '-lc', shellCommand];
    }
  }

  /// Checks if a command exists on Linux.
  static Future<bool> _isCommandAvailable(String cmd) async {
    try {
      final result = _canSpawnHostProcesses
          ? await Process.run('flatpak-spawn', ['--host', 'which', cmd])
          : await Process.run('which', [cmd]);
      LogService.debug(
        'ShellRunner/_isCommandAvailable',
        'Command lookup "$cmd" exit=${result.exitCode} '
        'stdout="${result.stdout.toString().trim()}" '
        'stderr="${result.stderr.toString().trim()}"',
      );
      return result.exitCode == 0;
    } catch (e) {
      LogService.debug(
        'ShellRunner/_isCommandAvailable',
        'Command lookup threw for "$cmd": $e',
      );
      return false;
    }
  }
}
