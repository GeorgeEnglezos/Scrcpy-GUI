import 'package:flutter/material.dart';
import 'dart:io';
import 'package:scrcpy_gui_prod/widgets/command_panel.dart';
import 'package:scrcpy_gui_prod/widgets/surrounding_panel.dart';
import '../services/settings_service.dart';
import '../services/commands_service.dart';
import '../services/terminal_service.dart';
import '../theme/app_colors.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final CommandsService _commandsService = CommandsService();

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
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  // ⬇⬇⬇ NEW — run a command when panel tapped + increase counter
  Future<void> _runCommand(String command) async {
    final commandsService = CommandsService();

    // increase usage counter
    await commandsService.trackCommandExecution(command);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Running command...'),
        backgroundColor: Colors.blueGrey,
      ),
    );

    final result = await TerminalService.runCommand(command);

    if (!mounted) return;

    if (result.isNotEmpty) {
      _showOutputDialog(command, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to run command: $command'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }

    // update most-used list
    await _loadData();
  }

  // ⬇⬇⬇ NEW: same dialog used in Actions Panel
  void _showOutputDialog(String command, String output) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Output for: $command'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              output.isNotEmpty ? output : 'No output received.',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAsBat(String command) async {
    try {
      final downloadsDir = SettingsService.currentSettings?.downloadsDirectory;

      if (downloadsDir == null || downloadsDir.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Downloads directory not configured in settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final directory = Directory(downloadsDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      List<String> nameParts = [];

      if (command.contains('--record')) {
        nameParts.add('recording');
      }

      final packageRegex = RegExp(r'--start-app[=\s]+([^\s]+)');
      final match = packageRegex.firstMatch(command);
      if (match != null) {
        final packageName = match
            .group(1)
            ?.replaceAll('"', '')
            .replaceAll("'", '');
        if (packageName != null && packageName.isNotEmpty) {
          nameParts.add(packageName);
        }
      }

      String baseFilename = nameParts.isEmpty ? 'scrcpy' : nameParts.join('_');

      String filename = baseFilename;
      int counter = 1;
      while (await File('$downloadsDir/$filename.bat').exists()) {
        filename = '$baseFilename ($counter)';
        counter++;
      }

      final file = File('$downloadsDir/$filename.bat');
      await file.writeAsString('@echo off\n$command\npause');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to ${file.path}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                      showDelete: false,
                      onTap: () => _runCommand(lastCommand),
                      onDownload: () => _downloadAsBat(lastCommand),
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
                          onTap: () => _runCommand(favorites[index]),
                          onDownload: () => _downloadAsBat(favorites[index]),
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
                          showDelete: false,
                          onTap: () => _runCommand(mostUsed[index]),
                          onDownload: () => _downloadAsBat(mostUsed[index]),
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
