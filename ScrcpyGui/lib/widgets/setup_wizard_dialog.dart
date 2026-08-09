/// First-run setup wizard.
///
/// Three steps: resolve scrcpy, choose directories, pick a theme. Skippable at
/// every step, and both Skip and Finish mark setup complete so it does not
/// reopen.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/settings_model.dart';
import '../services/adb_service.dart';
import '../services/color_theme_notifier.dart';
import '../services/shell_runner.dart';
import '../services/update_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_colors.dart';
import 'app_snackbar.dart';
import 'custom_dropdown.dart';
import 'directory_row.dart';

/// Where step 1 sends a user who has no scrcpy yet. The /latest redirect means
/// this never needs updating when scrcpy releases.
const kScrcpyReleasesUrl =
    'https://github.com/Genymobile/scrcpy/releases/latest';

/// The host platform, as far as the install hint is concerned.
enum HostOs { windows, macos, linux }

HostOs get currentHostOs => Platform.isWindows
    ? HostOs.windows
    : Platform.isMacOS
        ? HostOs.macos
        : HostOs.linux;

/// Package-manager commands that install scrcpy, plus a caveat to show under
/// them.
class ScrcpyInstallHint {
  /// Shell lines, shown in a copyable block in the order given.
  final List<String> commands;

  /// Caveat shown beneath the block.
  final String note;

  /// What the "Run in terminal" button executes, or null when running the
  /// listed commands is not safe to automate.
  ///
  /// Null on Linux specifically: the lines there are alternatives for
  /// different distributions, so running them in sequence would fire the wrong
  /// package manager. The user copies the one that matches their system.
  final String? runnable;

  const ScrcpyInstallHint({
    required this.commands,
    required this.note,
    this.runnable,
  });

  String get copyText => commands.join('\n');
}

