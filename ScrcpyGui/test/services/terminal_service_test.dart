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
}
