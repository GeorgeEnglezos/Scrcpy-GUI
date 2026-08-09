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

  // A running process keeps the PATH it inherited at launch. WinGet installs
  // scrcpy into a directory stamped with the version number and rewrites PATH
  // to match, so an app that was already open both misses the new entry and
  // keeps a stale one pointing at the previous version's deleted folder. PATH
  // therefore cannot confirm an install the user just performed, and we look
  // on disk instead.
  group('AdbService.findScrcpyDirectory', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('winget_packages'));
    tearDown(() => root.deleteSync(recursive: true));

    String exeName() => Platform.isWindows ? 'scrcpy.exe' : 'scrcpy';

    Directory makePackage(String versionFolder) {
      final dir = Directory(p.join(
        root.path,
        'Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe',
        versionFolder,
      ));
      dir.createSync(recursive: true);
      return dir;
    }

    test('finds scrcpy in a winget package folder', () async {
      final versionDir = makePackage('scrcpy-win64-v4.1');
      File(p.join(versionDir.path, exeName())).createSync();

      expect(
        await AdbService.findScrcpyDirectory(wingetPackagesRoot: root.path),
        versionDir.path,
      );
    });

    test('returns null when no package folder holds the executable', () async {
      makePackage('scrcpy-win64-v4.1');

      expect(
        await AdbService.findScrcpyDirectory(wingetPackagesRoot: root.path),
        isNull,
      );
    });

    test('returns null when the packages root does not exist', () async {
      expect(
        await AdbService.findScrcpyDirectory(
          wingetPackagesRoot: p.join(root.path, 'nope'),
        ),
        isNull,
      );
    });

    test('ignores unrelated packages', () async {
      final other = Directory(p.join(root.path, 'SomeoneElse.tool', 'bin'))
        ..createSync(recursive: true);
      File(p.join(other.path, exeName())).createSync();

      expect(
        await AdbService.findScrcpyDirectory(wingetPackagesRoot: root.path),
        isNull,
      );
    });
  });
}
