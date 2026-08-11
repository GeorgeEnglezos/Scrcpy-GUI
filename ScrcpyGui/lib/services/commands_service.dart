import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/commands_model.dart';
import 'settings_service.dart';
import 'adb_service.dart';

class CommandsService {
  static const String _commandsFileName = 'commands.json';
  static CommandsData? _cachedCommands;

  static CommandsData? get currentCommands => _cachedCommands;

  Future<String> get _commandsPath async {
    final settingsDir = await SettingsService().getSettingsDirectory();
    return p.join(settingsDir, _commandsFileName);
  }

  /// Migrates all stored commands in [data] to use the current scrcpy executable.
  /// Returns true if any command was changed (caller should re-persist).
  static bool _migrateExecutables(CommandsData data) {
    bool changed = false;

    final newLast = AdbService.normalizeScrcpyExecutable(data.lastCommand);
    if (newLast != data.lastCommand) {
      data.lastCommand = newLast;
      changed = true;
    }

    for (int i = 0; i < data.favorites.length; i++) {
      final updated = AdbService.normalizeScrcpyExecutable(data.favorites[i]);
      if (updated != data.favorites[i]) {
        data.favorites[i] = updated;
        changed = true;
      }
    }

    final updatedMostUsed = <String, int>{};
    for (final entry in data.mostUsed.entries) {
      final updatedKey = AdbService.normalizeScrcpyExecutable(entry.key);
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

  /// Track a command execution (updates last command and most used).
  ///
  /// Stored device-agnostic: the same command run on different devices counts
  /// as one entry, and the current device is injected when it is re-run.
  Future<void> trackCommandExecution(String command) async {
    final commands = await loadCommands();
    final stored = AdbService.applySerial(command, null);

    commands.lastCommand = stored;
    commands.mostUsed[stored] = (commands.mostUsed[stored] ?? 0) + 1;

    await saveCommands(commands);
  }

  /// Add a command to favorites, device-agnostic (the current device is
  /// injected at run/download time, so a favorite follows the connected device).
  Future<void> addToFavorites(String command) async {
    final commands = await loadCommands();
    final stored = AdbService.applySerial(command, null);

    if (!commands.favorites.contains(stored)) {
      commands.favorites.add(stored);
      await saveCommands(commands);
    }
  }

  /// Remove a command from favorites
  Future<void> removeFromFavorites(String command) async {
    final commands = await loadCommands();

    commands.favorites.remove(AdbService.applySerial(command, null));
    await saveCommands(commands);
  }

  /// Check if a command is in favorites
  Future<bool> isFavorite(String command) async {
    final commands = await loadCommands();
    return commands.favorites.contains(AdbService.applySerial(command, null));
  }
}
