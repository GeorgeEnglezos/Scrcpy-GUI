/// Screen recording settings panel for scrcpy.
///
/// This panel provides configuration for recording device screen to video files
/// with options for format, quality, size, and orientation.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/command_builder_service.dart';
import '../../services/settings_service.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

/// Panel for configuring screen recording options.
///
/// The [RecordingCommandsPanel] allows configuration of:
/// - Recording enable/disable
/// - Output file name and directory
/// - Video format (mp4, mkv, avi, mov, webm)
/// - Maximum frame rate
/// - Maximum video size
/// - Recording orientation
/// - Time limit for recording
/// - No display mode (record without mirroring)
///
/// The panel integrates with [SettingsService] for default directory paths.
class RecordingCommandsPanel extends StatefulWidget {
  /// Creates a recording commands panel.
  const RecordingCommandsPanel({super.key, this.clearController});

  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

  @override
  State<RecordingCommandsPanel> createState() => _RecordingCommandsPanelState();
}

class _RecordingCommandsPanelState extends State<RecordingCommandsPanel> {
  final List<String> outputFormats = ['mp4', 'mkv', 'avi', 'mov', 'webm'];
  final List<String> orientations = ['0', '90', '180', '270'];
  final SettingsService _settingsService = SettingsService();

  bool enableRecording = false;
  String fileName = '';
  String outputFormat = '';
  String maxFps = '';
  String maxSize = '';
  String recordOrientation = '';
  String recordingsDirectory = '';

  @override
  void initState() {
    super.initState();
    _loadRecordingsDirectory();
  }

  Future<void> _loadRecordingsDirectory() async {
    final settings = await _settingsService.loadSettings();
    recordingsDirectory = settings.recordingsDirectory;

    // Create directory if it doesn't exist
    if (recordingsDirectory.isNotEmpty) {
      final dir = Directory(recordingsDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  void _updateService(BuildContext context) {
    final cmdService = Provider.of<CommandBuilderService>(
      context,
      listen: false,
    );

    final options = cmdService.recordingOptions.copyWith(
      outputFile: fileName,
      outputFormat: outputFormat,
      framerate: maxFps,
      maxSize: maxSize,
      recordOrientation: recordOrientation,
    );

    cmdService.updateRecordingOptions(options);

    debugPrint(
      '[RecordingPanel] Updated RecordingOptions → ${cmdService.fullCommand}',
    );
  }

  void _initializeRecordingOptions(BuildContext context) {
    final now = DateTime.now();
    final formattedDateTime =
        "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}_${now.second.toString().padLeft(2, '0')}";

    final recordingsDir =
        SettingsService.currentSettings?.recordingsDirectory ?? '';

    setState(() {
      fileName = "$recordingsDir/Scrcpy_$formattedDateTime";
      outputFormat = "mp4";
      maxFps = "30";
      maxSize = "";
    });

    _updateService(context);
  }

  void _cleanSettings(BuildContext context) {
    setState(() {
      fileName = "";
      outputFormat = "";
      maxFps = "";
      maxSize = "";
      recordOrientation = "";
    });

    _updateService(context);
  }

  void _clearAllFields() {
    setState(() {
      enableRecording = false;
      fileName = '';
      outputFormat = '';
      maxFps = '';
      maxSize = '';
      recordOrientation = '';
    });
    _updateService(context);
  }

  @override
  Widget build(BuildContext context) {
    return SurroundingPanel(
      icon: Icons.videocam,
      title: 'Recording',
      panelType: "Recording",
      showButton: true,
      onClearPressed: _clearAllFields,
      clearController: widget.clearController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: CustomCheckbox(
                  label: 'Enable Recording',
                  value: enableRecording,
                  onChanged: (val) {
                    setState(() => enableRecording = val);
                    if (val) {
                      _initializeRecordingOptions(context);
                    } else {
                      _cleanSettings(context);
                    }
                  },
                  tooltip: 'Record screen to file. The format is determined by the --record-format option if set, or by the file extension.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AbsorbPointer(
                  absorbing: !enableRecording,
                  child: Opacity(
                    opacity: enableRecording ? 1.0 : 0.5,
                    child: CustomTextField(
                      label: 'File Name',
                      value: fileName,
                      onChanged: (val) {
                        setState(() => fileName = val);
                        _updateService(context);
                      },
                      tooltip: 'Set the file path for recording. The format is determined by the file extension or the output format option.',
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: AbsorbPointer(
                  absorbing: !enableRecording,
                  child: Opacity(
                    opacity: enableRecording ? 1.0 : 0.5,
                    child: CustomSearchBar(
                      hintText: 'Select format',
                      suggestions: outputFormats,
                      onChanged: (val) {
                        setState(() => outputFormat = val);
                        _updateService(context);
                      },
                      onClear: () {
                        setState(() => outputFormat = '');
                        _updateService(context);
                      },
                      value: outputFormat,
                      tooltip: 'Force recording format (mp4, mkv, m4a, mka, opus, aac, flac or wav).',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !enableRecording,
                  child: Opacity(
                    opacity: enableRecording ? 1.0 : 0.5,
                    child: CustomTextField(
                      label: 'Max fps',
                      value: maxFps,
                      onChanged: (val) {
                        setState(() => maxFps = val);
                        _updateService(context);
                      },
                      tooltip: 'Limit the frame rate of screen capture (officially supported since Android 10, but may work on earlier versions).',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AbsorbPointer(
                  absorbing: !enableRecording,
                  child: Opacity(
                    opacity: enableRecording ? 1.0 : 0.5,
                    child: CustomTextField(
                      label: 'Max Size',
                      value: maxSize,
                      onChanged: (val) {
                        setState(() => maxSize = val);
                        _updateService(context);
                      },
                      tooltip: 'Limit both the width and height of the video to value. The other dimension is computed so that the device aspect-ratio is preserved. Default is 0 (unlimited).',
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: AbsorbPointer(
                  absorbing: !enableRecording,
                  child: Opacity(
                    opacity: enableRecording ? 1.0 : 0.5,
                    child: CustomSearchBar(
                      hintText: 'Record Orientation',
                      suggestions: orientations,
                      onChanged: (val) {
                        setState(() => recordOrientation = val);
                        _updateService(context);
                      },
                      onClear: () {
                        setState(() => recordOrientation = '');
                        _updateService(context);
                      },
                      value: recordOrientation,
                      tooltip: 'Set the record orientation. The number represents the clockwise rotation in degrees (0, 90, 180, 270). Default is 0.',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}
