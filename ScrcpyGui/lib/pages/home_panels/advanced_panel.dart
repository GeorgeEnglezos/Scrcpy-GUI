/// Advanced/Developer settings panel for scrcpy command configuration.
///
/// This panel provides access to advanced scrcpy options including verbosity levels,
/// cleanup settings, error handling, and Linux-specific V4L2 options for virtual camera.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/custom_textinput.dart';
import '../../widgets/surrounding_panel.dart';

/// Panel for configuring advanced scrcpy options and developer settings.
///
/// The [AdvancedPanel] allows users to configure:
/// - Verbosity level for logging (verbose, debug, info, warn, error)
/// - Cleanup behavior on exit
/// - Error handling (auto-downsize on MediaCodec errors)
/// - V4L2 virtual camera options (Linux only)
///
/// All settings are synchronized with [CommandBuilderService] to update
/// the generated scrcpy command in real-time.
class AdvancedPanel extends StatefulWidget {
  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

  /// Creates an advanced settings panel.
  const AdvancedPanel({super.key, this.clearController});

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
    final opts = context.select<CommandBuilderService, AdvancedOptions>(
      (s) => s.advancedOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    return SurroundingPanel(
      icon: Icons.settings_applications,
      title: 'Advanced/Developer',
      showButton: true,
      panelType: "Advanced",
      onClearPressed: () {
        cmdService.updateAdvancedOptions(const AdvancedOptions());
        debugPrint('[AdvancedPanel] Fields cleared!');
      },
      clearController: widget.clearController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Verbosity Level',
                  value: opts.verbosity.isNotEmpty ? opts.verbosity : null,
                  suggestions: verbosityOptions,
                  onChanged: (val) {
                    cmdService.updateAdvancedOptions(opts.copyWith(verbosity: val));
                    debugPrint('[AdvancedPanel] Updated AdvancedOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateAdvancedOptions(opts.copyWith(verbosity: ''));
                    debugPrint('[AdvancedPanel] Updated AdvancedOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Set the log level (verbose, debug, info, warn or error). Default is info.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Cleanup',
                  value: opts.noCleanup,
                  onChanged: (val) {
                    cmdService.updateAdvancedOptions(opts.copyWith(noCleanup: val));
                    debugPrint('[AdvancedPanel] Updated AdvancedOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'By default, scrcpy removes the server binary from the device and restores the device state on exit. This option disables this cleanup.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Downsize on Error',
                  value: opts.noDownsizeOnError,
                  onChanged: (val) {
                    cmdService.updateAdvancedOptions(opts.copyWith(noDownsizeOnError: val));
                    debugPrint('[AdvancedPanel] Updated AdvancedOptions → ${cmdService.fullCommand}');
                  },
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
                  value: opts.v4l2Sink,
                  onChanged: (val) {
                    cmdService.updateAdvancedOptions(opts.copyWith(v4l2Sink: val));
                    debugPrint('[AdvancedPanel] Updated AdvancedOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Output to v4l2loopback device (e.g., /dev/videoN). This feature is only available on Linux.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'V4L2 Buffer (ms)',
                  value: opts.v4l2Buffer,
                  onChanged: (val) {
                    cmdService.updateAdvancedOptions(opts.copyWith(v4l2Buffer: val));
                    debugPrint('[AdvancedPanel] Updated AdvancedOptions → ${cmdService.fullCommand}');
                  },
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
