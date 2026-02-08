/// Input control settings panel for keyboard and mouse configuration.
///
/// This panel provides configuration for input behavior including keyboard modes,
/// mouse bindings, click forwarding, and text injection preferences.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../models/scrcpy_options.dart';
import '../../utils/clear_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/surrounding_panel.dart';

/// Panel for configuring keyboard and mouse input behavior.
///
/// The [InputControlPanel] allows configuration of:
/// - Input control enabling/disabling
/// - Mouse hover behavior
/// - Click forwarding options
/// - Paste behavior (legacy mode)
/// - Key repeat settings
/// - Raw key events
/// - Text injection preferences
/// - Mouse button bindings
/// - Keyboard and mouse input modes
class InputControlPanel extends StatefulWidget {
  /// Creates an input control panel.
  const InputControlPanel({super.key, this.clearController});

  /// Optional controller for clearing all fields in this panel
  final ClearController? clearController;

  @override
  State<InputControlPanel> createState() => _InputControlPanelState();
}

class _InputControlPanelState extends State<InputControlPanel> {
  final List<String> mouseBindOptions = [
    'bhsm',
    'bhms',
    'bshm',
    'bsmh',
    'bmhs',
    'bmsh',
  ];

  final List<String> keyboardModeOptions = [
    'sdk',
    'uhid',
    'aoa',
    'disabled',
  ];

  final List<String> mouseModeOptions = [
    'sdk',
    'uhid',
    'aoa',
    'disabled',
  ];

  @override
  Widget build(BuildContext context) {
    final opts = context.select<CommandBuilderService, InputControlOptions>(
      (s) => s.inputControlOptions,
    );
    final cmdService = context.read<CommandBuilderService>();

    return SurroundingPanel(
      icon: Icons.gamepad,
      title: 'Input Control',
      showButton: true,
      panelType: "Input Control",
      onClearPressed: () {
        cmdService.updateInputControlOptions(const InputControlOptions());
        debugPrint('[InputControlPanel] Fields cleared!');
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
                  hintText: 'Keyboard Mode',
                  value: opts.keyboardMode.isNotEmpty ? opts.keyboardMode : null,
                  suggestions: keyboardModeOptions,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(keyboardMode: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateInputControlOptions(opts.copyWith(keyboardMode: ''));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Select how to send keyboard inputs: disabled, sdk (Android API), uhid (physical HID keyboard), or aoa (AOAv2 protocol, USB only).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Mouse Mode',
                  value: opts.mouseMode.isNotEmpty ? opts.mouseMode : null,
                  suggestions: mouseModeOptions,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(mouseMode: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateInputControlOptions(opts.copyWith(mouseMode: ''));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Select how to send mouse inputs: disabled, sdk (Android API), uhid (physical HID mouse), or aoa (AOAv2 protocol, USB only).',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomCheckbox(
                  label: 'No Control (View Only)',
                  value: opts.noControl,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(noControl: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Disable device control (mirror the device in read-only).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Mouse Hover',
                  value: opts.noMouseHover,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(noMouseHover: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Do not forward mouse hover (mouse motion without any clicks) events.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Forward All Clicks',
                  value: opts.forwardAllClicks,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(forwardAllClicks: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Forward all mouse clicks to the device, including secondary buttons.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomCheckbox(
                  label: 'Legacy Paste',
                  value: opts.legacyPaste,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(legacyPaste: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Inject computer clipboard text as a sequence of key events on Ctrl+v. This is a workaround for some devices not behaving as expected when setting the device clipboard programmatically.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Key Repeat',
                  value: opts.noKeyRepeat,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(noKeyRepeat: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Do not forward repeated key events when a key is held down.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Raw Key Events',
                  value: opts.rawKeyEvents,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(rawKeyEvents: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Inject key events for all input keys, and ignore text events.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomCheckbox(
                  label: 'Prefer Text Injection',
                  value: opts.preferText,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(preferText: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Inject alpha characters and space as text events instead of key events. This avoids issues when combining multiple keys to enter a special character, but breaks the expected behavior of alpha keys in games (typically WASD).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomSearchBar(
                  hintText: 'Mouse Bind (Button mapping)',
                  value: opts.mouseBind.isNotEmpty ? opts.mouseBind : null,
                  suggestions: mouseBindOptions,
                  onChanged: (val) {
                    cmdService.updateInputControlOptions(opts.copyWith(mouseBind: val));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  onClear: () {
                    cmdService.updateInputControlOptions(opts.copyWith(mouseBind: ''));
                    debugPrint('[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}');
                  },
                  tooltip: 'Configure bindings of secondary clicks. Each character maps a mouse button: + (forward), - (ignore), b (BACK), h (HOME), s (APP_SWITCH), n (notifications).',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
