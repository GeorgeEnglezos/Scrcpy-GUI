class ScrcpyCommand {
  // --- GeneralCastOptions ---
  final bool fullscreen;
  final bool turnScreenOff;
  final String windowTitle;
  final String crop;
  final String extraParameters;
  final String videoOrientation;
  final String videoCodecEncoderPair;
  final bool stayAwake;
  final bool windowBorderless;
  final bool windowAlwaysOnTop;
  final bool disableScreensaver;
  final String videoBitRate;
  final String maxFps;
  final String maxSize;
  final String selectedPackage;
  final bool printFps;
  final String timeLimit;
  final bool powerOffOnClose;

  // --- AudioOptions ---
  final String audioBitRate;
  final String audioBuffer;
  final bool audioDup;
  final bool noAudio;
  final String audioCodecOptions;
  final String audioCodecEncoderPair;
  final String audioSource;

  // --- ScreenRecordingOptions ---
  final String outputFormat;
  final String outputFile;
  final String recordOrientation;

  // --- VirtualDisplayOptions ---
  final bool newDisplay;
  final String resolution;
  final bool noVdDestroyContent;
  final bool noVdSystemDecorations;
  final String dpi;

  // --- CameraOptions ---
  final String cameraId;
  final String cameraSize;
  final String cameraFacing;
  final String cameraFps;
  final String cameraAr;
  final bool cameraHighSpeed;

  // --- InputControlOptions ---
  final bool noControl;
  final bool noMouseHover;
  final bool legacyPaste;
  final bool noKeyRepeat;
  final bool rawKeyEvents;
  final bool preferText;
  final String mouseBind;
  final String keyboardMode;
  final String mouseMode;

  // --- DisplayWindowOptions ---
  final String windowX;
  final String windowY;
  final String windowWidth;
  final String windowHeight;
  final String rotation;
  final String displayId;
  final String displayBuffer;
  final String renderDriver;
  final bool forceAdbForward;

  // --- NetworkConnectionOptions ---
  final String tcpipPort;
  final bool selectTcpip;
  final String tunnelHost;
  final String tunnelPort;

  // --- AdvancedOptions ---
  final String verbosity;
  final bool noCleanup;
  final bool noDownsizeOnError;
  final String v4l2Sink;
  final String v4l2Buffer;

  // --- OtgModeOptions ---
  final bool otg;

  const ScrcpyCommand({
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
    this.maxFps = '',
    this.maxSize = '',
    this.selectedPackage = '',
    this.printFps = false,
    this.timeLimit = '',
    this.powerOffOnClose = false,
    this.audioBitRate = '',
    this.audioBuffer = '',
    this.audioDup = false,
    this.noAudio = false,
    this.audioCodecOptions = '',
    this.audioCodecEncoderPair = '',
    this.audioSource = '',
    this.outputFormat = '',
    this.outputFile = '',
    this.recordOrientation = '',
    this.newDisplay = false,
    this.resolution = '',
    this.noVdDestroyContent = false,
    this.noVdSystemDecorations = false,
    this.dpi = '',
    this.cameraId = '',
    this.cameraSize = '',
    this.cameraFacing = '',
    this.cameraFps = '',
    this.cameraAr = '',
    this.cameraHighSpeed = false,
    this.noControl = false,
    this.noMouseHover = false,
    this.legacyPaste = false,
    this.noKeyRepeat = false,
    this.rawKeyEvents = false,
    this.preferText = false,
    this.mouseBind = '',
    this.keyboardMode = '',
    this.mouseMode = '',
    this.windowX = '',
    this.windowY = '',
    this.windowWidth = '',
    this.windowHeight = '',
    this.rotation = '',
    this.displayId = '',
    this.displayBuffer = '',
    this.renderDriver = '',
    this.forceAdbForward = false,
    this.tcpipPort = '',
    this.selectTcpip = false,
    this.tunnelHost = '',
    this.tunnelPort = '',
    this.verbosity = '',
    this.noCleanup = false,
    this.noDownsizeOnError = false,
    this.v4l2Sink = '',
    this.v4l2Buffer = '',
    this.otg = false,
  });

  factory ScrcpyCommand.empty() => const ScrcpyCommand();

  ScrcpyCommand copyWith({
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
    String? maxFps,
    String? maxSize,
    String? selectedPackage,
    bool? printFps,
    String? timeLimit,
    bool? powerOffOnClose,
    String? audioBitRate,
    String? audioBuffer,
    bool? audioDup,
    bool? noAudio,
    String? audioCodecOptions,
    String? audioCodecEncoderPair,
    String? audioSource,
    String? outputFormat,
    String? outputFile,
    String? recordOrientation,
    bool? newDisplay,
    String? resolution,
    bool? noVdDestroyContent,
    bool? noVdSystemDecorations,
    String? dpi,
    String? cameraId,
    String? cameraSize,
    String? cameraFacing,
    String? cameraFps,
    String? cameraAr,
    bool? cameraHighSpeed,
    bool? noControl,
    bool? noMouseHover,
    bool? legacyPaste,
    bool? noKeyRepeat,
    bool? rawKeyEvents,
    bool? preferText,
    String? mouseBind,
    String? keyboardMode,
    String? mouseMode,
    String? windowX,
    String? windowY,
    String? windowWidth,
    String? windowHeight,
    String? rotation,
    String? displayId,
    String? displayBuffer,
    String? renderDriver,
    bool? forceAdbForward,
    String? tcpipPort,
    bool? selectTcpip,
    String? tunnelHost,
    String? tunnelPort,
    String? verbosity,
    bool? noCleanup,
    bool? noDownsizeOnError,
    String? v4l2Sink,
    String? v4l2Buffer,
    bool? otg,
  }) {
    return ScrcpyCommand(
      fullscreen: fullscreen ?? this.fullscreen,
      turnScreenOff: turnScreenOff ?? this.turnScreenOff,
      windowTitle: windowTitle ?? this.windowTitle,
      crop: crop ?? this.crop,
      extraParameters: extraParameters ?? this.extraParameters,
      videoOrientation: videoOrientation ?? this.videoOrientation,
      videoCodecEncoderPair: videoCodecEncoderPair ?? this.videoCodecEncoderPair,
      stayAwake: stayAwake ?? this.stayAwake,
      windowBorderless: windowBorderless ?? this.windowBorderless,
      windowAlwaysOnTop: windowAlwaysOnTop ?? this.windowAlwaysOnTop,
      disableScreensaver: disableScreensaver ?? this.disableScreensaver,
      videoBitRate: videoBitRate ?? this.videoBitRate,
      maxFps: maxFps ?? this.maxFps,
      maxSize: maxSize ?? this.maxSize,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      printFps: printFps ?? this.printFps,
      timeLimit: timeLimit ?? this.timeLimit,
      powerOffOnClose: powerOffOnClose ?? this.powerOffOnClose,
      audioBitRate: audioBitRate ?? this.audioBitRate,
      audioBuffer: audioBuffer ?? this.audioBuffer,
      audioDup: audioDup ?? this.audioDup,
      noAudio: noAudio ?? this.noAudio,
      audioCodecOptions: audioCodecOptions ?? this.audioCodecOptions,
      audioCodecEncoderPair: audioCodecEncoderPair ?? this.audioCodecEncoderPair,
      audioSource: audioSource ?? this.audioSource,
      outputFormat: outputFormat ?? this.outputFormat,
      outputFile: outputFile ?? this.outputFile,
      recordOrientation: recordOrientation ?? this.recordOrientation,
      newDisplay: newDisplay ?? this.newDisplay,
      resolution: resolution ?? this.resolution,
      noVdDestroyContent: noVdDestroyContent ?? this.noVdDestroyContent,
      noVdSystemDecorations: noVdSystemDecorations ?? this.noVdSystemDecorations,
      dpi: dpi ?? this.dpi,
      cameraId: cameraId ?? this.cameraId,
      cameraSize: cameraSize ?? this.cameraSize,
      cameraFacing: cameraFacing ?? this.cameraFacing,
      cameraFps: cameraFps ?? this.cameraFps,
      cameraAr: cameraAr ?? this.cameraAr,
      cameraHighSpeed: cameraHighSpeed ?? this.cameraHighSpeed,
      noControl: noControl ?? this.noControl,
      noMouseHover: noMouseHover ?? this.noMouseHover,
      legacyPaste: legacyPaste ?? this.legacyPaste,
      noKeyRepeat: noKeyRepeat ?? this.noKeyRepeat,
      rawKeyEvents: rawKeyEvents ?? this.rawKeyEvents,
      preferText: preferText ?? this.preferText,
      mouseBind: mouseBind ?? this.mouseBind,
      keyboardMode: keyboardMode ?? this.keyboardMode,
      mouseMode: mouseMode ?? this.mouseMode,
      windowX: windowX ?? this.windowX,
      windowY: windowY ?? this.windowY,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      rotation: rotation ?? this.rotation,
      displayId: displayId ?? this.displayId,
      displayBuffer: displayBuffer ?? this.displayBuffer,
      renderDriver: renderDriver ?? this.renderDriver,
      forceAdbForward: forceAdbForward ?? this.forceAdbForward,
      tcpipPort: tcpipPort ?? this.tcpipPort,
      selectTcpip: selectTcpip ?? this.selectTcpip,
      tunnelHost: tunnelHost ?? this.tunnelHost,
      tunnelPort: tunnelPort ?? this.tunnelPort,
      verbosity: verbosity ?? this.verbosity,
      noCleanup: noCleanup ?? this.noCleanup,
      noDownsizeOnError: noDownsizeOnError ?? this.noDownsizeOnError,
      v4l2Sink: v4l2Sink ?? this.v4l2Sink,
      v4l2Buffer: v4l2Buffer ?? this.v4l2Buffer,
      otg: otg ?? this.otg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullscreen': fullscreen,
      'turnScreenOff': turnScreenOff,
      'windowTitle': windowTitle,
      'crop': crop,
      'extraParameters': extraParameters,
      'videoOrientation': videoOrientation,
      'videoCodecEncoderPair': videoCodecEncoderPair,
      'stayAwake': stayAwake,
      'windowBorderless': windowBorderless,
      'windowAlwaysOnTop': windowAlwaysOnTop,
      'disableScreensaver': disableScreensaver,
      'videoBitRate': videoBitRate,
      'maxFps': maxFps,
      'maxSize': maxSize,
      'selectedPackage': selectedPackage,
      'printFps': printFps,
      'timeLimit': timeLimit,
      'powerOffOnClose': powerOffOnClose,
      'audioBitRate': audioBitRate,
      'audioBuffer': audioBuffer,
      'audioDup': audioDup,
      'noAudio': noAudio,
      'audioCodecOptions': audioCodecOptions,
      'audioCodecEncoderPair': audioCodecEncoderPair,
      'audioSource': audioSource,
      'outputFormat': outputFormat,
      'outputFile': outputFile,
      'recordOrientation': recordOrientation,
      'newDisplay': newDisplay,
      'resolution': resolution,
      'noVdDestroyContent': noVdDestroyContent,
      'noVdSystemDecorations': noVdSystemDecorations,
      'dpi': dpi,
      'cameraId': cameraId,
      'cameraSize': cameraSize,
      'cameraFacing': cameraFacing,
      'cameraFps': cameraFps,
      'cameraAr': cameraAr,
      'cameraHighSpeed': cameraHighSpeed,
      'noControl': noControl,
      'noMouseHover': noMouseHover,
      'legacyPaste': legacyPaste,
      'noKeyRepeat': noKeyRepeat,
      'rawKeyEvents': rawKeyEvents,
      'preferText': preferText,
      'mouseBind': mouseBind,
      'keyboardMode': keyboardMode,
      'mouseMode': mouseMode,
      'windowX': windowX,
      'windowY': windowY,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'rotation': rotation,
      'displayId': displayId,
      'displayBuffer': displayBuffer,
      'renderDriver': renderDriver,
      'forceAdbForward': forceAdbForward,
      'tcpipPort': tcpipPort,
      'selectTcpip': selectTcpip,
      'tunnelHost': tunnelHost,
      'tunnelPort': tunnelPort,
      'verbosity': verbosity,
      'noCleanup': noCleanup,
      'noDownsizeOnError': noDownsizeOnError,
      'v4l2Sink': v4l2Sink,
      'v4l2Buffer': v4l2Buffer,
      'otg': otg,
    };
  }

  factory ScrcpyCommand.fromJson(Map<String, dynamic> json) {
    return ScrcpyCommand(
      fullscreen: json['fullscreen'] as bool? ?? false,
      turnScreenOff: json['turnScreenOff'] as bool? ?? false,
      windowTitle: json['windowTitle'] as String? ?? '',
      crop: json['crop'] as String? ?? '',
      extraParameters: json['extraParameters'] as String? ?? '',
      videoOrientation: json['videoOrientation'] as String? ?? '',
      videoCodecEncoderPair: json['videoCodecEncoderPair'] as String? ?? '',
      stayAwake: json['stayAwake'] as bool? ?? false,
      windowBorderless: json['windowBorderless'] as bool? ?? false,
      windowAlwaysOnTop: json['windowAlwaysOnTop'] as bool? ?? false,
      disableScreensaver: json['disableScreensaver'] as bool? ?? false,
      videoBitRate: json['videoBitRate'] as String? ?? '',
      maxFps: json['maxFps'] as String? ?? '',
      maxSize: json['maxSize'] as String? ?? '',
      selectedPackage: json['selectedPackage'] as String? ?? '',
      printFps: json['printFps'] as bool? ?? false,
      timeLimit: json['timeLimit'] as String? ?? '',
      powerOffOnClose: json['powerOffOnClose'] as bool? ?? false,
      audioBitRate: json['audioBitRate'] as String? ?? '',
      audioBuffer: json['audioBuffer'] as String? ?? '',
      audioDup: json['audioDup'] as bool? ?? false,
      noAudio: json['noAudio'] as bool? ?? false,
      audioCodecOptions: json['audioCodecOptions'] as String? ?? '',
      audioCodecEncoderPair: json['audioCodecEncoderPair'] as String? ?? '',
      audioSource: json['audioSource'] as String? ?? '',
      outputFormat: json['outputFormat'] as String? ?? '',
      outputFile: json['outputFile'] as String? ?? '',
      recordOrientation: json['recordOrientation'] as String? ?? '',
      newDisplay: json['newDisplay'] as bool? ?? false,
      resolution: json['resolution'] as String? ?? '',
      noVdDestroyContent: json['noVdDestroyContent'] as bool? ?? false,
      noVdSystemDecorations: json['noVdSystemDecorations'] as bool? ?? false,
      dpi: json['dpi'] as String? ?? '',
      cameraId: json['cameraId'] as String? ?? '',
      cameraSize: json['cameraSize'] as String? ?? '',
      cameraFacing: json['cameraFacing'] as String? ?? '',
      cameraFps: json['cameraFps'] as String? ?? '',
      cameraAr: json['cameraAr'] as String? ?? '',
      cameraHighSpeed: json['cameraHighSpeed'] as bool? ?? false,
      noControl: json['noControl'] as bool? ?? false,
      noMouseHover: json['noMouseHover'] as bool? ?? false,
      legacyPaste: json['legacyPaste'] as bool? ?? false,
      noKeyRepeat: json['noKeyRepeat'] as bool? ?? false,
      rawKeyEvents: json['rawKeyEvents'] as bool? ?? false,
      preferText: json['preferText'] as bool? ?? false,
      mouseBind: json['mouseBind'] as String? ?? '',
      keyboardMode: json['keyboardMode'] as String? ?? '',
      mouseMode: json['mouseMode'] as String? ?? '',
      windowX: json['windowX'] as String? ?? '',
      windowY: json['windowY'] as String? ?? '',
      windowWidth: json['windowWidth'] as String? ?? '',
      windowHeight: json['windowHeight'] as String? ?? '',
      rotation: json['rotation'] as String? ?? '',
      displayId: json['displayId'] as String? ?? '',
      displayBuffer: json['displayBuffer'] as String? ?? '',
      renderDriver: json['renderDriver'] as String? ?? '',
      forceAdbForward: json['forceAdbForward'] as bool? ?? false,
      tcpipPort: json['tcpipPort'] as String? ?? '',
      selectTcpip: json['selectTcpip'] as bool? ?? false,
      tunnelHost: json['tunnelHost'] as String? ?? '',
      tunnelPort: json['tunnelPort'] as String? ?? '',
      verbosity: json['verbosity'] as String? ?? '',
      noCleanup: json['noCleanup'] as bool? ?? false,
      noDownsizeOnError: json['noDownsizeOnError'] as bool? ?? false,
      v4l2Sink: json['v4l2Sink'] as String? ?? '',
      v4l2Buffer: json['v4l2Buffer'] as String? ?? '',
      otg: json['otg'] as bool? ?? false,
    );
  }

  /// Generates the flag portion of the scrcpy command.
  /// Window title and serial are NOT included — CommandNotifier.fullCommand handles those.
  String toCliString() {
    final parts = <String>[];

    // GeneralCastOptions
    if (selectedPackage.isNotEmpty) parts.add('--start-app=$selectedPackage');
    if (fullscreen) parts.add('--fullscreen');
    if (turnScreenOff) parts.add('--turn-screen-off');
    if (crop.isNotEmpty) parts.add('--crop=$crop');
    if (videoOrientation.isNotEmpty) parts.add('--capture-orientation=$videoOrientation');
    if (stayAwake) parts.add('--stay-awake');
    if (videoBitRate.isNotEmpty) parts.add('--video-bit-rate=$videoBitRate');
    if (maxFps.isNotEmpty) parts.add('--max-fps=$maxFps');
    if (maxSize.isNotEmpty) parts.add('--max-size=$maxSize');
    if (windowBorderless) parts.add('--window-borderless');
    if (windowAlwaysOnTop) parts.add('--always-on-top');
    if (videoCodecEncoderPair.isNotEmpty) parts.add(videoCodecEncoderPair);
    if (printFps) parts.add('--print-fps');
    if (timeLimit.isNotEmpty) parts.add('--time-limit=$timeLimit');
    if (powerOffOnClose) parts.add('--power-off-on-close');
    if (extraParameters.isNotEmpty) parts.add(extraParameters);
    if (disableScreensaver) parts.add('--disable-screensaver');

    // AudioOptions
    if (audioBitRate.isNotEmpty) parts.add('--audio-bit-rate=$audioBitRate');
    if (audioBuffer.isNotEmpty) parts.add('--audio-buffer=$audioBuffer');
    if (audioSource.isNotEmpty) parts.add('--audio-source=$audioSource');
    if (audioCodecEncoderPair.isNotEmpty) parts.add(audioCodecEncoderPair);
    if (audioCodecOptions.isNotEmpty) parts.add('--audio-codec-options=$audioCodecOptions');
    if (audioDup) parts.add('--audio-dup');
    if (noAudio) parts.add('--no-audio');

    // ScreenRecordingOptions
    if (recordOrientation.isNotEmpty) parts.add('--record-orientation=$recordOrientation');
    if (outputFormat.isNotEmpty) parts.add('--record-format=$outputFormat');
    if (outputFile.isNotEmpty) {
      final ext = outputFormat.isNotEmpty ? '.$outputFormat' : '';
      final alreadyHasExt = ext.isNotEmpty && outputFile.endsWith(ext);
      parts.add('--record=$outputFile${alreadyHasExt ? '' : ext}');
    }

    // VirtualDisplayOptions
    if (newDisplay) {
      final buf = StringBuffer('--new-display');
      if (resolution.isNotEmpty) {
        buf.write('=$resolution');
        if (dpi.isNotEmpty) buf.write('/$dpi');
      } else if (dpi.isNotEmpty) {
        buf.write('=/$dpi');
      }
      parts.add(buf.toString());
    }
    if (noVdDestroyContent) parts.add('--no-vd-destroy-content');
    if (noVdSystemDecorations) parts.add('--no-vd-system-decorations');

    // CameraOptions — only emits --video-source=camera when at least one field is set
    final hasCameraOption = cameraId.isNotEmpty ||
        cameraSize.isNotEmpty ||
        cameraFacing.isNotEmpty ||
        cameraFps.isNotEmpty ||
        cameraAr.isNotEmpty ||
        cameraHighSpeed;
    if (hasCameraOption) {
      parts.add('--video-source=camera');
      if (cameraId.isNotEmpty) parts.add('--camera-id=$cameraId');
      if (cameraSize.isNotEmpty) parts.add('--camera-size=$cameraSize');
      if (cameraFacing.isNotEmpty) parts.add('--camera-facing=$cameraFacing');
      if (cameraFps.isNotEmpty) parts.add('--camera-fps=$cameraFps');
      if (cameraAr.isNotEmpty) parts.add('--camera-ar=$cameraAr');
      if (cameraHighSpeed) parts.add('--camera-high-speed');
    }

    // InputControlOptions
    if (keyboardMode.isNotEmpty) parts.add('--keyboard=$keyboardMode');
    if (mouseMode.isNotEmpty) parts.add('--mouse=$mouseMode');
    if (noControl) parts.add('--no-control');
    if (noMouseHover) parts.add('--no-mouse-hover');
    if (legacyPaste) parts.add('--legacy-paste');
    if (noKeyRepeat) parts.add('--no-key-repeat');
    if (rawKeyEvents) parts.add('--raw-key-events');
    if (preferText) parts.add('--prefer-text');
    if (mouseBind.isNotEmpty) parts.add('--mouse-bind=$mouseBind');

    // DisplayWindowOptions
    if (windowX.isNotEmpty) parts.add('--window-x=$windowX');
    if (windowY.isNotEmpty) parts.add('--window-y=$windowY');
    if (windowWidth.isNotEmpty) parts.add('--window-width=$windowWidth');
    if (windowHeight.isNotEmpty) parts.add('--window-height=$windowHeight');
    if (rotation.isNotEmpty) parts.add('--display-orientation=$rotation');
    if (displayId.isNotEmpty) parts.add('--display-id=$displayId');
    if (displayBuffer.isNotEmpty) parts.add('--video-buffer=$displayBuffer');
    if (renderDriver.isNotEmpty) parts.add('--render-driver=$renderDriver');
    if (forceAdbForward) parts.add('--force-adb-forward');

    // NetworkConnectionOptions
    if (tcpipPort.isNotEmpty) parts.add('--tcpip=$tcpipPort');
    if (selectTcpip) parts.add('--select-tcpip');
    if (tunnelHost.isNotEmpty) parts.add('--tunnel-host=$tunnelHost');
    if (tunnelPort.isNotEmpty) parts.add('--tunnel-port=$tunnelPort');

    // AdvancedOptions
    if (verbosity.isNotEmpty) parts.add('--verbosity=$verbosity');
    if (noCleanup) parts.add('--no-cleanup');
    if (noDownsizeOnError) parts.add('--no-downsize-on-error');
    if (v4l2Sink.isNotEmpty) parts.add('--v4l2-sink=$v4l2Sink');
    if (v4l2Buffer.isNotEmpty) parts.add('--v4l2-buffer=$v4l2Buffer');

    // OtgModeOptions
    if (otg) parts.add('--otg');

    return parts.join(' ');
  }
}
