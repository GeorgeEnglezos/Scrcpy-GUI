import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:desktop_drop/desktop_drop.dart';
import '../services/app_icon_cache.dart';
import '../services/log_service.dart';
import '../services/settings_service.dart';
import '../services/terminal_service.dart';
import '../theme/app_colors.dart';

class ScriptFileGroup {
  final String groupName;
  final List<FileSystemEntity> files;
  final bool isRoot;

  ScriptFileGroup({
    required this.groupName,
    required this.files,
    this.isRoot = false,
  });
}

class ScriptsPage extends StatefulWidget {
  const ScriptsPage({super.key});

  @override
  State<ScriptsPage> createState() => _ScriptsPageState();
}

class _ScriptsPageState extends State<ScriptsPage> {
  static final RegExp _startAppArgPattern = RegExp(
    r'''(?:^|\s)-{1,2}start-app=(?:"([^"]+)"|'([^']+)'|([^\s]+))''',
    caseSensitive: false,
  );

  final SettingsService _settingsService = SettingsService();
  bool _isLoading = true;
  List<ScriptFileGroup> _batFileGroups = [];
  String _currentDirectory = '';
  bool _isDragging = false;
  final Map<String, String?> _scriptPackageByPath = {};
  final Map<String, File?> _scriptIconByPackage = {};

  // Get platform-specific script extensions
  List<String> get _scriptExtensions {
    if (Platform.isWindows) {
      return ['.bat', '.cmd'];
    } else if (Platform.isMacOS) {
      return ['.sh', '.command'];
    } else {
      // Linux
      return ['.sh'];
    }
  }

  // Check if a file is a script file
  bool _isScriptFile(String filePath) {
    final lowerPath = filePath.toLowerCase();
    return _scriptExtensions.any((ext) => lowerPath.endsWith(ext));
  }

