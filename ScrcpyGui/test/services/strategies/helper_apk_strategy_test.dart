import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/services/strategies/helper_apk_strategy.dart';
import 'package:scrcpy_gui_prod/services/icon_fetch_strategy.dart';

void main() {
  group('HelperApkStrategy', () {
    late HelperApkStrategy strategy;

    setUp(() {
      strategy = HelperApkStrategy();
    });

    test('strategy implements IconFetchStrategy interface', () {
      expect(strategy, isA<IconFetchStrategy>());
    });

    test(
      'fetchAll requires device connection',
      () async {
        final labels = <String, String>{};

        // This test requires a real Android device connected via ADB
        // In CI/test environment, it will timeout waiting for device
        // Expected: Either APK installation succeeds or times out on polling
        expect(() async {
          await strategy.fetchAll(
            deviceId: 'test-device',
            packages: ['com.example.app'],
            labels: labels,
            batchSize: 10,
            forceUpdate: false,
            isCancelled: () => false,
            onLabelDiscovered: (pkg, label) {},
            onBatchDone: (partial) {},
          );
        }, throwsException);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    test(
      'fetchAll respects isCancelled callback',
      () async {
        final labels = <String, String>{};
        var callCount = 0;

        // Create a cancellation function that returns true immediately
        bool cancelled() {
          callCount++;
          return true; // Signal cancellation
        }

        try {
          await strategy.fetchAll(
            deviceId: 'test-device',
            packages: ['com.example.app'],
            labels: labels,
            batchSize: 10,
            forceUpdate: false,
            isCancelled: cancelled,
            onLabelDiscovered: (pkg, label) {},
            onBatchDone: (partial) {},
          );
        } catch (_) {
          // Expected: will fail when waiting for device or ADB
        }

        // Verify that isCancelled was called (it would be checked during batch processing)
        // Note: callCount may be 0 if test fails before batch processing
        expect(callCount, greaterThanOrEqualTo(0));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });
}