/// Install commands for [os], copied verbatim from `Official-docs/`.
///
/// Taken from the docs rather than from memory, which matters here: upstream
/// strikes through both the Debian/Ubuntu apt package and the snap as obsolete
/// versions, so neither is offered. WinGet's flag is `--exact`, not `--id`.
ScrcpyInstallHint scrcpyInstallHint(HostOs os) {
  switch (os) {
    case HostOs.windows:
      return const ScrcpyInstallHint(
        commands: ['winget install --exact Genymobile.scrcpy'],
        note: 'WinGet installs adb alongside scrcpy.',
        runnable: 'winget install --exact Genymobile.scrcpy',
      );
    case HostOs.macos:
      return const ScrcpyInstallHint(
        commands: [
          'brew install scrcpy',
          'brew install --cask android-platform-tools',
        ],
        note: 'The second line installs adb, which scrcpy needs on PATH.',
        runnable:
            'brew install scrcpy && brew install --cask android-platform-tools',
      );
    case HostOs.linux:
      return const ScrcpyInstallHint(
        commands: [
          'pacman -S scrcpy',
          'dnf copr enable zeno/scrcpy && dnf install scrcpy',
        ],
        note: 'One line per distribution, Arch then Fedora, so copy the one '
            'that matches yours rather than running both. On Debian and '
            'Ubuntu the apt package is obsolete upstream, so use the manual '
            'download instead.',
      );
  }
}

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
  bool _scrcpyChecked = false;

  /// Null while the probe is still running, which the adb status line renders
  /// as "Checking adb...". This is deliberately its own gate: adb can take up
  /// to 10 seconds to time out on a machine that has none, and that should
  /// not block the scrcpy Browse row above it.
  AdbStatus? _adbStatus;

  /// Set when the picked folder holds no scrcpy executable.
  String? _scrcpyDirError;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _checkScrcpyOnPath();
    _checkAdb();
  }

  Future<void> _checkScrcpyOnPath() async {
    final onPath = await AdbService.isScrcpyOnPath();
    if (!mounted) return;
    setState(() {
      _scrcpyOnPath = onPath;
      _scrcpyChecked = true;
    });
  }

  Future<void> _checkAdb() async {
    final adb = await AdbService.checkAdb();
    if (!mounted) return;
    setState(() => _adbStatus = adb);
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

    final found = await AdbService.hasScrcpyIn(result);
    if (!mounted) return;

    if (!found) {
      final exeName = Platform.isWindows ? 'scrcpy.exe' : 'scrcpy';
      // Report the failure but do not persist it: AdbService.adbExecutable
      // derives adb's path from scrcpyDirectory too, so saving a wrong
      // folder here would also break adb resolution.
      setState(() => _scrcpyDirError = 'No $exeName in that folder.');
      return;
    }

    setState(() {
      _scrcpyDirError = null;
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
      // Scrollable because step 1 grows: with scrcpy missing it gains the
      // install block, the download button and the Browse row, which overflows
      // a short window.
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(child: _buildStepBody()),
      ),
      actions: [
        // Skips this step only, never the wizard. Hidden on the last step,
        // where skipping and finishing would be the same action.
        if (!isLastStep)
          TextButton(
            onPressed: () => setState(() => _step++),
            child: const Text('Skip this step'),
          ),
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
    if (!_scrcpyChecked) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final scrcpyDirError = _scrcpyDirError;
    final adbReachable = _adbStatus?.reachable == true;

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
            'scrcpy is not on your system PATH. Download it, or choose the '
            'folder holding a copy you already have.',
          ),
          const SizedBox(height: 16),
          _buildInstallPanel(),
          const SizedBox(height: 16),
          DirectoryRow(
            label: 'Scrcpy Directory',
            path: _settings.scrcpyDirectory.isEmpty
                ? '(not set)'
                : _settings.scrcpyDirectory,
            showOpenButton: false,
            onBrowse: _pickScrcpyDirectory,
          ),
          if (scrcpyDirError != null) ...[
            const SizedBox(height: 8),
            _statusLine(
              Icons.warning_amber_rounded,
              AppColors.error,
              scrcpyDirError,
            ),
          ],
        ],
        const SizedBox(height: 12),
        _statusLine(
          adbReachable ? Icons.check_circle : Icons.info_outline,
          // adb is informational and never blocks progress, so it never uses
          // the error color, not even while still checking or not found.
          adbReachable ? AppColors.runGreen : context.appTextSecondary,
          _adbStatusLabel,
        ),
      ],
    );
  }

  /// Both ways to get scrcpy, boxed together so step 1 reads as one choice
  /// rather than a pile of loose controls.
  Widget _buildInstallPanel() {
    final hint = scrcpyInstallHint(currentHostOs);
    final runnable = hint.runnable;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: context.appDivider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.download_for_offline_outlined,
                  size: 18, color: context.appPrimary),
              const SizedBox(width: 8),
              Text(
                'Install scrcpy',
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _optionLabel('Option 1: Manual download'),
          const SizedBox(height: 6),
          _hint('Grab the latest release, extract it, then point the folder '
              'below at it.'),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () =>
                  UpdateService.launchReleasePage(kScrcpyReleasesUrl),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Get scrcpy'),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: context.appDivider, height: 1),
          const SizedBox(height: 16),
          _optionLabel('Option 2: Run a command'),
          const SizedBox(height: 8),
          _buildCommandBlock(hint),
          const SizedBox(height: 6),
          _hint(hint.note),
          if (runnable != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _runInstallCommand(runnable),
                  icon: const Icon(Icons.terminal, size: 18),
                  label: const Text('Run in terminal'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _checkScrcpyOnPath,
                  child: const Text('Check again'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionLabel(String text) => Text(
        text,
        style: TextStyle(
          color: context.appTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  /// Opens a terminal running [command]. The terminal stays open so the user
  /// can see the package manager's output and answer any prompt it raises.
  Future<void> _runInstallCommand(String command) async {
    await ShellRunner.runCommandInNewTerminal(command);
    if (!mounted) return;
    showAppSnackBar(
      context,
      'Opened a terminal. Press Check again once it finishes.',
      type: AppSnackBarType.info,
    );
  }

  Widget _buildCommandBlock(ScrcpyInstallHint hint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: context.appCommandSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              hint.copyText,
              style: TextStyle(
                color: context.appTextPrimary,
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            color: context.appTextSecondary,
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: hint.copyText));
              showAppSnackBar(
                context,
                'Install command copied',
                type: AppSnackBarType.neutral,
              );
            },
          ),
        ],
      ),
    );
  }

  String get _adbStatusLabel {
    final status = _adbStatus;
    if (status == null) return 'Checking adb...';
    if (!status.reachable) return 'adb not found';
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

/// Shows the wizard once after the first frame when [enabled], then renders
/// [child] untouched either way.
///
/// Mounted inside `MaterialApp.home` rather than `MaterialApp.builder`:
/// `builder` inserts widgets above the Navigator, so a context taken there has
/// no Navigator ancestor and showDialog throws.
class SetupWizardGate extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const SetupWizardGate({
    super.key,
    required this.enabled,
    required this.child,
  });

  @override
  State<SetupWizardGate> createState() => _SetupWizardGateState();
}

class _SetupWizardGateState extends State<SetupWizardGate> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _opened) return;
      _opened = true;
      showSetupWizard(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Opens the setup wizard, resolving its starting settings first.
///
/// The only entry point: used by [SetupWizardGate] on first run and by the
/// "Run Setup Again" button in Settings.
Future<void> showSetupWizard(BuildContext context) async {
  final service = SettingsService();
  final settingsDir = await service.getSettingsDirectory();
  final settings = SettingsService.withDirectoryDefaults(
    SettingsService.currentSettings ?? AppSettings.defaultSettings(),
    settingsDir,
  );
  if (!context.mounted) return;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SetupWizardDialog(
      initialSettings: settings,
      onSave: (updated) => service.saveSettings(updated),
    ),
  );
}
