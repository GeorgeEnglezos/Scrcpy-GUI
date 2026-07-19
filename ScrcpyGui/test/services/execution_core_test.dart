// test/services/terminal_service_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/services/settings_service.dart';
import 'package:scrcpy_gui_prod/services/adb_service.dart';
import 'package:scrcpy_gui_prod/services/shell_runner.dart';
import 'package:scrcpy_gui_prod/utils/command_executor.dart';

void main() {
  group('CommandExecutor.deriveScriptBaseName', () {
    test('returns scrcpy when no flags present', () {
      expect(
        CommandExecutor.deriveScriptBaseName('scrcpy --pause-on-exit=if-error'),
        equals('scrcpy'),
      );
    });

    test('returns recording when only --record flag present', () {
      expect(
        CommandExecutor.deriveScriptBaseName(
          'scrcpy --pause-on-exit=if-error --record=gameplay.mp4',
        ),
        equals('recording'),
      );
    });

    test('returns package name when only --start-app flag present', () {
      expect(
        CommandExecutor.deriveScriptBaseName(
          'scrcpy --pause-on-exit=if-error --start-app=com.example.app',
        ),
        equals('com.example.app'),
      );
    });

    test('returns recording_package when both flags present', () {
      expect(
        CommandExecutor.deriveScriptBaseName(
          'scrcpy --record=gameplay.mp4 --start-app=com.example.app',
        ),
        equals('recording_com.example.app'),
      );
    });

    test('handles --start-app= with quoted value', () {
      expect(
        CommandExecutor.deriveScriptBaseName(
          r'scrcpy --start-app=\"com.example.app\"',
        ),
        equals('com.example.app'),
      );
    });

    test('handles --start-app with space-separated value', () {
      expect(
        CommandExecutor.deriveScriptBaseName(
          'scrcpy --start-app com.example.app',
        ),
        equals('com.example.app'),
      );
    });
  });

  group('ShellRunner.tokenizeCommand', () {
    test('splits a plain command on spaces', () {
      expect(
        ShellRunner.tokenizeCommand('scrcpy --serial=ABC123'),
        equals(['scrcpy', '--serial=ABC123']),
      );
    });

    test('keeps a quoted value with spaces as a single token', () {
      // Regression for issue #24: window titles with spaces must survive
      // as one argv token instead of splitting at the space.
      expect(
        ShellRunner.tokenizeCommand(
          'scrcpy --window-title="A14 Last" --shortcut-mod=lctrl',
        ),
        equals(['scrcpy', '--window-title=A14 Last', '--shortcut-mod=lctrl']),
      );
    });

    test('preserves backslashes in Windows paths', () {
      expect(
        ShellRunner.tokenizeCommand(r'scrcpy --record="C:\vids\my clip.mp4"'),
        equals(['scrcpy', r'--record=C:\vids\my clip.mp4']),
      );
    });

    test('treats escaped quote as a literal quote, not a delimiter', () {
      expect(
        ShellRunner.tokenizeCommand(r'scrcpy --window-title="A \"B\" C"'),
        equals(['scrcpy', '--window-title=A "B" C']),
      );
    });

    test('empty string yields no tokens', () {
      expect(ShellRunner.tokenizeCommand(''), isEmpty);
    });

    test('runs of spaces do not produce empty tokens', () {
      expect(ShellRunner.tokenizeCommand('a   b'), equals(['a', 'b']));
    });

    test('empty quoted pair produces an empty token', () {
      expect(ShellRunner.tokenizeCommand('a "" b'), equals(['a', '', 'b']));
    });

    test('quoted executable path with spaces stays one token', () {
      expect(
        ShellRunner.tokenizeCommand(
          r'"C:\Program Files\scrcpy\scrcpy.exe" --fullscreen',
        ),
        equals([r'C:\Program Files\scrcpy\scrcpy.exe', '--fullscreen']),
      );
    });
  });

  group('AdbService.normalizeScrcpyExecutable', () {
    tearDown(() => SettingsService.debugSetSettings(null));

    String exeFor(String dir) =>
        p.join(dir, Platform.isWindows ? 'scrcpy.exe' : 'scrcpy');

    void setDirectory(String dir) {
      SettingsService.debugSetSettings(
        AppSettings.defaultSettings().copyWith(scrcpyDirectory: dir),
      );
    }

    test('no configured directory leaves bare scrcpy untouched', () {
      SettingsService.debugSetSettings(null);
      expect(
        AdbService.normalizeScrcpyExecutable('scrcpy --fullscreen'),
        equals('scrcpy --fullscreen'),
      );
    });

    test('bare scrcpy gets the configured path', () {
      final dir = p.join('C:', 'Tools', 'scrcpy');
      setDirectory(dir);
      expect(
        AdbService.normalizeScrcpyExecutable('scrcpy --fullscreen'),
        equals('${exeFor(dir)} --fullscreen'),
      );
    });

    test('scrcpy.exe prefix is replaced too', () {
      final dir = p.join('C:', 'Tools', 'scrcpy');
      setDirectory(dir);
      expect(
        AdbService.normalizeScrcpyExecutable('scrcpy.exe --no-audio'),
        equals('${exeFor(dir)} --no-audio'),
      );
    });

    test('quoted stale full path is rewritten', () {
      final dir = p.join('C:', 'Tools', 'scrcpy');
      setDirectory(dir);
      expect(
        AdbService.normalizeScrcpyExecutable(
          r'"C:\old path\scrcpy.exe" --no-audio',
        ),
        equals('${exeFor(dir)} --no-audio'),
      );
    });

    test('unquoted stale full path is rewritten', () {
      final dir = p.join('C:', 'Tools', 'scrcpy');
      setDirectory(dir);
      expect(
        AdbService.normalizeScrcpyExecutable(
          r'C:\old\scrcpy.exe --no-audio',
        ),
        equals('${exeFor(dir)} --no-audio'),
      );
    });

    test('directory with spaces emits a quoted executable', () {
      final dir = p.join('C:', 'Program Files', 'scrcpy');
      setDirectory(dir);
      expect(
        AdbService.normalizeScrcpyExecutable('scrcpy --fullscreen'),
        equals('"${exeFor(dir)}" --fullscreen'),
      );
    });

    test('non-scrcpy commands are untouched', () {
      setDirectory(p.join('C:', 'Tools', 'scrcpy'));
      expect(
        AdbService.normalizeScrcpyExecutable('adb devices'),
        equals('adb devices'),
      );
    });
  });
}
