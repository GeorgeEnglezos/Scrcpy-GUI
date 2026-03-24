import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/services/windows_shortcut_service.dart';

void main() {
  group('WindowsShortcutService.buildShortcutScript', () {
    test('resolves Desktop via Shell API, not USERPROFILE', () {
      final script = WindowsShortcutService.buildShortcutScript(
        safeName: 'MyApp',
        target: 'scrcpy',
        args: '--serial=abc',
      );

      expect(
        script,
        contains('[Environment]::GetFolderPath("Desktop")'),
        reason: 'Must use Shell API so relocated Desktop folders are handled correctly',
      );
      expect(
        script,
        isNot(contains('USERPROFILE')),
        reason: 'Must not hardcode USERPROFILE\\Desktop',
      );
    });

    test('uses Join-Path to build the .lnk path', () {
      final script = WindowsShortcutService.buildShortcutScript(
        safeName: 'MyApp',
        target: 'scrcpy',
        args: '',
      );

      expect(script, contains('Join-Path'));
      expect(script, contains('MyApp.lnk'));
    });

    test('sets TargetPath and Arguments', () {
      final script = WindowsShortcutService.buildShortcutScript(
        safeName: 'MyApp',
        target: r'C:\tools\scrcpy.exe',
        args: '--serial=emulator-5554 --start-app=com.example',
      );

      expect(script, contains(r'C:\tools\scrcpy.exe'));
      expect(script, contains('--serial=emulator-5554 --start-app=com.example'));
    });

    test('omits IconLocation when icoPath is null', () {
      final script = WindowsShortcutService.buildShortcutScript(
        safeName: 'MyApp',
        target: 'scrcpy',
        args: '',
        icoPath: null,
      );

      expect(script, isNot(contains('IconLocation')));
    });

    test('includes IconLocation when icoPath is provided', () {
      final script = WindowsShortcutService.buildShortcutScript(
        safeName: 'MyApp',
        target: 'scrcpy',
        args: '',
        icoPath: r'C:\Users\user\AppData\Roaming\ScrcpyGui\shortcuts\com.example.ico',
      );

      expect(script, contains('IconLocation'));
      expect(script, contains(r'C:\Users\user\AppData\Roaming\ScrcpyGui\shortcuts\com.example.ico'));
    });

    test('escapes single quotes in safeName', () {
      final script = WindowsShortcutService.buildShortcutScript(
        safeName: "O'Brien's App",
        target: 'scrcpy',
        args: '',
      );

      // PowerShell escapes single quotes by doubling them
      expect(script, contains("O''Brien''s App.lnk"));
    });

    test('escapes single quotes in args', () {
      final script = WindowsShortcutService.buildShortcutScript(
        safeName: 'MyApp',
        target: 'scrcpy',
        args: "--title='My Device'",
      );

      expect(script, contains("--title=''My Device''"));
    });

    test('calls \$lnk.Save()', () {
      final script = WindowsShortcutService.buildShortcutScript(
        safeName: 'MyApp',
        target: 'scrcpy',
        args: '',
      );

      expect(script, contains(r'$lnk.Save()'));
    });
  });
}
