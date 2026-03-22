import 'package:flutter/material.dart';
import 'dart:io';
import 'package:scrcpy_gui_prod/widgets/command_panel.dart';
import 'package:scrcpy_gui_prod/widgets/surrounding_panel.dart';
import '../services/app_icon_cache.dart';
import '../services/commands_service.dart';
import '../services/log_service.dart';
import '../services/terminal_service.dart';
import '../theme/app_colors.dart';

String _display(String cmd) => TerminalService.toDisplayCommand(cmd);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static final RegExp _startAppArgPattern = RegExp(
    r'''(?:^|\s)-{1,2}start-app(?:=|\s+)(?:"([^"]+)"|'([^']+)'|([^\s]+))''',
    caseSensitive: false,
  );

  final CommandsService _commandsService = CommandsService();
  final Map<String, File?> _iconByPackage = {};

  String lastCommand = '';
  List<String> favorites = [];
  List<String> mostUsed = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final commands = await _commandsService.loadCommands();

      setState(() {
        lastCommand = commands.lastCommand;
        favorites = commands.favorites;
        mostUsed = commands.getTopMostUsed(limit: 10);
        isLoading = false;
      });

      final allCommands = <String>{
        if (lastCommand.isNotEmpty) lastCommand,
        ...favorites,
        ...mostUsed,
      };
      await _hydrateCommandIcons(allCommands);
    } catch (e) {
      LogService.error('FavoritesPage/loadData', 'Failed to load', err: e);
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String? _extractStartAppPackage(String command) {
    final match = _startAppArgPattern.firstMatch(command);
    if (match == null) return null;
    return match.group(1) ?? match.group(2) ?? match.group(3);
  }

  bool _hasFlag(String command, String flagName) {
    final target = flagName.toLowerCase();
    final tokens = command.toLowerCase().split(RegExp(r'\s+'));
    for (final token in tokens) {
      if (token == '--$target' || token == '-$target') return true;
      if (token.startsWith('--$target=') || token.startsWith('-$target=')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _hydrateCommandIcons(Set<String> commands) async {
    final packages = <String>{};
    for (final command in commands) {
      final packageName = _extractStartAppPackage(command);
      if (packageName != null && packageName.isNotEmpty) {
        packages.add(packageName);
      }
    }
    if (packages.isEmpty) return;

    var changed = false;
    for (final packageName in packages) {
      if (_iconByPackage.containsKey(packageName)) continue;
      _iconByPackage[packageName] = await AppIconCache.getCachedIconIfExists(
        packageName,
      );
      changed = true;
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  Widget _buildPackageIcon(File? iconFile) {
    if (iconFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          iconFile,
          width: 18,
          height: 18,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.apps, size: 18, color: AppColors.textSecondary),
        ),
      );
    }

    return Icon(Icons.apps, size: 18, color: AppColors.textSecondary);
  }

  Widget _buildFlagIcon(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 16, color: AppColors.textSecondary),
    );
  }

  Widget? _buildCommandLeadingIcons(String command) {
    final packageName = _extractStartAppPackage(command);
    final items = <Widget>[];

    if (packageName != null && packageName.isNotEmpty) {
      final iconFile = _iconByPackage[packageName];
      items.add(
        Tooltip(message: packageName, child: _buildPackageIcon(iconFile)),
      );
    }

    if (_hasFlag(command, 'record')) {
      items.add(_buildFlagIcon(Icons.videocam, 'Recording'));
    }
    if (_hasFlag(command, 'new-display')) {
      items.add(_buildFlagIcon(Icons.monitor, 'New display window'));
    }
    if (_hasFlag(command, 'turn-screen-off')) {
      items.add(_buildFlagIcon(Icons.dark_mode, 'Turn screen off'));
    }
    if (items.isEmpty) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(items.length * 2 - 1, (index) {
        if (index.isOdd) return const SizedBox(width: 6);
        return items[index ~/ 2];
      }),
    );
  }

  Future<void> _deleteFromFavorites(int index) async {
    final command = favorites[index];
    await _commandsService.removeFromFavorites(command);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            SurroundingPanel(
              icon: Icons.terminal,
              title: 'Last Command',
              showButton: false,
              contentPadding: const EdgeInsets.all(12),
              child: lastCommand.isEmpty
                  ? Text(
                      'No command available',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  : CommandPanel(
                      command: lastCommand,
                      displayCommand: _display(lastCommand),
                      leading: _buildCommandLeadingIcons(lastCommand),
                      showDelete: false,
                      onTap: () async {
                        await TerminalService.executeCommand(context, lastCommand, source: 'Favorites/LastCommand');
                        await _loadData();
                      },
                      onDownload: () => TerminalService.generateScript(context, lastCommand),
                    ),
            ),

            const SizedBox(height: 24),

            SurroundingPanel(
              icon: Icons.favorite,
              title: 'Favorites',
              showButton: false,
              contentPadding: const EdgeInsets.all(12),
              child: favorites.isEmpty
                  ? Text(
                      'No favorite commands',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  : Column(
                      children: List.generate(
                        favorites.length,
                        (index) => CommandPanel(
                          command: favorites[index],
                          displayCommand: _display(favorites[index]),
                          leading: _buildCommandLeadingIcons(favorites[index]),
                          onTap: () async {
                            await TerminalService.executeCommand(context, favorites[index], source: 'Favorites/Favorites');
                            await _loadData();
                          },
                          onDownload: () => TerminalService.generateScript(context, favorites[index]),
                          onDelete: () => _deleteFromFavorites(index),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            SurroundingPanel(
              icon: Icons.trending_up,
              title: 'Most Used Commands',
              showButton: false,
              contentPadding: const EdgeInsets.all(12),
              child: mostUsed.isEmpty
                  ? Text(
                      'No most used commands',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  : Column(
                      children: List.generate(
                        mostUsed.length,
                        (index) => CommandPanel(
                          command: mostUsed[index],
                          displayCommand: _display(mostUsed[index]),
                          leading: _buildCommandLeadingIcons(mostUsed[index]),
                          showDelete: false,
                          onTap: () async {
                            await TerminalService.executeCommand(context, mostUsed[index], source: 'Favorites/MostUsed');
                            await _loadData();
                          },
                          onDownload: () => TerminalService.generateScript(context, mostUsed[index]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
