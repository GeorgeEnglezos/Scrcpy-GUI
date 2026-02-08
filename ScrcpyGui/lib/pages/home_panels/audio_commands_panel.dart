/// Audio settings panel for scrcpy command configuration.
///
/// This panel provides comprehensive audio configuration including codecs,
/// bit rates, buffering, sources, and audio-specific options.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';
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
      if (!mounted) return;
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
      if (mounted) setState(() => audioCodecEncoders = []);
      return;
    }

    final info = DeviceManagerService.devicesInfo[selectedDevice];
    if (info != null) {
      if (mounted) setState(() => audioCodecEncoders = info.audioCodecs);
    }
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opts = context.select<CommandBuilderService, AudioOptions>(
      (s) => s.audioOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    return SurroundingPanel(
      icon: Icons.headphones,
      title: 'Audio',
      showButton: true,
      panelType: "Audio",
      clearController: widget.clearController,
      onClearPressed: () {
        cmdService.updateAudioOptions(const AudioOptions());
        debugPrint('[AudioCommandsPanel] Fields cleared!');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Bit Rate',
                  value: opts.audioBitRate.isNotEmpty ? opts.audioBitRate : null,
                  suggestions: audioBitRateOptions,
                  onChanged: (val) {
                    cmdService.updateAudioOptions(opts.copyWith(audioBitRate: val));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateAudioOptions(opts.copyWith(audioBitRate: ''));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Encode the audio at the given bit rate, expressed in bits/s. Unit suffixes are supported: \'K\' (x1000) and \'M\' (x1000000). Default is 128K (128000).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Buffer',
                  value: opts.audioBuffer.isNotEmpty ? opts.audioBuffer : null,
                  suggestions: audioBufferOptions,
                  onChanged: (val) {
                    cmdService.updateAudioOptions(opts.copyWith(audioBuffer: val));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateAudioOptions(opts.copyWith(audioBuffer: ''));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Configure the audio buffering delay (in milliseconds). Lower values decrease the latency, but increase the likelihood of buffer underrun (causing audio glitches). Default is 50.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Codec Options',
                  value: opts.audioCodecOptions.isNotEmpty
                      ? opts.audioCodecOptions
                      : null,
                  suggestions: audioCodecOptionsList,
                  onChanged: (val) {
                    cmdService.updateAudioOptions(opts.copyWith(audioCodecOptions: val));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateAudioOptions(opts.copyWith(audioCodecOptions: ''));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
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
                  value: opts.audioSource.isNotEmpty ? opts.audioSource : null,
                  suggestions: audioSources,
                  onChanged: (val) {
                    cmdService.updateAudioOptions(opts.copyWith(audioSource: val));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateAudioOptions(opts.copyWith(audioSource: ''));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Select the audio source: output (whole audio output), playback (audio playback), mic (microphone), mic-unprocessed, mic-camcorder, mic-voice-recognition, mic-voice-communication. Default is output.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Audio',
                  value: opts.noAudio,
                  onChanged: (val) {
                    cmdService.updateAudioOptions(opts.copyWith(noAudio: val));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Disable audio forwarding.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Audio Duplication',
                  value: opts.audioDup,
                  onChanged: (val) {
                    cmdService.updateAudioOptions(opts.copyWith(audioDup: val));
                    debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Duplicate audio (capture and keep playing on the device). This feature is only available with --audio-source=playback.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomSearchBar(
            hintText: 'Audio Codec - Encoder',
            value: opts.audioCodecEncoderPair.isNotEmpty
                ? opts.audioCodecEncoderPair
                : null,
            suggestions: audioCodecEncoders,
            onChanged: (val) {
              cmdService.updateAudioOptions(opts.copyWith(audioCodecEncoderPair: val));
              debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
            },
            onClear: () {
              cmdService.updateAudioOptions(opts.copyWith(audioCodecEncoderPair: ''));
              debugPrint('[AudioCommandsPanel] Updated AudioOptions → ${cmdService.fullCommand}');
            },
            onReload: _loadAudioCodecs,
            tooltip: 'Select an audio codec (opus, aac, flac or raw). Default is opus. Use a specific MediaCodec audio encoder (depending on the codec).',
          ),
        ],
      ),
    );
  }
}
