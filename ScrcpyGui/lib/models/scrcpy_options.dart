import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scrcpy_options.freezed.dart';
part 'scrcpy_options.g.dart';

// ---------------------------------------------------------------------------
// OptionsBundle — wraps all 10 option objects for persistence
// ---------------------------------------------------------------------------

@freezed
class OptionsBundle with _$OptionsBundle {
  const factory OptionsBundle({
    @Default(AudioOptions()) AudioOptions audioOptions,
    @Default(ScreenRecordingOptions()) ScreenRecordingOptions recordingOptions,
    @Default(VirtualDisplayOptions()) VirtualDisplayOptions virtualDisplayOptions,
    @Default(GeneralCastOptions()) GeneralCastOptions generalCastOptions,
    @Default(CameraOptions()) CameraOptions cameraOptions,
    @Default(InputControlOptions()) InputControlOptions inputControlOptions,
    @Default(DisplayWindowOptions()) DisplayWindowOptions displayWindowOptions,
    @Default(NetworkConnectionOptions()) NetworkConnectionOptions networkConnectionOptions,
    @Default(AdvancedOptions()) AdvancedOptions advancedOptions,
    @Default(OtgModeOptions()) OtgModeOptions otgModeOptions,
  }) = _OptionsBundle;

  factory OptionsBundle.fromJson(Map<String, dynamic> json) =>
      _$OptionsBundleFromJson(json);
}

// ---------------------------------------------------------------------------
// Screen Recording Options
// ---------------------------------------------------------------------------

@freezed
class ScreenRecordingOptions with _$ScreenRecordingOptions {
  const ScreenRecordingOptions._();
  const factory ScreenRecordingOptions({
    @Default('') String maxSize,
    @Default('') String bitrate,
    @Default('') String framerate,
    @Default('') String outputFormat,
    @Default('') String outputFile,
    @Default('') String recordOrientation,
    @Default('') String videoCodec,
  }) = _ScreenRecordingOptions;

  factory ScreenRecordingOptions.fromJson(Map<String, dynamic> json) =>
      _$ScreenRecordingOptionsFromJson(json);

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
}

// ---------------------------------------------------------------------------
// Virtual Display Options
// ---------------------------------------------------------------------------

@freezed
class VirtualDisplayOptions with _$VirtualDisplayOptions {
  const VirtualDisplayOptions._();
  const factory VirtualDisplayOptions({
    @Default(false) bool newDisplay,
    @Default('') String resolution,
    @Default(false) bool noVdDestroyContent,
    @Default(false) bool noVdSystemDecorations,
    @Default('') String dpi,
  }) = _VirtualDisplayOptions;

  factory VirtualDisplayOptions.fromJson(Map<String, dynamic> json) =>
      _$VirtualDisplayOptionsFromJson(json);

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
}

// ---------------------------------------------------------------------------
// Audio Options
// ---------------------------------------------------------------------------

@freezed
class AudioOptions with _$AudioOptions {
  const AudioOptions._();
  const factory AudioOptions({
    @Default('') String audioBitRate,
    @Default('') String audioBuffer,
    @Default(false) bool audioDup,
    @Default(false) bool noAudio,
    @Default('') String audioCodecOptions,
    @Default('') String audioCodecEncoderPair,
    @Default('') String audioCodec,
    @Default('') String audioSource,
  }) = _AudioOptions;

  factory AudioOptions.fromJson(Map<String, dynamic> json) =>
      _$AudioOptionsFromJson(json);

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
}

// ---------------------------------------------------------------------------
// General Cast / Display Options
// ---------------------------------------------------------------------------

@freezed
class GeneralCastOptions with _$GeneralCastOptions {
  const GeneralCastOptions._();
  const factory GeneralCastOptions({
    @Default(false) bool fullscreen,
    @Default(false) bool turnScreenOff,
    @Default('') String windowTitle,
    @Default('') String crop,
    @Default('') String extraParameters,
    @Default('') String videoOrientation,
    @Default('') String videoCodecEncoderPair,
    @Default(false) bool stayAwake,
    @Default(false) bool windowBorderless,
    @Default(false) bool windowAlwaysOnTop,
    @Default(false) bool disableScreensaver,
    @Default('') String videoBitRate,
    @Default('') String selectedPackage,
    @Default(false) bool printFps,
    @Default('') String timeLimit,
    @Default(false) bool powerOffOnClose,
  }) = _GeneralCastOptions;