  // Handle dropped files
  Future<void> _handleDroppedFiles(List<String> filePaths) async {
    if (_currentDirectory.isEmpty) return;

    int copiedCount = 0;
    int skippedCount = 0;
    List<String> errors = [];

    for (final filePath in filePaths) {
      try {
        // Check if it's a valid script file
        if (!_isScriptFile(filePath)) {
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
        LogService.error('ScriptsPage/dropFiles', 'Error copying ${path.basename(filePath)}', err: e);
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          backgroundColor: errors.isNotEmpty ? Colors.orange : Colors.green,
        ),
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
      final entities = await directory.list().toList();

      // Separate files in root and subdirectories
      final rootFiles = <FileSystemEntity>[];
      final subDirectories = <Directory>[];

      for (final entity in entities) {
        if (entity is File && _isScriptFile(entity.path)) {
          rootFiles.add(entity);
        } else if (entity is Directory) {
          subDirectories.add(entity);
        }
      }

      // Create groups
      final groups = <ScriptFileGroup>[];

      // Add root group if there are files in the main directory
      if (rootFiles.isNotEmpty) {
        rootFiles.sort((a, b) {
          final aName = path.basename(a.path).toLowerCase();
          final bName = path.basename(b.path).toLowerCase();
          return aName.compareTo(bName);
        });
        groups.add(
          ScriptFileGroup(groupName: 'Root', files: rootFiles, isRoot: true),
        );
      }

      // Add groups for each subdirectory
      for (final subDir in subDirectories) {
        final subDirFiles = await subDir
            .list()
            .where((entity) => entity is File && _isScriptFile(entity.path))
            .toList();

        if (subDirFiles.isNotEmpty) {
          subDirFiles.sort((a, b) {
            final aName = path.basename(a.path).toLowerCase();
            final bName = path.basename(b.path).toLowerCase();
            return aName.compareTo(bName);
          });

          groups.add(
            ScriptFileGroup(
              groupName: path.basename(subDir.path),
              files: subDirFiles,
              isRoot: false,
            ),
          );
        }
      }

      // Sort groups by name (root first, then alphabetically)
      groups.sort((a, b) {
        if (a.isRoot) return -1;
        if (b.isRoot) return 1;
        return a.groupName.toLowerCase().compareTo(b.groupName.toLowerCase());
      });

      setState(() {
        _batFileGroups = groups;
      });
      await _hydrateScriptIcons(groups);
    } catch (e) {
      LogService.error('ScriptsPage/loadScripts', 'Failed to load script files', err: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading script files: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _openFileLocation(String filePath) async {
    try {
      final directory = path.dirname(filePath);
      if (Platform.isWindows) {
        final normalized = directory.replaceAll('/', '\\');
        await Process.run('cmd', [
          '/c',
          'start',
          '',
          normalized,
        ], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [directory]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      }
    } catch (e) {
      LogService.error('ScriptsPage/openFileLocation', 'Failed to open location', err: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file location: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String? _extractStartAppPackage(String scriptText) {
    final match = _startAppArgPattern.firstMatch(scriptText);
    if (match == null) return null;
    return match.group(1) ?? match.group(2) ?? match.group(3);
  }

  String? _extractScriptPackage(FileSystemEntity entity) {
    if (entity is! File) return null;
    if (_scriptPackageByPath.containsKey(entity.path)) {
      return _scriptPackageByPath[entity.path];
    }
    try {
      final contents = entity.readAsStringSync();
      final packageName = _extractStartAppPackage(contents);
      _scriptPackageByPath[entity.path] = packageName;
      return packageName;
    } catch (_) {
      _scriptPackageByPath[entity.path] = null;
      return null;
    }
  }

  Future<void> _hydrateScriptIcons(List<ScriptFileGroup> groups) async {
    final packages = <String>{};
    for (final group in groups) {
      for (final entity in group.files) {
        final packageName = _extractScriptPackage(entity);
        if (packageName != null) {
          packages.add(packageName);
        }
      }
    }
    if (packages.isEmpty) return;

    var changed = false;
    for (final packageName in packages) {
      if (_scriptIconByPackage.containsKey(packageName)) continue;
      _scriptIconByPackage[packageName] =
          await AppIconCache.getCachedIconIfExists(packageName);
      changed = true;
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
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
                  Icon(Icons.terminal, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    Platform.isWindows ? 'Batch Scripts' : 'Shell Scripts',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _loadBatFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Refresh',
                      style: TextStyle(color: Colors.white),
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDragging
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDragging
              ? AppColors.primary
              : AppColors.textSecondary.withValues(alpha: 0.3),
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
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.7),
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
                    color: _isDragging ? AppColors.primary : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supported formats: $scriptTypes',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Files will be copied to: $_currentDirectory',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No script files found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Place script files ($scriptTypes) in:\n$_currentDirectory',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Or create subfolders to organize them into groups',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupPanel(ScriptFileGroup group) {
    return _buildFileList(group);
  }

  Widget _buildScriptIcon(File? iconFile) {
    if (iconFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          iconFile,
          width: 18,
          height: 18,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.insert_drive_file,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Icon(
      Icons.insert_drive_file,
      size: 18,
      color: AppColors.textSecondary,
    );
  }

  Widget _buildFileList(ScriptFileGroup group) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  group.isRoot ? Icons.folder_special : Icons.folder,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.groupName,
                    style: TextStyle(
                      color: AppColors.primary,
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

  Future<void> _openEditDialog(FileSystemEntity file) async {
    if (file is! File) return;

    String content;
    try {
      content = await file.readAsString();
    } catch (e) {
      LogService.error('ScriptsPage/editScript', 'Failed to read file', err: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    final fileName = path.basename(file.path);
    final nameController = TextEditingController(text: path.basenameWithoutExtension(file.path));
    final contentController = TextEditingController(text: content);
    final ext = path.extension(file.path);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit Script: $fileName',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File Name',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  suffixText: ext,
                  suffixStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Content',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: TextField(
                  controller: contentController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
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
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newContent = contentController.text;

              if (newName.isEmpty) return;

              try {
                // Rename if needed
                final newFileName = '$newName$ext';
                File targetFile = file;
                if (newFileName != fileName) {
                  final newPath = path.join(path.dirname(file.path), newFileName);
                  targetFile = await file.rename(newPath);
                  _scriptPackageByPath.remove(file.path);
                }

                // Write content
                await targetFile.writeAsString(newContent);

                if (ctx.mounted) Navigator.of(ctx).pop();
                await _loadBatFiles();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Script saved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                LogService.error('ScriptsPage/editScript', 'Failed to save script', err: e);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save: $e'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    nameController.dispose();
    contentController.dispose();
  }

  Widget _buildFileRow(FileSystemEntity file) {
    final fileName = path.basename(file.path);
    final packageName = _extractScriptPackage(file);
    final iconFile = packageName != null
        ? _scriptIconByPackage[packageName]
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildScriptIcon(iconFile),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Run script',
            child: ElevatedButton(
              onPressed: () => TerminalService.executeScriptFile(context, file.path, source: 'Scripts/RunScript'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: const Size(32, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _openEditDialog(file),
            icon: const Icon(Icons.edit, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'View / Edit script',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: () => _openFileLocation(file.path),
            icon: const Icon(Icons.folder_open, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'Open location',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
