import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../widgets/app_snackbar.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../services/log_service.dart';
import '../services/script_repository.dart';
import '../services/settings_service.dart';
import '../services/shell_runner.dart';
import '../utils/command_executor.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/package_icon.dart';

class ScriptsPage extends StatefulWidget {
  const ScriptsPage({super.key});

  @override
  State<ScriptsPage> createState() => _ScriptsPageState();
}

class _ScriptsPageState extends State<ScriptsPage> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  List<ScriptGroup> _batFileGroups = [];
  String _currentDirectory = '';
  bool _isDragging = false;
  final Map<String, String?> _scriptPackageByPath = {};
  final Map<String, File?> _scriptIconByPackage = {};

  List<String> get _scriptExtensions => ScriptRepository.scriptExtensions;

  // Handle dropped files
  Future<void> _handleDroppedFiles(List<String> filePaths) async {
    if (_currentDirectory.isEmpty) return;

    int copiedCount = 0;
    int skippedCount = 0;
    List<String> errors = [];

    for (final filePath in filePaths) {
      try {
        // Check if it's a valid script file
        if (!ScriptRepository.isScriptFile(filePath)) {
          skippedCount++;
          continue;
        }

        final sourceFile = File(filePath);
        if (!await sourceFile.exists()) {
          errors.add('File not found: ${path.basename(filePath)}');
          continue;
        }

        // Copy to scripts directory
        final fileName = path.basename(filePath);
        final targetPath = path.join(_currentDirectory, fileName);
        final targetFile = File(targetPath);

        // Check if file already exists
        if (await targetFile.exists()) {
          errors.add('Already exists: $fileName');
          skippedCount++;
          continue;
        }

        await sourceFile.copy(targetPath);
        copiedCount++;
      } catch (e) {
        LogService.error(
          'ScriptsPage/dropFiles',
          'Error copying ${path.basename(filePath)}',
          err: e,
        );
        errors.add('Error copying ${path.basename(filePath)}: $e');
      }
    }

    // Show result
    if (mounted) {
      String message = '';
      if (copiedCount > 0) {
        message += '$copiedCount file(s) copied successfully';
      }
      if (skippedCount > 0) {
        if (message.isNotEmpty) message += '\n';
        message += '$skippedCount file(s) skipped';
      }
      if (errors.isNotEmpty) {
        if (message.isNotEmpty) message += '\n';
        message += errors.join('\n');
      }

      showAppSnackBar(
        context,
        message,
        type: errors.isNotEmpty
            ? AppSnackBarType.warning
            : AppSnackBarType.success,
      );

      // Refresh the file list
      if (copiedCount > 0) {
        await _loadBatFiles();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _currentDirectory = settings.batDirectory;
      _isLoading = false;
    });
    await _loadBatFiles();
  }

  Future<void> _loadBatFiles() async {
    if (_currentDirectory.isEmpty) return;

    final directory = Directory(_currentDirectory);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    try {
      final groups = await ScriptRepository.loadGroups(_currentDirectory);
      setState(() {
        _batFileGroups = groups;
      });
      await _hydrateScriptIcons(groups);
    } catch (e) {
      LogService.error(
        'ScriptsPage/loadScripts',
        'Failed to load script files',
        err: e,
      );
      if (mounted) {
        showAppSnackBar(
          context,
          'Error loading script files: $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  Future<void> _openFileLocation(String filePath) async {
    try {
      await ShellRunner.openFolder(path.dirname(filePath));
    } catch (e) {
      LogService.error(
        'ScriptsPage/openFileLocation',
        'Failed to open location',
        err: e,
      );
      if (mounted) {
        showAppSnackBar(
          context,
          'Failed to open file location: $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  String? _extractScriptPackage(File file) =>
      ScriptRepository.packageForScript(file, _scriptPackageByPath);

  Future<void> _hydrateScriptIcons(List<ScriptGroup> groups) async {
    final packages = <String>{};
    for (final group in groups) {
      for (final file in group.files) {
        final packageName = _extractScriptPackage(file);
        if (packageName != null) {
          packages.add(packageName);
        }
      }
    }
    if (packages.isEmpty) return;

    final changed = await ScriptRepository.hydrateCachedIcons(
      packages,
      _scriptIconByPackage,
    );
    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      body: DropTarget(
        onDragEntered: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onDragExited: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        onDragDone: (details) {
          setState(() {
            _isDragging = false;
          });
          final filePaths = details.files.map((file) => file.path).toList();
          _handleDroppedFiles(filePaths);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Header with refresh button
              Row(
                children: [
                  Icon(Icons.terminal, color: context.appPrimary, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    Platform.isWindows ? 'Batch Scripts' : 'Shell Scripts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _loadBatFiles,
                    icon: Icon(Icons.refresh, color: context.appOnPrimary),
                    label: Text(
                      'Refresh',
                      style: TextStyle(color: context.appOnPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Drag and drop zone
              _buildDropZone(),
              const SizedBox(height: 24),
              // Groups
              if (_batFileGroups.isEmpty)
                _buildEmptyState()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Determine number of columns based on available width
                    int crossAxisCount;
                    if (constraints.maxWidth >= 1400) {
                      crossAxisCount = 3; // 3 columns for very wide screens
                    } else if (constraints.maxWidth >= 900) {
                      crossAxisCount = 2; // 2 columns for medium-wide screens
                    } else {
                      crossAxisCount = 1; // 1 column for narrow screens
                    }

                    // Create rows of panels
                    final rows = <Widget>[];
                    for (
                      int i = 0;
                      i < _batFileGroups.length;
                      i += crossAxisCount
                    ) {
                      final rowItems = <Widget>[];
                      for (
                        int j = 0;
                        j < crossAxisCount && (i + j) < _batFileGroups.length;
                        j++
                      ) {
                        rowItems.add(
                          Expanded(
                            child: _buildGroupPanel(_batFileGroups[i + j]),
                          ),
                        );
                      }

                      // Fill remaining space if last row is incomplete
                      while (rowItems.length < crossAxisCount) {
                        rowItems.add(const Expanded(child: SizedBox.shrink()));
                      }

                      rows.add(
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i + crossAxisCount < _batFileGroups.length
                                ? 24
                                : 0,
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (
                                  int idx = 0;
                                  idx < rowItems.length;
                                  idx++
                                ) ...[
                                  rowItems[idx],
                                  if (idx < rowItems.length - 1)
                                    const SizedBox(width: 24),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(children: rows);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropZone() {
    final scriptTypes = _scriptExtensions.join(', ');
    final textColor = context.appTextSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDragging
            ? context.appPrimary.withValues(alpha: 0.2)
            : context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDragging
              ? context.appPrimary
              : textColor.withValues(alpha: 0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isDragging ? Icons.file_download : Icons.file_upload,
            size: 48,
            color: _isDragging
                ? context.appPrimary
                : textColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isDragging
                      ? 'Drop files here to copy them'
                      : 'Drag & Drop Scripts Here',
                  style: TextStyle(
                    color: _isDragging
                        ? context.appPrimary
                        : context.appTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supported formats: $scriptTypes',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Files will be copied to: $_currentDirectory',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final scriptTypes = _scriptExtensions.join(', ');
    final textColor = context.appTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No script files found',
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Place script files ($scriptTypes) in:\n$_currentDirectory',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Or create subfolders to organize them into groups',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupPanel(ScriptGroup group) {
    return _buildFileList(group);
  }

  Widget _buildFileList(ScriptGroup group) {
    final textColor = context.appTextSecondary;
    return Container(
      decoration: BoxDecoration(
        color: context.appInputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  group.isRoot ? Icons.folder_special : Icons.folder,
                  color: context.appPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.name,
                    style: TextStyle(
                      color: context.appPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(group.files.length, (index) {
            return _buildFileRow(group.files[index]);
          }),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(File file) async {
    String content;
    try {
      content = await file.readAsString();
    } catch (e) {
      LogService.error('ScriptsPage/editScript', 'Failed to read file', err: e);
      if (mounted) {
        showAppSnackBar(
          context,
          'Failed to read file: $e',
          type: AppSnackBarType.error,
        );
      }
      return;
    }

    final fileName = path.basename(file.path);
    final nameController = TextEditingController(
      text: path.basenameWithoutExtension(file.path),
    );
    final contentController = TextEditingController(text: content);
    final ext = path.extension(file.path);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Edit Script: $fileName',
          style: TextStyle(color: context.appTextPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Name',
                style: TextStyle(color: context.appTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: TextStyle(color: context.appTextPrimary),
                decoration: InputDecoration(
                  suffixText: ext,
                  suffixStyle: TextStyle(color: context.appTextSecondary),
                  filled: true,
                  fillColor: context.appInputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Content',
                style: TextStyle(color: context.appTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: TextField(
                  controller: contentController,
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  maxLines: null,
                  expands: true,
                  // An expanding field is centred by its InputDecorator, which
                  // leaves a short script floating in the middle of the box.
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.appInputFill,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newContent = contentController.text;

              if (newName.isEmpty) return;

              try {
                // Rename if needed
                final newFileName = '$newName$ext';
                File targetFile = file;
                if (newFileName != fileName) {
                  final newPath = path.join(
                    path.dirname(file.path),
                    newFileName,
                  );
                  targetFile = await file.rename(newPath);
                  _scriptPackageByPath.remove(file.path);
                }

                // Write content
                await targetFile.writeAsString(newContent);

                if (ctx.mounted) Navigator.of(ctx).pop();
                await _loadBatFiles();

                if (mounted) {
                  showAppSnackBar(
                    context,
                    'Script saved successfully',
                    type: AppSnackBarType.success,
                  );
                }
              } catch (e) {
                LogService.error(
                  'ScriptsPage/editScript',
                  'Failed to save script',
                  err: e,
                );
                if (ctx.mounted) {
                  showAppSnackBar(
                    ctx,
                    'Failed to save: $e',
                    type: AppSnackBarType.error,
                  );
                }
              }
            },
            child: Text('Save', style: TextStyle(color: context.appOnPrimary)),
          ),
        ],
      ),
    );

    nameController.dispose();
    contentController.dispose();
  }

  Widget _buildFileRow(File file) {
    final fileName = path.basename(file.path);
    final packageName = _extractScriptPackage(file);
    final iconFile = packageName != null
        ? _scriptIconByPackage[packageName]
        : null;
    final textColor = context.appTextSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: textColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          PackageIcon(iconFile: iconFile, fallbackIcon: Icons.insert_drive_file),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(color: textColor, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Run script',
            child: ElevatedButton(
              onPressed: () => CommandExecutor.executeScriptFile(
                context,
                file.path,
                source: 'Scripts/RunScript',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: const Size(32, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Icon(
                Icons.play_arrow,
                size: 16,
                color: context.appOnPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _openEditDialog(file),
            icon: const Icon(Icons.edit, size: 18),
            color: textColor,
            tooltip: 'View / Edit script',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: () => _openFileLocation(file.path),
            icon: const Icon(Icons.folder_open, size: 18),
            color: textColor,
            tooltip: 'Open location',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
