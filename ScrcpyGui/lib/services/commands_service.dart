import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/commands_model.dart';
import '../utils/app_paths.dart';

class CommandsService {
  static const String _commandsFileName = 'commands.json';
  static CommandsData? _cachedCommands;

  static CommandsData? get currentCommands => _cachedCommands;

  Future<String> get _commandsPath async {
    final basePath = await AppPaths.getBasePath();
    return p.join(basePath, _commandsFileName);
  }

  Future<CommandsData> loadCommands() async {
    try {
      final path = await _commandsPath;
      final file = File(path);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        _cachedCommands = CommandsData.fromJsonString(jsonString);
        return _cachedCommands!;
      }
    } catch (e) {
      debugPrint('Error loading commands: $e');
    }

    // First launch - create with default favorites
    _cachedCommands = CommandsData(
      favorites: List.from(CommandsData.defaultFavorites),
    );

    // Save the defaults to persist them
    await saveCommands(_cachedCommands!);

    return _cachedCommands!;
  }

  Future<bool> saveCommands(CommandsData commands) async {
    try {
      final path = await _commandsPath;
      final file = File(path);

      _cachedCommands = commands;

      await file.writeAsString(commands.toJsonString());
      return true;
    } catch (e) {
      debugPrint('Error saving commands: $e');
      return false;
    }
  }

  /// Track a command execution (updates last command and most used)
  Future<void> trackCommandExecution(String command) async {
    final commands = await loadCommands();

    // Update last command
    commands.lastCommand = command;

    // Update most used counter
    commands.mostUsed[command] = (commands.mostUsed[command] ?? 0) + 1;

    await saveCommands(commands);
  }

  /// Add a command to favorites
  Future<void> addToFavorites(String command) async {
    final commands = await loadCommands();

    if (!commands.favorites.contains(command)) {
      commands.favorites.add(command);
      await saveCommands(commands);
    }
  }

  /// Remove a command from favorites
  Future<void> removeFromFavorites(String command) async {
    final commands = await loadCommands();

    commands.favorites.remove(command);
    await saveCommands(commands);
  }

  /// Check if a command is in favorites
  Future<bool> isFavorite(String command) async {
    final commands = await loadCommands();
    return commands.favorites.contains(command);
  }
}
