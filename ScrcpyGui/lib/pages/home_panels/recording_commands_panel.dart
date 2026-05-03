/// Screen recording settings panel for scrcpy.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../services/settings_service.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

class RecordingCommandsPanel extends StatefulWidget {
  const RecordingCommandsPanel({super.key});

  @override
  State<RecordingCommandsPanel> createState() => _RecordingCommandsPanelState();
}

class _RecordingCommandsPanelState extends State<RecordingCommandsPanel> {
  final List<String> outputFormats = [
    'mp4', 'mkv', 'm4a', 'mka', 'opus', 'aac', 'flac', 'wav',
  ];
  final List<String> orientations = ['0', '90', '180', '270'];

  void _initializeRecordingOptions(CommandNotifier notifier) {
    final now = DateTime.now();
    final formattedDateTime =
        '${now.year}_${now.month.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}_'
        '${now.minute.toString().padLeft(2, '0')}_'
        '${now.second.toString().padLeft(2, '0')}';
    final recordingsDir =
        SettingsService.currentSettings?.recordingsDirectory ?? '';
    notifier.update(notifier.current.copyWith(
      outputFile: '$recordingsDir/Scrcpy_$formattedDateTime',
      outputFormat: 'mp4',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;
    final enableRecording = cmd.outputFile.isNotEmpty;

    return SurroundingPanel(
      icon: Icons.videocam,
      title: 'Recording',
      panelType: 'Recording',
      showButton: true,
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(
        outputFile: '',
        outputFormat: '',
        recordOrientation: '',
      )),
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
                      _initializeRecordingOptions(notifier);
                    } else {
                      notifier.update(cmd.copyWith(
                        outputFile: '',
                        outputFormat: '',
                        recordOrientation: '',
                      ));
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
                      value: cmd.outputFile,
                      onChanged: (val) =>
                          notifier.update(cmd.copyWith(outputFile: val)),
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
                      value: cmd.outputFormat.isEmpty ? null : cmd.outputFormat,
                      onChanged: (val) =>
                          notifier.update(cmd.copyWith(outputFormat: val)),
                      onClear: () =>
                          notifier.update(cmd.copyWith(outputFormat: '')),
                      tooltip: 'Force recording format (mp4, mkv, m4a, mka, opus, aac, flac or wav).',
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
                      value: cmd.recordOrientation.isEmpty
                          ? null
                          : cmd.recordOrientation,
                      onChanged: (val) =>
                          notifier.update(cmd.copyWith(recordOrientation: val)),
                      onClear: () =>
                          notifier.update(cmd.copyWith(recordOrientation: '')),
                      tooltip: 'Set the record orientation. The number represents the clockwise rotation in degrees (0, 90, 180, 270). Default is 0.',
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ],
      ),
    );
  }
}
