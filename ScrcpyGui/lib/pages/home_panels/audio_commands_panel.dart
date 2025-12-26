/// Audio settings panel for scrcpy command configuration.
///
/// This panel provides comprehensive audio configuration including codecs,
/// bit rates, buffering, sources, and audio-specific options.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../services/device_manager_service.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/surrounding_panel.dart';

/// Panel for configuring audio-related scrcpy options.
///
/// The [AudioCommandsPanel] allows users to configure:
/// - Audio codecs and encoders (device-specific)
/// - Bit rate for audio encoding
/// - Audio buffering delays
/// - Audio source selection (output, playback, mic variants)
/// - Audio duplication and forwarding options
///
/// The panel automatically loads available audio codecs from the selected
/// device and updates when the device selection changes.
class AudioCommandsPanel extends StatefulWidget {
  /// Creates an audio commands panel.
  const AudioCommandsPanel({super.key, this.clearController});

  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

  @override
  State<AudioCommandsPanel> createState() => _AudioCommandsPanelState();
}

class _AudioCommandsPanelState extends State<AudioCommandsPanel> {
  String audioBitRate = '';
  String audioBuffer = '';
  String audioCodecOptions = '';
  String audioSource = '';
  String audioCodec = '';
  bool noAudio = false;
  bool audioDuplication = false;

  final List<String> audioBitRateOptions = [
    '64k',
    '128k',
    '192k',
    '256k',
    '320k',
  ];
  final List<String> audioBufferOptions = ['256', '512', '1024', '2048'];
  final List<String> audioCodecOptionsList = ['aac', 'mp3', 'opus', 'flac'];
  final List<String> audioSources = [
    'output',
    'playback',
    'mic',
    'mic-unprocessed',
    'mic-camcorder',
    'mic-voice-recognition',
    'mic-voice-communication',
  ];
  List<String> audioCodecEncoders = [];

  DeviceManagerService? _deviceManager;

  @override
  void initState() {
    super.initState();
    _loadAudioCodecs();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceManager = Provider.of<DeviceManagerService>(
        context,
        listen: false,
      );
      _deviceManager?.selectedDeviceNotifier.addListener(_onDeviceChanged);
    });
  }

  void _onDeviceChanged() {
    _loadAudioCodecs();
  }

  /// Loads audio codecs for the selected device
  void _loadAudioCodecs() {
    final deviceManager = Provider.of<DeviceManagerService>(
      context,
      listen: false,
    );
    final selectedDevice = deviceManager.selectedDevice;

    if (selectedDevice == null) {
      setState(() {
        audioCodecEncoders = [];
        audioCodec = '';
      });
      return;
    }

    final info = DeviceManagerService.devicesInfo[selectedDevice];
    if (info != null) {
      setState(() {
        audioCodecEncoders = info.audioCodecs;

        if (!audioCodecEncoders.contains(audioCodec)) {
          audioCodec = '';
        }
      });
    }
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    super.dispose();
  }

  void _updateService(BuildContext context) {
    final cmdService = Provider.of<CommandBuilderService>(
      context,
      listen: false,
    );

    final options = cmdService.audioOptions.copyWith(
      audioBitRate: audioBitRate,
      audioBuffer: audioBuffer,
      audioCodecOptions: audioCodecOptions,
      audioSource: audioSource,
      audioCodecEncoderPair: audioCodec,
      audioDup: audioDuplication,
      noAudio: noAudio,
    );

    cmdService.updateAudioOptions(options);

    debugPrint(
      '[AudioPanel] Updated AudioOptions → ${cmdService.fullCommand}',
    );
  }

  void _clearAllFields() {
    setState(() {
      audioBitRate = '';
      audioBuffer = '';
      audioCodecOptions = '';
      audioSource = '';
      audioCodec = '';
      noAudio = false;
      audioDuplication = false;
    });
    _updateService(context);
    debugPrint('[AudioPanel] Fields cleared!');
  }

  @override
  Widget build(BuildContext context) {
    return SurroundingPanel(
      icon: Icons.headphones,
      title: 'Audio',
      showButton: true,
      panelType: "Audio",
      clearController: widget.clearController,
      onClearPressed: _clearAllFields,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Bit Rate',
                  value: audioBitRate.isNotEmpty ? audioBitRate : null,
                  suggestions: audioBitRateOptions,
                  onChanged: (val) {
                    setState(() => audioBitRate = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => audioBitRate = '');
                    _updateService(context);
                  },
                  tooltip: 'Encode the audio at the given bit rate, expressed in bits/s. Unit suffixes are supported: \'K\' (x1000) and \'M\' (x1000000). Default is 128K (128000).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Buffer',
                  value: audioBuffer.isNotEmpty ? audioBuffer : null,
                  suggestions: audioBufferOptions,
                  onChanged: (val) {
                    setState(() => audioBuffer = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => audioBuffer = '');
                    _updateService(context);
                  },
                  tooltip: 'Configure the audio buffering delay (in milliseconds). Lower values decrease the latency, but increase the likelihood of buffer underrun (causing audio glitches). Default is 50.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Codec Options',
                  value: audioCodecOptions.isNotEmpty
                      ? audioCodecOptions
                      : null,
                  suggestions: audioCodecOptionsList,
                  onChanged: (val) {
                    setState(() => audioCodecOptions = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => audioCodecOptions = '');
                    _updateService(context);
                  },
                  tooltip: 'Set codec-specific options for the device audio encoder. The list of possible codec options is available in the Android documentation.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Source',
                  value: audioSource.isNotEmpty ? audioSource : null,
                  suggestions: audioSources,
                  onChanged: (val) {
                    setState(() => audioSource = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => audioSource = '');
                    _updateService(context);
                  },
                  tooltip: 'Select the audio source: output (whole audio output), playback (audio playback), mic (microphone), mic-unprocessed, mic-camcorder, mic-voice-recognition, mic-voice-communication. Default is output.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Audio',
                  value: noAudio,
                  onChanged: (val) {
                    setState(() => noAudio = val);
                    _updateService(context);
                  },
                  tooltip: 'Disable audio forwarding.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Audio Duplication',
                  value: audioDuplication,
                  onChanged: (val) {
                    setState(() => audioDuplication = val);
                    _updateService(context);
                  },
                  tooltip: 'Duplicate audio (capture and keep playing on the device). This feature is only available with --audio-source=playback.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomSearchBar(
            hintText: 'Audio Codec - Encoder',
            value: audioCodec.isNotEmpty ? audioCodec : null,
            suggestions: audioCodecEncoders,
            onChanged: (val) {
              setState(() => audioCodec = val);
              _updateService(context);
            },
            onClear: () {
              setState(() => audioCodec = '');
              _updateService(context);
            },
            onReload: _loadAudioCodecs,
            tooltip: 'Select an audio codec (opus, aac, flac or raw). Default is opus. Use a specific MediaCodec audio encoder (depending on the codec).',
          ),
        ],
      ),
    );
  }
}
