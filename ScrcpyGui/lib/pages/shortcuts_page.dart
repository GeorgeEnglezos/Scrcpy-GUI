/// Shortcuts page displaying the official scrcpy keyboard shortcuts.
///
/// Fetches the shortcuts markdown from the scrcpy repository and renders
/// it using [Markdown] from flutter_markdown_plus. The content is cached
/// locally for offline access and refreshed in the background once per
/// app session.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../services/shortcuts_service.dart';
import '../theme/app_colors.dart';

class ShortcutsPage extends StatefulWidget {
  const ShortcutsPage({super.key});

  @override
  State<ShortcutsPage> createState() => _ShortcutsPageState();
}

class _ShortcutsPageState extends State<ShortcutsPage> {
  final ShortcutsService _service = ShortcutsService();
  String? _markdown;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    // Try loading from cache first for instant display
    final cached = await _service.getCachedMarkdown();
    if (cached != null && mounted) {
      setState(() {
        _markdown = cached;
        _loading = false;
      });
    }

    // Refresh from network once per session
    if (!_service.hasRefreshedThisSession) {
      _service.markRefreshed();
      final fresh = await _service.fetchAndCache();
      if (mounted) {
        if (fresh != null) {
          setState(() {
            _markdown = fresh;
            _loading = false;
          });
        } else if (_markdown == null) {
          // No cache and no network
          setState(() {
            _loading = false;
            _error = 'Could not load shortcuts. Check your internet connection.';
          });
        }
      }
    } else if (_markdown == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load shortcuts. Check your internet connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header matching Resources page style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.keyboard,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Scrcpy Keyboard & Mouse Shortcuts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null && _markdown == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _service.markRefreshed();
                _loadContent();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final styleSheet = MarkdownStyleSheet(
      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
      h3: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
      h4: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
      p: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
      a: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline),
      code: TextStyle(
        fontSize: 13,
        color: AppColors.primaryLight,
        backgroundColor: AppColors.surface,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      tableHead: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      tableBody: const TextStyle(color: Colors.white70),
      tableBorder: TableBorder.all(color: AppColors.divider),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      blockquote: const TextStyle(color: AppColors.textSecondary),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      listBullet: const TextStyle(color: Colors.white70),
      strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      em: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
      blockSpacing: 12,
    );

    // Convert <kbd>X</kbd> HTML tags to inline code since flutter_markdown
    // doesn't render arbitrary HTML elements.
    final processed = _markdown!.replaceAllMapped(
      RegExp(r'<kbd>(.*?)</kbd>'),
      (match) => '`${match.group(1)}`',
    );

    return Markdown(
      data: processed,
      styleSheet: styleSheet,
      padding: const EdgeInsets.all(32),
    );
  }
}
