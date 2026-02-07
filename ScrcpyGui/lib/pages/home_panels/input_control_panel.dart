/// Input control settings panel for keyboard and mouse configuration.
///
/// This panel provides configuration for input behavior including keyboard modes,
/// mouse bindings, click forwarding, and text injection preferences.
library;

import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:provider/provider.dart';

import '../../services/command_builder_service.dart';
import '../../theme/app_colors.dart';
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
  bool noControl = false;
  bool noMouseHover = false;
  bool forwardAllClicks = false;
  bool legacyPaste = false;
  bool noKeyRepeat = false;
  bool rawKeyEvents = false;
  bool preferText = false;
  String? mouseBind;
  String? keyboardMode;
  String? mouseMode;
  List<String> shortcutMod = [];

  final MultiSelectController<String> _shortcutModController =
      MultiSelectController<String>();

  final List<DropdownItem<String>> _shortcutModItems = [
    DropdownItem(label: 'lctrl', value: 'lctrl'),
    DropdownItem(label: 'rctrl', value: 'rctrl'),
    DropdownItem(label: 'lalt', value: 'lalt'),
    DropdownItem(label: 'ralt', value: 'ralt'),
    DropdownItem(label: 'lsuper', value: 'lsuper'),
    DropdownItem(label: 'rsuper', value: 'rsuper'),
  ];

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

  void _updateService(BuildContext context) {
    final cmdService = Provider.of<CommandBuilderService>(
      context,
      listen: false,
    );

    final options = cmdService.inputControlOptions.copyWith(
      keyboardMode: keyboardMode ?? '',
      mouseMode: mouseMode ?? '',
      noControl: noControl,
      noMouseHover: noMouseHover,
      forwardAllClicks: forwardAllClicks,
      legacyPaste: legacyPaste,
      noKeyRepeat: noKeyRepeat,
      rawKeyEvents: rawKeyEvents,
      preferText: preferText,
      mouseBind: mouseBind ?? '',
      shortcutMod: shortcutMod,
    );

    cmdService.updateInputControlOptions(options);

    debugPrint(
      '[InputControlPanel] Updated InputControlOptions → ${cmdService.fullCommand}',
    );
  }

  void _clearAllFields() {
    setState(() {
      keyboardMode = null;
      mouseMode = null;
      noControl = false;
      noMouseHover = false;
      forwardAllClicks = false;
      legacyPaste = false;
      noKeyRepeat = false;
      rawKeyEvents = false;
      preferText = false;
      mouseBind = null;
      shortcutMod = [];
    });
    _shortcutModController.clearAll();
    _updateService(context);
  }

  @override
  Widget build(BuildContext context) {
    return SurroundingPanel(
      icon: Icons.gamepad,
      title: 'Input Control',
      showButton: true,
      panelType: "Input Control",
      onClearPressed: _clearAllFields,
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
                  value: keyboardMode,
                  suggestions: keyboardModeOptions,
                  onChanged: (val) {
                    setState(() => keyboardMode = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => keyboardMode = null);
                    _updateService(context);
                  },
                  tooltip: 'Select how to send keyboard inputs: disabled, sdk (Android API), uhid (physical HID keyboard), or aoa (AOAv2 protocol, USB only).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSearchBar(
                  hintText: 'Mouse Mode',
                  value: mouseMode,
                  suggestions: mouseModeOptions,
                  onChanged: (val) {
                    setState(() => mouseMode = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => mouseMode = null);
                    _updateService(context);
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
                  value: noControl,
                  onChanged: (val) {
                    setState(() => noControl = val);
                    _updateService(context);
                  },
                  tooltip: 'Disable device control (mirror the device in read-only).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Mouse Hover',
                  value: noMouseHover,
                  onChanged: (val) {
                    setState(() => noMouseHover = val);
                    _updateService(context);
                  },
                  tooltip: 'Do not forward mouse hover (mouse motion without any clicks) events.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Forward All Clicks',
                  value: forwardAllClicks,
                  onChanged: (val) {
                    setState(() => forwardAllClicks = val);
                    _updateService(context);
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
                  value: legacyPaste,
                  onChanged: (val) {
                    setState(() => legacyPaste = val);
                    _updateService(context);
                  },
                  tooltip: 'Inject computer clipboard text as a sequence of key events on Ctrl+v. This is a workaround for some devices not behaving as expected when setting the device clipboard programmatically.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'No Key Repeat',
                  value: noKeyRepeat,
                  onChanged: (val) {
                    setState(() => noKeyRepeat = val);
                    _updateService(context);
                  },
                  tooltip: 'Do not forward repeated key events when a key is held down.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomCheckbox(
                  label: 'Raw Key Events',
                  value: rawKeyEvents,
                  onChanged: (val) {
                    setState(() => rawKeyEvents = val);
                    _updateService(context);
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
                  value: preferText,
                  onChanged: (val) {
                    setState(() => preferText = val);
                    _updateService(context);
                  },
                  tooltip: 'Inject alpha characters and space as text events instead of key events. This avoids issues when combining multiple keys to enter a special character, but breaks the expected behavior of alpha keys in games (typically WASD).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomSearchBar(
                  hintText: 'Mouse Bind (Button mapping)',
                  value: mouseBind,
                  suggestions: mouseBindOptions,
                  onChanged: (val) {
                    setState(() => mouseBind = val);
                    _updateService(context);
                  },
                  onClear: () {
                    setState(() => mouseBind = null);
                    _updateService(context);
                  },
                  tooltip: 'Configure bindings of secondary clicks. Each character maps a mouse button: + (forward), - (ignore), b (BACK), h (HOME), s (APP_SWITCH), n (notifications).',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Select one or more modifier keys used for scrcpy shortcuts (e.g. lctrl+rctrl). Defaults to left Alt or left Super if not set.',
                  child: MultiDropdown<String>(
              items: _shortcutModItems,
              controller: _shortcutModController,
              onSelectionChange: (selected) {
                setState(() {
                  shortcutMod = selected.toList();
                });
                _updateService(context);
              },
              fieldDecoration: FieldDecoration(
                hintText: 'Shortcut Mod Key',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                backgroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              dropdownDecoration: DropdownDecoration(
                backgroundColor: AppColors.surface,
                maxHeight: 250,
                borderRadius: BorderRadius.circular(8),
              ),
              dropdownItemDecoration: DropdownItemDecoration(
                selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.15),
                textColor: Colors.white70,
                selectedTextColor: Colors.white,
              ),
              chipDecoration: ChipDecoration(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                borderRadius: BorderRadius.circular(6),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                spacing: 6,
                runSpacing: 6,
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
