import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/commands_model.dart';
import 'settings_service.dart';
import 'terminal_service.dart';

class CommandsService {
  static const String _commandsFileName = 'commands.json';
  static CommandsData? _cachedCommands;

  static CommandsData? get currentCommands => _cachedCommands;

  Future<String> get _commandsPath async {
    final settingsDir = await SettingsService().getSettingsDirectory();
    return p.join(settingsDir, _commandsFileName);
  }

  /// Rewrites the scrcpy executable prefix in a single command to match the
  /// current [TerminalService.scrcpyExecutable]. Handles:
  /// - Bare "scrcpy" (PATH-based)
  /// - Unquoted full paths: C:\path\scrcpy.exe --flags
  /// - Quoted full paths:  "C:\path with spaces\scrcpy.exe" --flags
  static String _normalizeExecutable(String cmd) =>
      TerminalService.normalizeScrcpyExecutable(cmd);

  /// Migrates all stored commands in [data] to use the current scrcpy executable.
  /// Returns true if any command was changed (caller should re-persist).
  static bool _migrateExecutables(CommandsData data) {
    bool changed = false;

    final newLast = _normalizeExecutable(data.lastCommand);
    if (newLast != data.lastCommand) {
      data.lastCommand = newLast;
      changed = true;
    }

    for (int i = 0; i < data.favorites.length; i++) {
      final updated = _normalizeExecutable(data.favorites[i]);
      if (updated != data.favorites[i]) {
        data.favorites[i] = updated;
        changed = true;
      }
    }

    final updatedMostUsed = <String, int>{};
    for (final entry in data.mostUsed.entries) {
      final updatedKey = _normalizeExecutable(entry.key);
      // Merge counts in case two old keys normalise to the same new key
      updatedMostUsed[updatedKey] = (updatedMostUsed[updatedKey] ?? 0) + entry.value;
      if (updatedKey != entry.key) { changed = true; }
    }
    if (changed) {
      data.mostUsed
        ..clear()
        ..addAll(updatedMostUsed);
    }

    return changed;
  }

  Future<CommandsData> loadCommands() async {
    try {
      final path = await _commandsPath;
      final file = File(path);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        _cachedCommands = CommandsData.fromJsonString(jsonString);
        if (_migrateExecutables(_cachedCommands!)) {
          await saveCommands(_cachedCommands!);
        }

        return _cachedCommands!;
      }
    } catch (_) {}

    // First launch - create with default favorites
    _cachedCommands = CommandsData(
      favorites: List.from(CommandsData.defaultFavorites),
    );
    _migrateExecutables(_cachedCommands!);

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
