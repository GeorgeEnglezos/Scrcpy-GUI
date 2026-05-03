/// Advanced/Developer settings panel for scrcpy command configuration.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

class AdvancedPanel extends StatefulWidget {
  const AdvancedPanel({super.key});

  @override
  State<AdvancedPanel> createState() => _AdvancedPanelState();
}

class _AdvancedPanelState extends State<AdvancedPanel> {
  final List<String> verbosityOptions = [
    'verbose',
    'debug',
    'info',
    'warn',
    'error',
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;

    return SurroundingPanel(
      icon: Icons.settings_applications,
      title: 'Advanced/Developer',
      showButton: true,
      panelType: 'Advanced',
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(
        verbosity: '',
        noCleanup: false,
        noDownsizeOnError: false,
        v4l2Sink: '',
        v4l2Buffer: '',
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Verbosity Level',
                  value: cmd.verbosity.isEmpty ? null : cmd.verbosity,
                  suggestions: verbosityOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(verbosity: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(verbosity: '')),
                  tooltip: 'Set the log level (verbose, debug, info, warn or error). Default is info.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Cleanup',
                  value: cmd.noCleanup,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(noCleanup: val)),
                  tooltip: 'By default, scrcpy removes the server binary from the device and restores the device state on exit. This option disables this cleanup.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Downsize on Error',
                  value: cmd.noDownsizeOnError,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(noDownsizeOnError: val)),
                  tooltip: 'By default, on MediaCodec error, scrcpy automatically tries again with a lower definition. This option disables this behavior.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'V4L2 Sink (Linux)',
                  value: cmd.v4l2Sink,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(v4l2Sink: val)),
                  tooltip: 'Output to v4l2loopback device (e.g., /dev/videoN). This feature is only available on Linux.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'V4L2 Buffer (ms)',
                  value: cmd.v4l2Buffer,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(v4l2Buffer: val)),
                  tooltip: 'Add a buffering delay (in milliseconds) before pushing frames. This increases latency to compensate for jitter. Default is 0 (no buffering). Linux only.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Advanced options for debugging and specialized use cases.\n'
            'V4L2 options are Linux-only for virtual camera loopback.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
