import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
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

  group('AdbService.hasScrcpyIn', () {
    test('is false for an empty folder, true once the executable exists',
        () async {
      final dir = Directory.systemTemp.createTempSync('adb_service_test');
      addTearDown(() => dir.deleteSync(recursive: true));

      expect(await AdbService.hasScrcpyIn(dir.path), isFalse);

      final exeName = Platform.isWindows ? 'scrcpy.exe' : 'scrcpy';
      File(p.join(dir.path, exeName)).createSync();

      expect(await AdbService.hasScrcpyIn(dir.path), isTrue);
    });
  });
}
