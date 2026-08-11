import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/models/scrcpy_command.dart';

void main() {
  group('ScrcpyCommand.toCliString', () {
    test('empty command produces empty string', () {
      expect(const ScrcpyCommand().toCliString(), '');
    });

    test('one representative flag per group', () {
      // Expected flag spellings taken from Official-docs (video.md, audio.md,
      // recording.md, control.md, connection.md, video.md, otg.md).
      expect(
        const ScrcpyCommand(videoOrientation: '90').toCliString(),
        '--capture-orientation=90',
      );
      expect(
        const ScrcpyCommand(audioBitRate: '128K').toCliString(),
        '--audio-bit-rate=128K',
      );
      expect(
        const ScrcpyCommand(recordOrientation: '180').toCliString(),
        '--record-orientation=180',
      );
      expect(
        const ScrcpyCommand(keyboardMode: 'uhid').toCliString(),
        '--keyboard=uhid',
      );
      expect(
        const ScrcpyCommand(rotation: '270').toCliString(),
        '--display-orientation=270',
      );
      expect(
        const ScrcpyCommand(tcpipPort: '192.168.1.5:5555').toCliString(),
        '--tcpip=192.168.1.5:5555',
      );
      expect(
        const ScrcpyCommand(verbosity: 'debug').toCliString(),
        '--verbosity=debug',
      );
      expect(const ScrcpyCommand(otg: true).toCliString(), '--otg');
      expect(
        const ScrcpyCommand(selectedPackage: 'org.videolan.vlc').toCliString(),
        '--start-app=org.videolan.vlc',
      );
    });

    test('boolean flags emit bare switches', () {
      expect(
        const ScrcpyCommand(
          fullscreen: true,
          turnScreenOff: true,
          noAudio: true,
        ).toCliString(),
        '--fullscreen --turn-screen-off --no-audio',
      );
    });

    group('camera', () {
      test('no camera fields → no --video-source', () {
        expect(const ScrcpyCommand().toCliString(), isNot(contains('camera')));
      });

      test('any camera field emits --video-source=camera first', () {
        expect(
          const ScrcpyCommand(cameraFacing: 'back').toCliString(),
          '--video-source=camera --camera-facing=back',
        );
        expect(
          const ScrcpyCommand(cameraHighSpeed: true).toCliString(),
          '--video-source=camera --camera-high-speed',
        );
      });

      test('multiple camera fields keep documented order', () {
        expect(
          const ScrcpyCommand(
            cameraFacing: 'back',
            cameraAr: '16:9',
            cameraFps: '120',
            cameraHighSpeed: true,
          ).toCliString(),
          '--video-source=camera --camera-facing=back --camera-fps=120 '
          '--camera-ar=16:9 --camera-high-speed',
        );
      });
    });

    group('--new-display forms (virtual_display.md)', () {
      test('bare', () {
        expect(
          const ScrcpyCommand(newDisplay: true).toCliString(),
          '--new-display',
        );
      });

      test('resolution only', () {
        expect(
          const ScrcpyCommand(newDisplay: true, resolution: '1920x1080')
              .toCliString(),
          '--new-display=1920x1080',
        );
      });

      test('resolution and dpi', () {
        expect(
          const ScrcpyCommand(
            newDisplay: true,
            resolution: '1920x1080',
            dpi: '420',
          ).toCliString(),
          '--new-display=1920x1080/420',
        );
      });

      test('dpi only', () {
        expect(
          const ScrcpyCommand(newDisplay: true, dpi: '240').toCliString(),
          '--new-display=/240',
        );
      });

      test('resolution/dpi ignored when newDisplay is off', () {
        expect(
          const ScrcpyCommand(resolution: '1920x1080', dpi: '240')
              .toCliString(),
          '',
        );
      });
    });

    group('--record extension handling', () {
      test('file without format emits no extension', () {
        expect(
          const ScrcpyCommand(outputFile: 'capture').toCliString(),
          '--record=capture',
        );
      });

      test('format appends extension to file', () {
        expect(
          const ScrcpyCommand(outputFile: 'capture', outputFormat: 'mkv')
              .toCliString(),
          '--record-format=mkv --record=capture.mkv',
        );
      });

      test('extension not duplicated when file already has it', () {
        expect(
          const ScrcpyCommand(outputFile: 'capture.mkv', outputFormat: 'mkv')
              .toCliString(),
          '--record-format=mkv --record=capture.mkv',
        );
      });
    });
  });

  group('ScrcpyCommand JSON round-trip', () {
    test('fully-populated command survives toJson → fromJson', () {
      // Every field set to a non-default value; a field missed in toJson,
      // fromJson, or the constructor defaults fails this test.
      const original = ScrcpyCommand(
        fullscreen: true,
        turnScreenOff: true,
        windowTitle: 'My Device',
        crop: '1224:1440:0:0',
        extraParameters: '--foo',
        videoOrientation: '90',
        videoCodecEncoderPair: '--video-codec=h265',
        stayAwake: true,
        windowBorderless: true,
        windowAlwaysOnTop: true,
        disableScreensaver: true,
        videoBitRate: '8M',
        maxFps: '60',
        maxSize: '1920',
        selectedPackage: 'org.videolan.vlc',
        printFps: true,
        timeLimit: '30',
        powerOffOnClose: true,
        audioBitRate: '128K',
        audioBuffer: '80',
        audioDup: true,
        noAudio: true,
        audioCodecOptions: 'flac-delay=50',
        audioCodecEncoderPair: '--audio-codec=opus',
        audioSource: 'playback',
        outputFormat: 'mkv',
        outputFile: 'capture',
        recordOrientation: '180',
        newDisplay: true,
        resolution: '1920x1080',
        noVdDestroyContent: true,
        noVdSystemDecorations: true,
        dpi: '420',
        cameraId: '0',
        cameraSize: '1920x1080',
        cameraFacing: 'back',
        cameraFps: '120',
        cameraAr: '16:9',
        cameraHighSpeed: true,
        noControl: true,
        noMouseHover: true,
        legacyPaste: true,
        noKeyRepeat: true,
        rawKeyEvents: true,
        preferText: true,
        mouseBind: 'bhsn',
        keyboardMode: 'uhid',
        mouseMode: 'uhid',
        windowX: '100',
        windowY: '200',
        windowWidth: '800',
        windowHeight: '600',
        rotation: '270',
        displayId: '1',
        displayBuffer: '50',
        renderDriver: 'opengl',
        forceAdbForward: true,
        tcpipPort: '5555',
        selectTcpip: true,
        tunnelHost: '192.168.1.2',
        tunnelPort: '5556',
        verbosity: 'debug',
        noCleanup: true,
        noDownsizeOnError: true,
        v4l2Sink: '/dev/video2',
        v4l2Buffer: '300',
        otg: true,
      );

      final restored = ScrcpyCommand.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
      expect(restored.toCliString(), original.toCliString());
    });

    test('empty JSON restores all defaults', () {
      final restored = ScrcpyCommand.fromJson(const {});
      expect(restored.toJson(), const ScrcpyCommand().toJson());
    });
  });
}
