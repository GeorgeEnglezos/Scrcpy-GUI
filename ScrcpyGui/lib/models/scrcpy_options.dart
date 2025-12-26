import 'package:flutter/foundation.dart';

/// Screen Recording Options
class ScreenRecordingOptions {
  String maxSize;
  String bitrate;
  String framerate;
  String outputFormat;
  String outputFile;
  String recordOrientation;
  String videoCodec;

  ScreenRecordingOptions({
    this.maxSize = '',
    this.bitrate = '',
    this.framerate = '',
    this.outputFormat = '',
    this.outputFile = '',
    this.recordOrientation = '',
    this.videoCodec = '',
  });

  ScreenRecordingOptions copyWith({
    String? maxSize,
    String? bitrate,
    String? framerate,
    String? outputFormat,
    String? outputFile,
    String? recordOrientation,
    String? videoCodec,
  }) {
    return ScreenRecordingOptions(
      maxSize: maxSize ?? this.maxSize,
      bitrate: bitrate ?? this.bitrate,
      framerate: framerate ?? this.framerate,
      outputFormat: outputFormat ?? this.outputFormat,
      outputFile: outputFile ?? this.outputFile,
      recordOrientation: recordOrientation ?? this.recordOrientation,
      videoCodec: videoCodec ?? this.videoCodec,
    );
  }

