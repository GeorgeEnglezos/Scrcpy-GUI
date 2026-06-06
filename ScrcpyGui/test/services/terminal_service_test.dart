// test/services/terminal_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/services/terminal_service.dart';

void main() {
  group('TerminalService._deriveScriptBaseName', () {
    test('returns scrcpy when no flags present', () {
      expect(
        TerminalService.deriveScriptBaseName('scrcpy --pause-on-exit=if-error'),
        equals('scrcpy'),
      );
    });

    test('returns recording when only --record flag present', () {
      expect(
        TerminalService.deriveScriptBaseName(
          'scrcpy --pause-on-exit=if-error --record=gameplay.mp4',
        ),
        equals('recording'),
      );
    });

    test('returns package name when only --start-app flag present', () {
      expect(
        TerminalService.deriveScriptBaseName(
          'scrcpy --pause-on-exit=if-error --start-app=com.example.app',
        ),
        equals('com.example.app'),
      );
    });

    test('returns recording_package when both flags present', () {
      expect(
        TerminalService.deriveScriptBaseName(
          'scrcpy --record=gameplay.mp4 --start-app=com.example.app',
        ),
        equals('recording_com.example.app'),
      );
    });

    test('handles --start-app= with quoted value', () {
      expect(
        TerminalService.deriveScriptBaseName(
          r'scrcpy --start-app=\"com.example.app\"',
        ),
        equals('com.example.app'),
      );
    });
  });

  group('TerminalService.tokenizeCommand', () {
    test('splits a plain command on spaces', () {
      expect(
        TerminalService.tokenizeCommand('scrcpy --serial=ABC123'),
        equals(['scrcpy', '--serial=ABC123']),
      );
    });

    test('keeps a quoted value with spaces as a single token', () {
      // Regression for issue #24: window titles with spaces must survive
      // as one argv token instead of splitting at the space.
      expect(
        TerminalService.tokenizeCommand(
          'scrcpy --window-title="A14 Last" --shortcut-mod=lctrl',
        ),
        equals(['scrcpy', '--window-title=A14 Last', '--shortcut-mod=lctrl']),
      );
    });

    test('preserves backslashes in Windows paths', () {
      expect(
        TerminalService.tokenizeCommand(r'scrcpy --record="C:\vids\my clip.mp4"'),
        equals(['scrcpy', r'--record=C:\vids\my clip.mp4']),
      );
    });

    test('treats escaped quote as a literal quote, not a delimiter', () {
      expect(
        TerminalService.tokenizeCommand(r'scrcpy --window-title="A \"B\" C"'),
        equals(['scrcpy', '--window-title=A "B" C']),
      );
    });
  });
}
