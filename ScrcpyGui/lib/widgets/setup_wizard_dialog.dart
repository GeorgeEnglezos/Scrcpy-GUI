/// First-run setup wizard.
///
/// Three steps: resolve scrcpy, choose directories, pick a theme. Skippable at
/// every step, and both Skip and Finish mark setup complete so it does not
/// reopen.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/settings_model.dart';
import '../services/adb_service.dart';
import '../services/color_theme_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_colors.dart';
import 'custom_dropdown.dart';
import 'directory_row.dart';

class SetupWizardDialog extends StatefulWidget {
  /// Settings the wizard starts from, with directory defaults already applied
  /// by the caller. Passed in rather than read from the service so the dialog
  /// needs no disk access to open.
  final AppSettings initialSettings;

  /// Persists a change. Injected so widget tests do not write to the real
  /// settings file.
  final Future<void> Function(AppSettings) onSave;

  const SetupWizardDialog({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  @override
  State<SetupWizardDialog> createState() => _SetupWizardDialogState();
}

class _SetupWizardDialogState extends State<SetupWizardDialog> {
  static const _stepCount = 3;

  int _step = 0;
  late AppSettings _settings;

  bool _scrcpyOnPath = false;
  bool _toolsChecked = false;
  AdbStatus? _adbStatus;

  /// Set when the picked folder holds no scrcpy executable.
  String? _scrcpyDirError;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _checkTools();
  }

  Future<void> _checkTools() async {
    final onPath = await AdbService.isScrcpyOnPath();
    final adb = await AdbService.checkAdb();
    if (!mounted) return;
    setState(() {
      _scrcpyOnPath = onPath;
      _adbStatus = adb;
      _toolsChecked = true;
    });
  }

  Future<void> _save() => widget.onSave(_settings);

  /// Closes the wizard, recording that setup is done. Skip and Finish both
  /// land here: a user who dismissed it does not want it back next launch.
  Future<void> _close() async {
    final navigator = Navigator.of(context);
    _settings = _settings.copyWith(setupCompleted: true);
    await widget.onSave(_settings);
    navigator.pop();
  }

  Future<void> _pickScrcpyDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;

    final exeName = Platform.isWindows ? 'scrcpy.exe' : 'scrcpy';
    final found = await File(p.join(result, exeName)).exists();
    if (!mounted) return;

    setState(() {
      _scrcpyDirError = found ? null : 'No $exeName in that folder.';
      _settings = _settings.copyWith(scrcpyDirectory: result);
    });
    await _save();
  }

  /// Picks a directory and folds it into the settings via [apply].
  Future<void> _pickInto(AppSettings Function(String) apply) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null || !mounted) return;

    setState(() => _settings = apply(result));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _step == _stepCount - 1;

    return AlertDialog(
      backgroundColor: context.appSurface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welcome to Scrcpy GUI',
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Step ${_step + 1} of $_stepCount',
                style: TextStyle(color: context.appTextSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_step + 1) / _stepCount,
            color: context.appPrimary,
            backgroundColor: context.appDivider,
          ),
        ],
      ),
      content: SizedBox(width: 520, child: _buildStepBody()),
      actions: [
        TextButton(onPressed: _close, child: const Text('Skip')),
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text('Back'),
          ),
        ElevatedButton(
          onPressed: isLastStep ? _close : () => setState(() => _step++),
          child: Text(isLastStep ? 'Finish' : 'Next'),
        ),
      ],
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return _buildScrcpyStep();
      case 1:
        return _buildDirectoriesStep();
      default:
        return _buildThemeStep();
    }
  }

  Widget _buildScrcpyStep() {
    if (!_toolsChecked) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _hint('Scrcpy GUI runs the scrcpy executable, so it needs to know '
            'where that is.'),
        const SizedBox(height: 16),
        if (_scrcpyOnPath)
          _statusLine(
            Icons.check_circle,
            AppColors.runGreen,
            'scrcpy found on your system PATH',
          )
        else ...[
          _statusLine(
            Icons.error_outline,
            AppColors.error,
            'scrcpy is not on your system PATH. Choose the folder holding it.',
          ),
          const SizedBox(height: 16),
          DirectoryRow(
            label: 'Scrcpy Directory',
            path: _settings.scrcpyDirectory.isEmpty
                ? '(not set)'
                : _settings.scrcpyDirectory,
            showOpenButton: false,
            onBrowse: _pickScrcpyDirectory,
          ),
          if (_scrcpyDirError != null) ...[
            const SizedBox(height: 8),
            _statusLine(
              Icons.warning_amber_rounded,
              AppColors.error,
              _scrcpyDirError!,
            ),
          ],
        ],
        const SizedBox(height: 12),
        _statusLine(
          _adbStatus?.reachable == true
              ? Icons.check_circle
              : Icons.info_outline,
          _adbStatus?.reachable == true ? AppColors.runGreen : AppColors.error,
          _adbStatusLabel,
        ),
      ],
    );
  }

  String get _adbStatusLabel {
    final status = _adbStatus;
    if (status == null || !status.reachable) return 'adb not found';
    if (status.deviceCount == 0) return 'adb responding, no devices connected';
    if (status.deviceCount == 1) return 'adb responding, 1 device connected';
    return 'adb responding, ${status.deviceCount} devices connected';
  }

  Widget _buildDirectoriesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _hint('Where Scrcpy GUI keeps the files it creates. These are '
            'pre-filled, and all of them can be changed later in Settings.'),
        const SizedBox(height: 16),
        DirectoryRow(
          label: 'Downloads Directory (generated scripts)',
          path: _settings.downloadsDirectory,
          showOpenButton: false,
          onBrowse: () => _pickInto(
            (path) => _settings.copyWith(downloadsDirectory: path),
          ),
        ),
        const SizedBox(height: 16),
        DirectoryRow(
          label: Platform.isWindows
              ? 'Scripts Directory (.bat, .cmd)'
              : 'Scripts Directory (.sh${Platform.isMacOS ? ', .command' : ''})',
          path: _settings.batDirectory,
          showOpenButton: false,
          onBrowse: () =>
              _pickInto((path) => _settings.copyWith(batDirectory: path)),
        ),
        const SizedBox(height: 16),
        DirectoryRow(
          label: 'Recordings Directory',
          path: _settings.recordingsDirectory,
          showOpenButton: false,
          onBrowse: () => _pickInto(
            (path) => _settings.copyWith(recordingsDirectory: path),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeStep() {
    final themeNotifier = context.watch<ColorThemeNotifier>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _hint('Pick a color theme. It applies as soon as you choose it.'),
        const SizedBox(height: 16),
        CustomDropdown(
          label: 'Color Theme',
          value: themeNotifier.current.name,
          items: themeNotifier.presets.map((preset) => preset.name).toList(),
          onChanged: (value) {
            if (value == null) return;
            context.read<ColorThemeNotifier>().setPreset(value);
            setState(() => _settings = _settings.copyWith(colorPreset: value));
            _save();
          },
        ),
      ],
    );
  }

  Widget _hint(String text) => Text(
        text,
        style: TextStyle(color: context.appTextSecondary, fontSize: 13),
      );

  Widget _statusLine(IconData icon, Color color, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: context.appTextPrimary, fontSize: 13),
            ),
          ),
        ],
      );
}