  String generateCommandPart() {
    var cmd = '';
    if (maxSize.isNotEmpty) cmd += ' --max-size=$maxSize';
    if (bitrate.isNotEmpty) cmd += ' --video-bit-rate=$bitrate';
    if (framerate.isNotEmpty) cmd += ' --max-fps=$framerate';
    if (videoCodec.isNotEmpty) cmd += ' --video-codec=$videoCodec';
    if (recordOrientation.isNotEmpty) {
      cmd += ' --record-orientation=$recordOrientation';
    }
    if (outputFormat.isNotEmpty) cmd += ' --record-format=$outputFormat';
    if (outputFile.isNotEmpty) {
      final ext = outputFormat.isNotEmpty ? '.$outputFormat' : '';
      cmd += ' --record=$outputFile$ext';
    }
    debugPrint('[ScreenRecordingOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}

/// Virtual Display Options
class VirtualDisplayOptions {
  bool newDisplay;
  String resolution;
  bool noVdDestroyContent;
  bool noVdSystemDecorations;
  String dpi;

  VirtualDisplayOptions({
    this.newDisplay = false,
    this.resolution = '',
    this.noVdDestroyContent = false,
    this.noVdSystemDecorations = false,
    this.dpi = '',
  });

  VirtualDisplayOptions copyWith({
    bool? newDisplay,
    String? resolution,
    bool? noVdDestroyContent,
    bool? noVdSystemDecorations,
    String? dpi,
  }) {
    return VirtualDisplayOptions(
      newDisplay: newDisplay ?? this.newDisplay,
      resolution: resolution ?? this.resolution,
      noVdDestroyContent: noVdDestroyContent ?? this.noVdDestroyContent,
      noVdSystemDecorations:
          noVdSystemDecorations ?? this.noVdSystemDecorations,
      dpi: dpi ?? this.dpi,
    );
  }

  String generateCommandPart() {
    var cmd = '';
    if (newDisplay) {
      cmd += ' --new-display';
      if (resolution.isNotEmpty) {
        cmd += '=$resolution';
        if (dpi.isNotEmpty) cmd += '/$dpi';
      } else if (dpi.isNotEmpty) {
        cmd += '=/$dpi';
      }
    }
    if (noVdDestroyContent) cmd += ' --no-vd-destroy-content';
    if (noVdSystemDecorations) cmd += ' --no-vd-system-decorations';
    debugPrint('[VirtualDisplayOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}

/// Audio Options
class AudioOptions {
  String audioBitRate;
  String audioBuffer;
  bool audioDup;
  bool noAudio;
  String audioCodecOptions;
  String audioCodecEncoderPair;
  String audioCodec;
  String audioSource;

  AudioOptions({
    this.audioBitRate = '',
    this.audioBuffer = '',
    this.audioDup = false,
    this.noAudio = false,
    this.audioCodecOptions = '',
    this.audioCodecEncoderPair = '',
    this.audioCodec = '',
    this.audioSource = '',
  });

  AudioOptions copyWith({
    String? audioBitRate,
    String? audioBuffer,
    bool? audioDup,
    bool? noAudio,
    String? audioCodecOptions,
    String? audioCodecEncoderPair,
    String? audioCodec,
    String? audioSource,
  }) {
    return AudioOptions(
      audioBitRate: audioBitRate ?? this.audioBitRate,
      audioBuffer: audioBuffer ?? this.audioBuffer,
      audioDup: audioDup ?? this.audioDup,
      noAudio: noAudio ?? this.noAudio,
      audioCodecOptions: audioCodecOptions ?? this.audioCodecOptions,
      audioCodecEncoderPair:
          audioCodecEncoderPair ?? this.audioCodecEncoderPair,
      audioCodec: audioCodec ?? this.audioCodec,
      audioSource: audioSource ?? this.audioSource,
    );
  }

  String generateCommandPart() {
    var cmd = '';
    if (audioBitRate.isNotEmpty) cmd += ' --audio-bit-rate=$audioBitRate';
    if (audioBuffer.isNotEmpty) cmd += ' --audio-buffer=$audioBuffer';
    if (audioSource.isNotEmpty) cmd += ' --audio-source=$audioSource';
    if (audioCodecEncoderPair.isNotEmpty) cmd += ' $audioCodecEncoderPair';
    if (audioCodecOptions.isNotEmpty) {
      cmd += ' --audio-codec-options=$audioCodecOptions';
    }
    if (audioDup) cmd += ' --audio-dup';
    if (noAudio) cmd += ' --no-audio';
    debugPrint('[AudioOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}

/// General Cast / Display Options
class GeneralCastOptions {
  bool fullscreen;
  bool turnScreenOff;
  String windowTitle;
  String crop;
  String extraParameters;
  String videoOrientation;
  String videoCodecEncoderPair;
  bool stayAwake;
  bool windowBorderless;
  bool windowAlwaysOnTop;
  bool disableScreensaver;
  String videoBitRate;
  String selectedPackage;
  bool printFps;
  String timeLimit;
  bool powerOffOnClose;

  GeneralCastOptions({
    this.fullscreen = false,
    this.turnScreenOff = false,
    this.windowTitle = '',
    this.crop = '',
    this.extraParameters = '',
    this.videoOrientation = '',
    this.videoCodecEncoderPair = '',
    this.stayAwake = false,
    this.windowBorderless = false,
    this.windowAlwaysOnTop = false,
    this.disableScreensaver = false,
    this.videoBitRate = '',
    this.selectedPackage = '',
    this.printFps = false,
    this.timeLimit = '',
    this.powerOffOnClose = false,
  });

  GeneralCastOptions copyWith({
    bool? fullscreen,
    bool? turnScreenOff,
    String? windowTitle,
    String? crop,
    String? extraParameters,
    String? videoOrientation,
    String? videoCodecEncoderPair,
    bool? stayAwake,
    bool? windowBorderless,
    bool? windowAlwaysOnTop,
    bool? disableScreensaver,
    String? videoBitRate,
    String? selectedPackage,
    bool? printFps,
    String? timeLimit,
    bool? powerOffOnClose,
  }) {
    return GeneralCastOptions(
      fullscreen: fullscreen ?? this.fullscreen,
      turnScreenOff: turnScreenOff ?? this.turnScreenOff,
      windowTitle: windowTitle ?? this.windowTitle,
      crop: crop ?? this.crop,
      extraParameters: extraParameters ?? this.extraParameters,
      videoOrientation: videoOrientation ?? this.videoOrientation,
      videoCodecEncoderPair:
          videoCodecEncoderPair ?? this.videoCodecEncoderPair,
      stayAwake: stayAwake ?? this.stayAwake,
      windowBorderless: windowBorderless ?? this.windowBorderless,
      windowAlwaysOnTop: windowAlwaysOnTop ?? this.windowAlwaysOnTop,
      disableScreensaver: disableScreensaver ?? this.disableScreensaver,
      videoBitRate: videoBitRate ?? this.videoBitRate,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      printFps: printFps ?? this.printFps,
      timeLimit: timeLimit ?? this.timeLimit,
      powerOffOnClose: powerOffOnClose ?? this.powerOffOnClose,
    );
  }

  String generateCommandPart() {
    var cmd = '';

    if (selectedPackage.isNotEmpty) cmd += ' --start-app=$selectedPackage';
    if (fullscreen) cmd += ' --fullscreen';
    if (turnScreenOff) cmd += ' --turn-screen-off';
    if (crop.isNotEmpty) cmd += ' --crop=$crop';
    if (videoOrientation.isNotEmpty) {
      cmd += ' --capture-orientation=$videoOrientation';
    }
    if (stayAwake) cmd += ' --stay-awake';
    if (videoBitRate.isNotEmpty) cmd += ' --video-bit-rate=$videoBitRate';
    if (windowBorderless) cmd += ' --window-borderless';
    if (windowAlwaysOnTop) cmd += ' --always-on-top';
    if (videoCodecEncoderPair.isNotEmpty) cmd += ' $videoCodecEncoderPair';
    if (printFps) cmd += ' --print-fps';
    if (timeLimit.isNotEmpty) cmd += ' --time-limit=$timeLimit';
    if (powerOffOnClose) cmd += ' --power-off-on-close';
    if (extraParameters.isNotEmpty) cmd += ' $extraParameters';
    if (disableScreensaver) cmd += ' --disable-screensaver';

    debugPrint('[GeneralCastOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}

/// Camera Options
class CameraOptions {
  String cameraId;
  String cameraSize;
  String cameraFacing;
  String cameraFps;
  String cameraAr;
  bool cameraHighSpeed;

  CameraOptions({
    this.cameraId = '',
    this.cameraSize = '',
    this.cameraFacing = '',
    this.cameraFps = '',
    this.cameraAr = '',
    this.cameraHighSpeed = false,
  });

  CameraOptions copyWith({
    String? cameraId,
    String? cameraSize,
    String? cameraFacing,
    String? cameraFps,
    String? cameraAr,
    bool? cameraHighSpeed,
  }) {
    return CameraOptions(
      cameraId: cameraId ?? this.cameraId,
      cameraSize: cameraSize ?? this.cameraSize,
      cameraFacing: cameraFacing ?? this.cameraFacing,
      cameraFps: cameraFps ?? this.cameraFps,
      cameraAr: cameraAr ?? this.cameraAr,
      cameraHighSpeed: cameraHighSpeed ?? this.cameraHighSpeed,
    );
  }

  String generateCommandPart() {
    var cmd = '';
    if (cameraId.isNotEmpty) cmd += ' --camera-id=$cameraId';
    if (cameraSize.isNotEmpty) cmd += ' --camera-size=$cameraSize';
    if (cameraFacing.isNotEmpty) cmd += ' --camera-facing=$cameraFacing';
    if (cameraFps.isNotEmpty) cmd += ' --camera-fps=$cameraFps';
    if (cameraAr.isNotEmpty) cmd += ' --camera-ar=$cameraAr';
    if (cameraHighSpeed) cmd += ' --camera-high-speed';
    debugPrint('[CameraOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}

/// Input Control Options
class InputControlOptions {
  bool noControl;
  bool noMouseHover;
  bool forwardAllClicks;
  bool legacyPaste;
  bool noKeyRepeat;
  bool rawKeyEvents;
  bool preferText;
  String mouseBind;
  String keyboardMode;
  String mouseMode;

  InputControlOptions({
    this.noControl = false,
    this.noMouseHover = false,
    this.forwardAllClicks = false,
    this.legacyPaste = false,
    this.noKeyRepeat = false,
    this.rawKeyEvents = false,
    this.preferText = false,
    this.mouseBind = '',
    this.keyboardMode = '',
    this.mouseMode = '',
  });

  InputControlOptions copyWith({
    bool? noControl,
    bool? noMouseHover,
    bool? forwardAllClicks,
    bool? legacyPaste,
    bool? noKeyRepeat,
    bool? rawKeyEvents,
    bool? preferText,
    String? mouseBind,
    String? keyboardMode,
    String? mouseMode,
  }) {
    return InputControlOptions(
      noControl: noControl ?? this.noControl,
      noMouseHover: noMouseHover ?? this.noMouseHover,
      forwardAllClicks: forwardAllClicks ?? this.forwardAllClicks,
      legacyPaste: legacyPaste ?? this.legacyPaste,
      noKeyRepeat: noKeyRepeat ?? this.noKeyRepeat,
      rawKeyEvents: rawKeyEvents ?? this.rawKeyEvents,
      preferText: preferText ?? this.preferText,
      mouseBind: mouseBind ?? this.mouseBind,
      keyboardMode: keyboardMode ?? this.keyboardMode,
      mouseMode: mouseMode ?? this.mouseMode,
    );
  }

  String generateCommandPart() {
    var cmd = '';
    if (keyboardMode.isNotEmpty) cmd += ' --keyboard=$keyboardMode';
    if (mouseMode.isNotEmpty) cmd += ' --mouse=$mouseMode';
    if (noControl) cmd += ' --no-control';
    if (noMouseHover) cmd += ' --no-mouse-hover';
    if (forwardAllClicks) cmd += ' --forward-all-clicks';
    if (legacyPaste) cmd += ' --legacy-paste';
    if (noKeyRepeat) cmd += ' --no-key-repeat';
    if (rawKeyEvents) cmd += ' --raw-key-events';
    if (preferText) cmd += ' --prefer-text';
    if (mouseBind.isNotEmpty) cmd += ' --mouse-bind=$mouseBind';
    debugPrint('[InputControlOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}

/// Display/Window Configuration Options
class DisplayWindowOptions {
  String windowX;
  String windowY;
  String windowWidth;
  String windowHeight;
  String rotation;
  String displayId;
  String displayBuffer;
  String renderDriver;
  bool forceAdbForward;

  DisplayWindowOptions({
    this.windowX = '',
    this.windowY = '',
    this.windowWidth = '',
    this.windowHeight = '',
    this.rotation = '',
    this.displayId = '',
    this.displayBuffer = '',
    this.renderDriver = '',
    this.forceAdbForward = false,
  });

  DisplayWindowOptions copyWith({
    String? windowX,
    String? windowY,
    String? windowWidth,
    String? windowHeight,
    String? rotation,
    String? displayId,
    String? displayBuffer,
    String? renderDriver,
    bool? forceAdbForward,
  }) {
    return DisplayWindowOptions(
      windowX: windowX ?? this.windowX,
      windowY: windowY ?? this.windowY,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      rotation: rotation ?? this.rotation,
      displayId: displayId ?? this.displayId,
      displayBuffer: displayBuffer ?? this.displayBuffer,
      renderDriver: renderDriver ?? this.renderDriver,
      forceAdbForward: forceAdbForward ?? this.forceAdbForward,
    );
  }

  String generateCommandPart() {
    var cmd = '';
    if (windowX.isNotEmpty) cmd += ' --window-x=$windowX';
    if (windowY.isNotEmpty) cmd += ' --window-y=$windowY';
    if (windowWidth.isNotEmpty) cmd += ' --window-width=$windowWidth';
    if (windowHeight.isNotEmpty) cmd += ' --window-height=$windowHeight';
    if (rotation.isNotEmpty) cmd += ' --rotation=$rotation';
    if (displayId.isNotEmpty) cmd += ' --display-id=$displayId';
    if (displayBuffer.isNotEmpty) cmd += ' --display-buffer=$displayBuffer';
    if (renderDriver.isNotEmpty) cmd += ' --render-driver=$renderDriver';
    if (forceAdbForward) cmd += ' --force-adb-forward';
    debugPrint('[DisplayWindowOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}

/// Network/Connection Options
class NetworkConnectionOptions {
  String tcpipPort;
  bool selectTcpip;
  String tunnelHost;
  String tunnelPort;
  bool noAdbForward;

  NetworkConnectionOptions({
    this.tcpipPort = '',
    this.selectTcpip = false,
    this.tunnelHost = '',
    this.tunnelPort = '',
    this.noAdbForward = false,
  });

  NetworkConnectionOptions copyWith({
    String? tcpipPort,
    bool? selectTcpip,
    String? tunnelHost,
    String? tunnelPort,
    bool? noAdbForward,
  }) {
    return NetworkConnectionOptions(
      tcpipPort: tcpipPort ?? this.tcpipPort,
      selectTcpip: selectTcpip ?? this.selectTcpip,
      tunnelHost: tunnelHost ?? this.tunnelHost,
      tunnelPort: tunnelPort ?? this.tunnelPort,
      noAdbForward: noAdbForward ?? this.noAdbForward,
    );
  }

  String generateCommandPart() {
    var cmd = '';
    if (tcpipPort.isNotEmpty) cmd += ' --tcpip=$tcpipPort';
    if (selectTcpip) cmd += ' --select-tcpip';
    if (tunnelHost.isNotEmpty) cmd += ' --tunnel-host=$tunnelHost';
    if (tunnelPort.isNotEmpty) cmd += ' --tunnel-port=$tunnelPort';
    if (noAdbForward) cmd += ' --no-adb-forward';
    debugPrint('[NetworkConnectionOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}

/// Advanced/Developer Options
class AdvancedOptions {
  String verbosity;
  bool noCleanup;
  bool noDownsizeOnError;
  String v4l2Sink;
  String v4l2Buffer;

  AdvancedOptions({
    this.verbosity = '',
    this.noCleanup = false,
    this.noDownsizeOnError = false,
    this.v4l2Sink = '',
    this.v4l2Buffer = '',
  });

  AdvancedOptions copyWith({
    String? verbosity,
    bool? noCleanup,
    bool? noDownsizeOnError,
    String? v4l2Sink,
    String? v4l2Buffer,
  }) {
    return AdvancedOptions(
      verbosity: verbosity ?? this.verbosity,
      noCleanup: noCleanup ?? this.noCleanup,
      noDownsizeOnError: noDownsizeOnError ?? this.noDownsizeOnError,
      v4l2Sink: v4l2Sink ?? this.v4l2Sink,
      v4l2Buffer: v4l2Buffer ?? this.v4l2Buffer,
    );
  }

  String generateCommandPart() {
    var cmd = '';
    if (verbosity.isNotEmpty) cmd += ' --verbosity=$verbosity';
    if (noCleanup) cmd += ' --no-cleanup';
    if (noDownsizeOnError) cmd += ' --no-downsize-on-error';
    if (v4l2Sink.isNotEmpty) cmd += ' --v4l2-sink=$v4l2Sink';
    if (v4l2Buffer.isNotEmpty) cmd += ' --v4l2-buffer=$v4l2Buffer';
    debugPrint('[AdvancedOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}

/// OTG Mode Options
class OtgModeOptions {
  bool otg;
  bool hidKeyboard;
  bool hidMouse;

  OtgModeOptions({
    this.otg = false,
    this.hidKeyboard = false,
    this.hidMouse = false,
  });

  OtgModeOptions copyWith({
    bool? otg,
    bool? hidKeyboard,
    bool? hidMouse,
  }) {
    return OtgModeOptions(
      otg: otg ?? this.otg,
      hidKeyboard: hidKeyboard ?? this.hidKeyboard,
      hidMouse: hidMouse ?? this.hidMouse,
    );
  }

  String generateCommandPart() {
    var cmd = '';
    if (otg) cmd += ' --otg';
    if (hidKeyboard) cmd += ' --hid-keyboard';
    if (hidMouse) cmd += ' --hid-mouse';
    debugPrint('[OtgModeOptions] => $cmd');
    return cmd.trim();
  }

  @override
  String toString() => generateCommandPart();
}
