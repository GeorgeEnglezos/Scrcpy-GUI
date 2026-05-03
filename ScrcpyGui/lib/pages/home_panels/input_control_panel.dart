/// Input control settings panel for keyboard and mouse configuration.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/command_notifier.dart';
import '../../widgets/custom_checkbox.dart';
import '../../widgets/custom_searchbar.dart';
import '../../widgets/surrounding_panel.dart';

class InputControlPanel extends StatefulWidget {
  const InputControlPanel({super.key});

  @override
  State<InputControlPanel> createState() => _InputControlPanelState();
}

class _InputControlPanelState extends State<InputControlPanel> {
  final List<String> mouseBindOptions = [
    '++++:++++',
    'bhsn',
    'bhsn:++++',
    '++++:bhsn',
    'b+++',
    '----',
  ];

  final List<String> keyboardModeOptions = ['sdk', 'uhid', 'aoa', 'disabled'];
  final List<String> mouseModeOptions = ['sdk', 'uhid', 'aoa', 'disabled'];

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<CommandNotifier>(context);
    final cmd = notifier.current;

    return SurroundingPanel(
      icon: Icons.gamepad,
      title: 'Input Control',
      showButton: true,
      panelType: 'Input Control',
      onSaveDefaultPressed: () => notifier.saveDefault(),
      onClearPressed: () => notifier.update(cmd.copyWith(
        keyboardMode: '',
        mouseMode: '',
        noControl: false,
        noMouseHover: false,
        legacyPaste: false,
        noKeyRepeat: false,
        rawKeyEvents: false,
        preferText: false,
        mouseBind: '',
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Keyboard Mode',
                  value: cmd.keyboardMode.isEmpty ? null : cmd.keyboardMode,
                  suggestions: keyboardModeOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(keyboardMode: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(keyboardMode: '')),
                  tooltip: 'Select how to send keyboard inputs: disabled, sdk (Android API), uhid (physical HID keyboard), or aoa (AOAv2 protocol, USB only).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Mouse Mode',
                  value: cmd.mouseMode.isEmpty ? null : cmd.mouseMode,
                  suggestions: mouseModeOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(mouseMode: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(mouseMode: '')),
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
                  value: cmd.noControl,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(noControl: val)),
                  tooltip: 'Disable device control (mirror the device in read-only).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Mouse Hover',
                  value: cmd.noMouseHover,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(noMouseHover: val)),
                  tooltip: 'Do not forward mouse hover (mouse motion without any clicks) events.',
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
                  value: cmd.legacyPaste,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(legacyPaste: val)),
                  tooltip: 'Inject computer clipboard text as a sequence of key events on Ctrl+v. This is a workaround for some devices not behaving as expected when setting the device clipboard programmatically.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Key Repeat',
                  value: cmd.noKeyRepeat,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(noKeyRepeat: val)),
                  tooltip: 'Do not forward repeated key events when a key is held down.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Raw Key Events',
                  value: cmd.rawKeyEvents,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(rawKeyEvents: val)),
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
                  value: cmd.preferText,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(preferText: val)),
                  tooltip: 'Inject alpha characters and space as text events instead of key events. This avoids issues when combining multiple keys to enter a special character, but breaks the expected behavior of alpha keys in games (typically WASD).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomSearchBar(
                  hintText: 'Mouse Bind (Button mapping)',
                  value: cmd.mouseBind.isEmpty ? null : cmd.mouseBind,
                  suggestions: mouseBindOptions,
                  onChanged: (val) =>
                      notifier.update(cmd.copyWith(mouseBind: val)),
                  onClear: () =>
                      notifier.update(cmd.copyWith(mouseBind: '')),
                  tooltip: 'Configure bindings of secondary mouse buttons. Format: PRIMARY:SECONDARY (4 chars each) for right, middle, 4th, 5th button. Each char: + (forward), - (ignore), b (BACK), h (HOME), s (APP_SWITCH), n (notifications). Example: ++++:++++ forwards all secondary clicks.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
