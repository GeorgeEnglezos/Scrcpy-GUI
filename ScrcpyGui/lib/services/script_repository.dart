/// Shared script/icon logic for the Scripts page, App Drawer, and Favorites:
/// script-directory scanning, `--start-app` package extraction, and
/// cached-icon hydration.
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'app_icon_cache.dart';

/// One folder of script files (the root of the scripts directory or a
/// subdirectory).
class ScriptGroup {
  final String name;
  final bool isRoot;
  final List<File> files;

  ScriptGroup({required this.name, required this.isRoot, required this.files});
}

class ScriptRepository {
  ScriptRepository._();

  /// Matches `--start-app=value` and `--start-app value`, quoted or bare.
  static final RegExp startAppArgPattern = RegExp(
    r'''(?:^|\s)-{1,2}start-app(?:=|\s+)(?:"([^"]+)"|'([^']+)'|([^\s]+))''',
    caseSensitive: false,
  );

  /// Script extensions for the current platform.
  static List<String> get scriptExtensions => Platform.isWindows
      ? const ['.bat', '.cmd']
      : Platform.isMacOS
          ? const ['.sh', '.command']
          : const ['.sh'];

  static bool isScriptFile(String path) {
    final lower = path.toLowerCase();
    return scriptExtensions.any(lower.endsWith);
  }

  /// Extracts the `--start-app` package name from a command string or script
  /// text. Returns null when the flag is absent.
  static String? extractStartAppPackage(String text) {
    final match = startAppArgPattern.firstMatch(text);
    if (match == null) return null;
    return match.group(1) ?? match.group(2) ?? match.group(3);
  }

  /// Reads [script] and extracts its `--start-app` package, memoized in
  /// [cache] by file path. Unreadable files cache null so they are not
  /// re-read on every rebuild.
  static String? packageForScript(File script, Map<String, String?> cache) {
    if (cache.containsKey(script.path)) return cache[script.path];
    String? pkg;
    try {
      pkg = extractStartAppPackage(script.readAsStringSync());
    } catch (_) {
      pkg = null;
    }
    cache[script.path] = pkg;
    return pkg;
  }

  /// Loads cached icons for [packages] into [into], skipping keys already
  /// present. Returns true if anything was added (caller decides whether to
  /// rebuild).
  static Future<bool> hydrateCachedIcons(
    Iterable<String> packages,
    Map<String, File?> into,
  ) async {
    var changed = false;
    for (final pkg in packages) {
      if (into.containsKey(pkg)) continue;
      into[pkg] = await AppIconCache.getCachedIconIfExists(pkg);
      changed = true;
    }
    return changed;
  }

  /// Scans [directory] for script files: root files first, then one group
  /// per subdirectory (alphabetical), each group sorted by filename.
  static Future<List<ScriptGroup>> loadGroups(String directory) async {
    if (directory.isEmpty) return [];
    final dir = Directory(directory);
    if (!await dir.exists()) return [];

    int byName(FileSystemEntity a, FileSystemEntity b) => p
        .basename(a.path)
        .toLowerCase()
        .compareTo(p.basename(b.path).toLowerCase());

    final entities = await dir.list().toList();
    final rootFiles = entities
        .whereType<File>()
        .where((f) => isScriptFile(f.path))
        .toList()
      ..sort(byName);
    final subDirs = entities.whereType<Directory>().toList()..sort(byName);

    final groups = <ScriptGroup>[];
    if (rootFiles.isNotEmpty) {
      groups.add(ScriptGroup(name: 'Root', isRoot: true, files: rootFiles));
    }
    for (final subDir in subDirs) {
      final subFiles = (await subDir.list().toList())
          .whereType<File>()
          .where((f) => isScriptFile(f.path))
          .toList()
        ..sort(byName);
      if (subFiles.isNotEmpty) {
        groups.add(
          ScriptGroup(
            name: p.basename(subDir.path),
            isRoot: false,
            files: subFiles,
          ),
        );
      }
    }
    return groups;
  }
}
