import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/services/update_service.dart';

void main() {
  group('UpdateService Version Comparison', () {
    test('Standard versions: 1.6.0 > 1.5.0 should be true', () {
      expect(UpdateService.isVersionGreater('1.6.0', '1.5.0'), isTrue);
    });

    test('Same versions: 1.6.0 > 1.6.0 should be false', () {
      expect(UpdateService.isVersionGreater('1.6.0', '1.6.0'), isFalse);
    });

    test('Lower versions: 1.5.0 > 1.6.0 should be false', () {
      expect(UpdateService.isVersionGreater('1.5.0', '1.6.0'), isFalse);
    });

    test('Multi-digit parts: 1.10.0 > 1.9.0 should be true', () {
      expect(UpdateService.isVersionGreater('1.10.0', '1.9.0'), isTrue);
    });

    test('Major version bump: 2.0.0 > 1.9.9 should be true', () {
      expect(UpdateService.isVersionGreater('2.0.0', '1.9.9'), isTrue);
    });

    test('Stable vs RC: 1.6.0 > 1.6.0-rc.1 should be true', () {
      expect(UpdateService.isVersionGreater('1.6.0', '1.6.0-rc.1'), isTrue);
    });

    test('Stable vs older RC: 1.6.1 > 1.6.0-rc.1 should be true', () {
      expect(UpdateService.isVersionGreater('1.6.1', '1.6.0-rc.1'), isTrue);
    });

    test('RC vs RC: 1.6.0-rc.2 > 1.6.0-rc.1 should be true', () {
      expect(UpdateService.isVersionGreater('1.6.0-rc.2', '1.6.0-rc.1'), isTrue);
    });

    test('RC vs RC (lower): 1.6.0-rc.1 > 1.6.0-rc.2 should be false', () {
      expect(UpdateService.isVersionGreater('1.6.0-rc.1', '1.6.0-rc.2'), isFalse);
    });

    test('RC vs Stable: 1.6.0-rc.1 > 1.6.0 should be false', () {
      expect(UpdateService.isVersionGreater('1.6.0-rc.1', '1.6.0'), isFalse);
    });

    test('Nightly vs Stable: 1.6.1-nightly.20260301.1 > 1.6.0 should be true', () {
      expect(UpdateService.isVersionGreater('1.6.1-nightly.20260301.1', '1.6.0'), isTrue);
    });

    test('Nightly vs older Nightly: 1.6.1-nightly.20260301.1 > 1.6.1-nightly.20260228.1 should be true', () {
      expect(UpdateService.isVersionGreater('1.6.1-nightly.20260301.1', '1.6.1-nightly.20260228.1'), isTrue);
    });

    test('Stable vs same version Nightly: 1.6.1 > 1.6.1-nightly.20260301.1 should be true', () {
      expect(UpdateService.isVersionGreater('1.6.1', '1.6.1-nightly.20260301.1'), isTrue);
    });
  });
}
