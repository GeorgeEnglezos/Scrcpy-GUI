import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/app_snackbar.dart';
import 'package:scrcpy_gui_prod/widgets/command_panel.dart';
import 'package:scrcpy_gui_prod/widgets/package_icon.dart';
import 'package:scrcpy_gui_prod/widgets/surrounding_panel.dart';
import '../services/commands_service.dart';
import '../services/log_service.dart';
import '../services/script_repository.dart';
import '../services/adb_service.dart';
import '../utils/command_executor.dart';
import '../theme/app_theme_colors.dart';

String _display(String cmd) => AdbService.toDisplayCommand(cmd);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
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
        showAppSnackBar(
          context,
          'Error loading data: $e',
          type: AppSnackBarType.error,
        );
      }
    }
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
      final packageName = ScriptRepository.extractStartAppPackage(command);
      if (packageName != null && packageName.isNotEmpty) {
        packages.add(packageName);
      }
    }
    if (packages.isEmpty) return;

    final changed =
        await ScriptRepository.hydrateCachedIcons(packages, _iconByPackage);
    if (changed && mounted) {
      setState(() {});
    }
  }

  Widget _buildFlagIcon(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 16, color: context.appTextSecondary),
    );
  }

  Widget? _buildCommandLeadingIcons(String command) {
    final packageName = ScriptRepository.extractStartAppPackage(command);
    final items = <Widget>[];

    if (packageName != null && packageName.isNotEmpty) {
      final iconFile = _iconByPackage[packageName];
      items.add(
        Tooltip(
          message: packageName,
          child: PackageIcon(iconFile: iconFile),
        ),
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
      return Center(child: CircularProgressIndicator(color: context.appPrimary));
    }

    return Scaffold(
      backgroundColor: context.appBackground,
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
                      style: TextStyle(color: context.appTextSecondary),
                    )
                  : CommandPanel(
                      command: lastCommand,
                      displayCommand: _display(lastCommand),
                      leading: _buildCommandLeadingIcons(lastCommand),
                      showDelete: false,
                      onTap: () async {
                        await CommandExecutor.executeCommand(
                          context,
                          lastCommand,
                          source: 'Favorites/LastCommand',
                        );
                        await _loadData();
                      },
                      onDownload: () =>
                          CommandExecutor.generateScript(context, lastCommand),
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
                      style: TextStyle(color: context.appTextSecondary),
                    )
                  : Column(
                      children: List.generate(
                        favorites.length,
                        (index) => CommandPanel(
                          command: favorites[index],
                          displayCommand: _display(favorites[index]),
                          leading: _buildCommandLeadingIcons(favorites[index]),
                          onTap: () async {
                            await CommandExecutor.executeCommand(
                              context,
                              favorites[index],
                              source: 'Favorites/Favorites',
                            );
                            await _loadData();
                          },
                          onDownload: () => CommandExecutor.generateScript(
                            context,
                            favorites[index],
                          ),
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
                      style: TextStyle(color: context.appTextSecondary),
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
                            await CommandExecutor.executeCommand(
                              context,
                              mostUsed[index],
                              source: 'Favorites/MostUsed',
                            );
                            await _loadData();
                          },
                          onDownload: () => CommandExecutor.generateScript(
                            context,
                            mostUsed[index],
                          ),
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
