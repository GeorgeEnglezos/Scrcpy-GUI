import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:scrcpy_gui_prod/services/shell_runner.dart';

void main() {
  // The macOS Terminal launcher is unverifiable on a non-Mac, so the string it
  // hands to osascript is pinned here instead. These guard the two things that
  // actually break scrcpy on macOS: a PATH that misses a package manager, and
  // an unescaped quote that ends the AppleScript string early.
  group('macTerminalDoScript', () {
    test('includes the MacPorts bin dir in the PATH export', () {
      // Lead 1 regression guard: a MacPorts scrcpy/adb lives in /opt/local/bin,
      // which a Finder-launched macOS app won't have on PATH unless we add it.
      final script = ShellRunner.macTerminalDoScript('scrcpy');
      expect(script, contains('/opt/local/bin'));
      expect(script, contains('scrcpy'));
    });

    test('wraps the command in a single Terminal do-script statement', () {
      final script = ShellRunner.macTerminalDoScript('scrcpy');
      expect(script, startsWith('tell application "Terminal" to do script "'));
      expect(script, endsWith('"'));
    });

    test('escapes inner double quotes so quoted args survive AppleScript', () {
      final script =
          ShellRunner.macTerminalDoScript('scrcpy --window-title="A B"');
      // The user's quotes must reach the shell as \" inside the AppleScript
      // literal; a bare " would terminate the do-script string.
      expect(script, contains(r'--window-title=\"A B\"'));
    });

    test('escapes backslashes before quotes', () {
      final script = ShellRunner.macTerminalDoScript(r'echo a\b');
      expect(script, contains(r'echo a\\b'));
    });
  });

  group('hostFileExists (off Flatpak, the plain File branch)', () {
    late Directory tempDir;

    setUp(() => tempDir = Directory.systemTemp.createTempSync('host_exists'));
    tearDown(() => tempDir.deleteSync(recursive: true));

    test('true for a file that exists', () async {
      final file = File(p.join(tempDir.path, 'scrcpy'))..createSync();
      expect(await ShellRunner.hostFileExists(file.path), isTrue);
    });

    test('false for a path that does not exist', () async {
      final missing = p.join(tempDir.path, 'nope', 'scrcpy');
      expect(await ShellRunner.hostFileExists(missing), isFalse);
    });
  });

  group('runCommandInNewTerminal', () {
    // The failure this guards: the launcher used to return void, so callers
    // reported "opened a terminal" even when no emulator was found. It must
    // report false instead. Only the Linux branch has a reachable no-terminal
    // path, so this runs there; the bogus candidate never resolves, so no
    // window is spawned.
    test('returns false when no terminal emulator is available', () async {
      ShellRunner.debugLinuxTerminalCandidates = [
        'scrcpygui-no-such-terminal-xyz',
      ];
      addTearDown(() => ShellRunner.debugLinuxTerminalCandidates = null);

      expect(await ShellRunner.runCommandInNewTerminal('true'), isFalse);
    }, skip: Platform.isLinux ? false : 'Linux terminal-detection branch only');
  });
}
