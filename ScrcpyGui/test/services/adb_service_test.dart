import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/services/adb_service.dart';

void main() {
  group('AdbService.checkAdb', () {
    // The wizard runs this on open. Without the debugSkipProcessChecks guard
    // every widget test that pumps the wizard would spawn a real adb process,
    // which fake async cannot complete.
    test('reports a working adb without spawning a process in tests', () async {
      AdbService.debugSkipProcessChecks = true;
      addTearDown(() => AdbService.debugSkipProcessChecks = false);

      final status = await AdbService.checkAdb();

      expect(status.reachable, isTrue);
      expect(status.deviceCount, 0);
    });
  });
}
