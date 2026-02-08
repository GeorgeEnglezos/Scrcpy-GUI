/// Screen recording settings panel for scrcpy.
///
/// This panel provides configuration for recording device screen to video files
/// with options for format, quality, size, and orientation.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';
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

  String recordingsDirectory = '';

  @override
  void initState() {
    super.initState();
    _loadRecordingsDirectory();
  }

  Future<void> _loadRecordingsDirectory() async {
    final settings = await _settingsService.loadSettings();
    if (mounted) {
      setState(() {
        recordingsDirectory = settings.recordingsDirectory;
      });
    }

    // Create directory if it doesn't exist
    if (recordingsDirectory.isNotEmpty) {
      final dir = Directory(recordingsDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  void _initializeRecordingOptions(CommandBuilderService cmdService) {
    final now = DateTime.now();
    final formattedDateTime =
        "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}_${now.second.toString().padLeft(2, '0')}";

    final recordingsDir =
        SettingsService.currentSettings?.recordingsDirectory ?? '';

    final newOptions = cmdService.recordingOptions.copyWith(
      outputFile: "$recordingsDir/Scrcpy_$formattedDateTime",
      outputFormat: "mp4",
      framerate: "30",
      maxSize: "",
    );
    cmdService.updateRecordingOptions(newOptions);
    debugPrint('[RecordingCommandsPanel] Recording initialized → ${cmdService.fullCommand}');
  }

  void _cleanSettings(CommandBuilderService cmdService) {
    final newOptions = cmdService.recordingOptions.copyWith(
      outputFile: "",
      outputFormat: "",
      framerate: "",
      maxSize: "",
      recordOrientation: "",
    );
    cmdService.updateRecordingOptions(newOptions);
    debugPrint('[RecordingCommandsPanel] Recording settings cleaned → ${cmdService.fullCommand}');
  }

  @override
  Widget build(BuildContext context) {
    final opts = context.select<CommandBuilderService, ScreenRecordingOptions>(
      (s) => s.recordingOptions,
    );
    final cmdService = context.read<CommandBuilderService>();
    final enableRecording = opts.outputFile.isNotEmpty;

    return SurroundingPanel(
      icon: Icons.videocam,
      title: 'Recording',
      panelType: "Recording",
      showButton: true,
      onClearPressed: () {
        cmdService.updateRecordingOptions(const ScreenRecordingOptions());
        debugPrint('[RecordingCommandsPanel] Fields cleared!');
      },
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
                    if (val) {
                      _initializeRecordingOptions(cmdService);
                    } else {
                      _cleanSettings(cmdService);
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
                      value: opts.outputFile,
                      onChanged: (val) {
                        cmdService.updateRecordingOptions(
                          opts.copyWith(outputFile: val),
                        );
                        debugPrint('[RecordingCommandsPanel] Updated ScreenRecordingOptions → ${cmdService.fullCommand}');
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
                        cmdService.updateRecordingOptions(
                          opts.copyWith(outputFormat: val),
                        );
                        debugPrint('[RecordingCommandsPanel] Updated ScreenRecordingOptions → ${cmdService.fullCommand}');
                      },
                      onClear: () {
                        cmdService.updateRecordingOptions(
                          opts.copyWith(outputFormat: ''),
                        );
                        debugPrint('[RecordingCommandsPanel] Updated ScreenRecordingOptions → ${cmdService.fullCommand}');
                      },
                      value: opts.outputFormat,
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
                      value: opts.framerate,
                      onChanged: (val) {
                        cmdService.updateRecordingOptions(
                          opts.copyWith(framerate: val),
                        );
                        debugPrint('[RecordingCommandsPanel] Updated ScreenRecordingOptions → ${cmdService.fullCommand}');
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
                      value: opts.maxSize,
                      onChanged: (val) {
                        cmdService.updateRecordingOptions(
                          opts.copyWith(maxSize: val),
                        );
                        debugPrint('[RecordingCommandsPanel] Updated ScreenRecordingOptions → ${cmdService.fullCommand}');
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
                        cmdService.updateRecordingOptions(
                          opts.copyWith(recordOrientation: val),
                        );
                        debugPrint('[RecordingCommandsPanel] Updated ScreenRecordingOptions → ${cmdService.fullCommand}');
                      },
                      onClear: () {
                        cmdService.updateRecordingOptions(
                          opts.copyWith(recordOrientation: ''),
                        );
                        debugPrint('[RecordingCommandsPanel] Updated ScreenRecordingOptions → ${cmdService.fullCommand}');
                      },
                      value: opts.recordOrientation,
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
