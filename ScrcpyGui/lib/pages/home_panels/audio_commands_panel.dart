/// Audio settings panel for scrcpy command configuration.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../services/device_manager_service.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/surrounding_panel.dart';

class AudioCommandsPanel extends StatefulWidget {
  const AudioCommandsPanel({super.key});

  @override
  State<AudioCommandsPanel> createState() => _AudioCommandsPanelState();
}

class _AudioCommandsPanelState extends State<AudioCommandsPanel> {
  final List<String> audioBitRateOptions = [
    '64k', '128k', '192k', '256k', '320k',
  ];
  final List<String> audioBufferOptions = ['256', '512', '1024', '2048'];
  final List<String> audioCodecOptionsList = [
    'flac-compression-level=8',
    'bitrate=128000',
  ];
  final List<String> audioSources = [
    'output', 'playback', 'mic', 'mic-unprocessed', 'mic-camcorder',
    'mic-voice-recognition', 'mic-voice-communication', 'voice-call',
    'voice-call-uplink', 'voice-call-downlink', 'voice-performance',
  ];

  List<String> audioCodecEncoders = [];
  DeviceManagerService? _deviceManager;

  @override
  void initState() {
    super.initState();
    _loadAudioCodecs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceManager = context.read<DeviceManagerService>();
      _deviceManager?.selectedDeviceNotifier.addListener(_onDeviceChanged);
    });
  }

  void _onDeviceChanged() => _loadAudioCodecs();

  void _loadAudioCodecs() {
    final deviceManager = context.read<DeviceManagerService>();
    final selectedDevice = deviceManager.selectedDevice;

    if (selectedDevice == null) {
      setState(() => audioCodecEncoders = []);
      return;
    }

    final info = DeviceManagerService.devicesInfo[selectedDevice];
    if (info != null) {
      setState(() => audioCodecEncoders = info.audioCodecs);
    }

    // If the current codec is no longer valid for this device, clear it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = context.read<CommandNotifier>();
      if (notifier.current.audioCodecEncoderPair.isNotEmpty &&
          !audioCodecEncoders.contains(notifier.current.audioCodecEncoderPair)) {
        notifier.update(notifier.current.copyWith(audioCodecEncoderPair: ''));
      }
    });
  }

  @override
  void dispose() {
    _deviceManager?.selectedDeviceNotifier.removeListener(_onDeviceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;

    return SurroundingPanel(
      icon: Icons.headphones,
      title: 'Audio',
      showButton: true,
      panelType: 'Audio',
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(
        audioBitRate: '',
        audioBuffer: '',
        audioCodecOptions: '',
        audioSource: '',
        audioCodecEncoderPair: '',
        audioDup: false,
        noAudio: false,
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Bit Rate',
                  value: cmd.audioBitRate.isEmpty ? null : cmd.audioBitRate,
                  suggestions: audioBitRateOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(audioBitRate: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(audioBitRate: '')),
                  tooltip: "Encode the audio at the given bit rate, expressed in bits/s. Unit suffixes are supported: 'K' (x1000) and 'M' (x1000000). Default is 128K (128000).",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Buffer',
                  value: cmd.audioBuffer.isEmpty ? null : cmd.audioBuffer,
                  suggestions: audioBufferOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(audioBuffer: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(audioBuffer: '')),
                  tooltip: 'Configure the audio buffering delay (in milliseconds). Lower values decrease the latency, but increase the likelihood of buffer underrun (causing audio glitches). Default is 50.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Audio Codec Options',
                  value: cmd.audioCodecOptions.isEmpty
                      ? null
                      : cmd.audioCodecOptions,
                  suggestions: audioCodecOptionsList,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(audioCodecOptions: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(audioCodecOptions: '')),
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
                  value: cmd.audioSource.isEmpty ? null : cmd.audioSource,
                  suggestions: audioSources,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(audioSource: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(audioSource: '')),
                  tooltip: 'Select the audio source: output (whole audio output), playback (audio playback), mic (microphone), mic-unprocessed, mic-camcorder, mic-voice-recognition, mic-voice-communication. Default is output.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Audio',
                  value: cmd.noAudio,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(noAudio: val)),
                  tooltip: 'Disable audio forwarding.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Audio Duplication',
                  value: cmd.audioDup,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(audioDup: val)),
                  tooltip: 'Duplicate audio (capture and keep playing on the device). This feature is only available with --audio-source=playback.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomSearchBar(
            hintText: 'Audio Codec - Encoder',
            value: cmd.audioCodecEncoderPair.isEmpty
                ? null
                : cmd.audioCodecEncoderPair,
            suggestions: audioCodecEncoders,
            onChanged: (val) =>
                notifier.update(cmd.copyWith(audioCodecEncoderPair: val)),
            onClear: () =>
                notifier.update(cmd.copyWith(audioCodecEncoderPair: '')),
            onReload: _loadAudioCodecs,
            tooltip: 'Select an audio codec (opus, aac, flac or raw). Default is opus. Use a specific MediaCodec audio encoder (depending on the codec).',
          ),
        ],
      ),
    );
  }
}