  factory GeneralCastOptions.fromJson(Map<String, dynamic> json) =>
      _$GeneralCastOptionsFromJson(json);

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
}

// ---------------------------------------------------------------------------
// Camera Options
// ---------------------------------------------------------------------------

@freezed
class CameraOptions with _$CameraOptions {
  const CameraOptions._();
  const factory CameraOptions({
    @Default('') String cameraId,
    @Default('') String cameraSize,
    @Default('') String cameraFacing,
    @Default('') String cameraFps,
    @Default('') String cameraAr,
    @Default(false) bool cameraHighSpeed,
  }) = _CameraOptions;

  factory CameraOptions.fromJson(Map<String, dynamic> json) =>
      _$CameraOptionsFromJson(json);

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
}

// ---------------------------------------------------------------------------
// Input Control Options
// ---------------------------------------------------------------------------

@freezed
class InputControlOptions with _$InputControlOptions {
  const InputControlOptions._();
  const factory InputControlOptions({
    @Default(false) bool noControl,
    @Default(false) bool noMouseHover,
    @Default(false) bool forwardAllClicks,
    @Default(false) bool legacyPaste,
    @Default(false) bool noKeyRepeat,
    @Default(false) bool rawKeyEvents,
    @Default(false) bool preferText,
    @Default('') String mouseBind,
    @Default('') String keyboardMode,
    @Default('') String mouseMode,
  }) = _InputControlOptions;

  factory InputControlOptions.fromJson(Map<String, dynamic> json) =>
      _$InputControlOptionsFromJson(json);

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
}

// ---------------------------------------------------------------------------
// Display/Window Configuration Options
// ---------------------------------------------------------------------------

@freezed
class DisplayWindowOptions with _$DisplayWindowOptions {
  const DisplayWindowOptions._();
  const factory DisplayWindowOptions({
    @Default('') String windowX,
    @Default('') String windowY,
    @Default('') String windowWidth,
    @Default('') String windowHeight,
    @Default('') String rotation,
    @Default('') String displayId,
    @Default('') String displayBuffer,
    @Default('') String renderDriver,
    @Default(false) bool forceAdbForward,
  }) = _DisplayWindowOptions;

  factory DisplayWindowOptions.fromJson(Map<String, dynamic> json) =>
      _$DisplayWindowOptionsFromJson(json);

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
}

// ---------------------------------------------------------------------------
// Network/Connection Options
// ---------------------------------------------------------------------------

@freezed
class NetworkConnectionOptions with _$NetworkConnectionOptions {
  const NetworkConnectionOptions._();
  const factory NetworkConnectionOptions({
    @Default('') String tcpipPort,
    @Default(false) bool selectTcpip,
    @Default('') String tunnelHost,
    @Default('') String tunnelPort,
    @Default(false) bool noAdbForward,
  }) = _NetworkConnectionOptions;

  factory NetworkConnectionOptions.fromJson(Map<String, dynamic> json) =>
      _$NetworkConnectionOptionsFromJson(json);

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
}

// ---------------------------------------------------------------------------
// Advanced/Developer Options
// ---------------------------------------------------------------------------

@freezed
class AdvancedOptions with _$AdvancedOptions {
  const AdvancedOptions._();
  const factory AdvancedOptions({
    @Default('') String verbosity,
    @Default(false) bool noCleanup,
    @Default(false) bool noDownsizeOnError,
    @Default('') String v4l2Sink,
    @Default('') String v4l2Buffer,
  }) = _AdvancedOptions;

  factory AdvancedOptions.fromJson(Map<String, dynamic> json) =>
      _$AdvancedOptionsFromJson(json);

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
}

// ---------------------------------------------------------------------------
// OTG Mode Options
// ---------------------------------------------------------------------------

@freezed
class OtgModeOptions with _$OtgModeOptions {
  const OtgModeOptions._();
  const factory OtgModeOptions({
    @Default(false) bool otg,
    @Default(false) bool hidKeyboard,
    @Default(false) bool hidMouse,
  }) = _OtgModeOptions;

  factory OtgModeOptions.fromJson(Map<String, dynamic> json) =>
      _$OtgModeOptionsFromJson(json);

  String generateCommandPart() {
    var cmd = '';
    if (otg) cmd += ' --otg';
    if (hidKeyboard) cmd += ' --hid-keyboard';
    if (hidMouse) cmd += ' --hid-mouse';
    debugPrint('[OtgModeOptions] => $cmd');
    return cmd.trim();
  }
}
