import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../services/log_service.dart';
import '../theme/app_colors.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  // null = live session view
  String? _selectedLogFile;
  String? _selectedLogContent;
  List<File> _logFiles = [];
  bool _loadingFile = false;

  @override
  void initState() {
    super.initState();
    _refreshFileList();
  }

  Future<void> _refreshFileList() async {
    final dir = LogService.logFolderPath;
    if (dir == null) return;
    final d = Directory(dir);
    if (!await d.exists()) return;

    final files = await d
        .list()
        .where((e) => e is File && p.basename(e.path).startsWith('session_'))
        .cast<File>()
        .toList();

    files.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));

    if (mounted) setState(() => _logFiles = files);
  }

  Future<void> _selectFile(File file) async {
    setState(() {
      _selectedLogFile = file.path;
      _loadingFile = true;
      _selectedLogContent = null;
    });
    final content = await file.readAsString();
    if (mounted) {
      setState(() {
        _selectedLogContent = content;
        _loadingFile = false;
      });
    }
  }

  void _selectLive() {
    setState(() {
      _selectedLogFile = null;
      _selectedLogContent = null;
    });
  }

  String _friendlyName(String path) {
    final base = p.basenameWithoutExtension(path);
    // session_2026-03-22_14-05-30 → 2026-03-22 14:05:30
    return base
        .replaceFirst('session_', '')
        .replaceFirst('_', ' ')
        .replaceAllMapped(RegExp(r'(\d{2})-(\d{2})-(\d{2})$'), (m) => '${m[1]}:${m[2]}:${m[3]}');
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.white70;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LogService>();
    final liveEntries = LogService.entries;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Logs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_selectedLogFile == null)
                IconButton(
                  onPressed: LogService.clear,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear current session logs',
                ),
              if (_selectedLogContent != null)
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _selectedLogContent!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy log to clipboard',
                ),
              IconButton(
                onPressed: _refreshFileList,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh file list',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Body: file list + content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: file list ─────────────────────────────────────────
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live session entry
                      _FileListTile(
                        label: 'Current session',
                        icon: Icons.circle,
                        iconColor: Colors.greenAccent,
                        selected: _selectedLogFile == null,
                        onTap: _selectLive,
                      ),
                      const SizedBox(height: 4),
                      const Divider(),
                      const SizedBox(height: 4),
                      if (_logFiles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'No saved logs',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _logFiles.length,
                            itemBuilder: (context, i) {
                              final file = _logFiles[i];
                              return _FileListTile(
                                label: _friendlyName(file.path),
                                icon: Icons.description_outlined,
                                selected: _selectedLogFile == file.path,
                                onTap: () => _selectFile(file),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),
                const VerticalDivider(),
                const SizedBox(width: 16),

                // ── Right: content ───────────────────────────────────────────
                Expanded(
                  child: _selectedLogFile == null
                      ? _LiveView(entries: liveEntries, levelColor: _levelColor)
                      : _loadingFile
                          ? const Center(child: CircularProgressIndicator())
                          : _FileView(content: _selectedLogContent ?? ''),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _FileListTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool selected;
  final VoidCallback onTap;

  const _FileListTile({
    required this.label,
    required this.icon,
    this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: iconColor ?? AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveView extends StatefulWidget {
  final List<LogEntry> entries;
  final Color Function(LogLevel) levelColor;

  const _LiveView({required this.entries, required this.levelColor});

  @override
  State<_LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<_LiveView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_LiveView old) {
    super.didUpdateWidget(old);
    if (widget.entries.length != old.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return const Center(
        child: Text(
          'No logs yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      itemCount: widget.entries.length,
      itemBuilder: (context, index) {
        final e = widget.entries[index];
        final ts = e.timestamp
            .toIso8601String()
            .replaceFirst('T', ' ')
            .substring(0, 23);
        final color = widget.levelColor(e.level);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ts,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '[${e.level.name.toUpperCase().padRight(5)}]',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${e.source}:',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  e.message,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FileView extends StatelessWidget {
  final String content;

  const _FileView({required this.content});

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) {
      return const Center(
        child: Text(
          'Empty log file.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      child: SelectableText(
        content,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: Colors.white70,
        ),
      ),
    );
  }
}
