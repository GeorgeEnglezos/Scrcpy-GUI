/// ADB Scrape Strategy
///
/// Fetches icons for Android packages by extracting them directly from device
/// APKs via ADB (zip-based heuristic + resources.arsc fallback).
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import '../app_icon_cache.dart';
import '../icon_fetch_strategy.dart';
import '../log_service.dart';
import '../terminal_service.dart';
import 'arsc_parser.dart';

class AdbScrapeStrategy implements IconFetchStrategy {
  const AdbScrapeStrategy();

  @override
  Future<void> fetchAll({
    required String deviceId,
    required List<String> packages,
    required Map<String, String> labels,
    required int batchSize,
    required bool forceUpdate,
    required bool Function() isCancelled,
    required void Function(String pkg, String label) onLabelDiscovered,
    required void Function(Map<String, File?> partial) onBatchDone,
    void Function(Map<String, String> categories)? onCategoriesLoaded,
    void Function(int current, int total, String status)? onProgress,
  }) async {
    // Build pending set, skipping already-cached icons when not forcing.
    final pendingIcon = <String>{};
    LogService.info('AdbScrapeStrategy', 'Starting fetch for device=${LogService.sanitizeDevice(deviceId)} packages=${packages.length} forceUpdate=$forceUpdate');
    for (final pkg in packages) {
      if (forceUpdate) {
        pendingIcon.add(pkg);
      } else {
        final cached = await AppIconCache.getCachedIconIfExists(pkg);
        if (cached == null) pendingIcon.add(pkg);
      }
    }

    final total = packages.length;
    var current = 0;

    // Process packages in concurrent chunks of batchSize.
    for (var i = 0; i < packages.length; i += batchSize) {
      if (isCancelled()) return;

      final chunk = packages.sublist(i, (i + batchSize).clamp(0, packages.length));

      final futures = chunk.map((pkg) async {
        final File? result;
        if (!pendingIcon.contains(pkg)) {
          result = await AppIconCache.getCachedIconIfExists(pkg);
          current++;
          onProgress?.call(current, total, 'Skipped $pkg');
        } else {
          result = await _processAdb(
            pkg: pkg,
            deviceId: deviceId,
            pendingIcon: pendingIcon,
          );
          current++;
          onProgress?.call(current, total, 'Fetched $pkg');
        }
        return MapEntry(pkg, result);
      });

      final results = await Future.wait(futures);
      final partial = Map.fromEntries(results);
      onBatchDone(partial);
    }

    // Sentinels for anything still missing
    final sentinels = <String, File?>{};
    for (final pkg in packages) {
      if (pendingIcon.contains(pkg)) sentinels[pkg] = File('');
    }
    if (sentinels.isNotEmpty) onBatchDone(sentinels);

    LogService.info('AdbScrapeStrategy', 'Fetch complete for device=${LogService.sanitizeDevice(deviceId)} — ${packages.length - pendingIcon.length}/${packages.length} icons resolved');
    onProgress?.call(total, total, 'Done');
  }

  // Density suffix priority order (highest first)
  static const _densityOrder = [
    'xxxhdpi', 'xxhdpi', 'xhdpi', 'hdpi', 'mdpi', 'ldpi',
  ];

  // Scan APK zip entries for the best launcher icon PNG/WebP by density heuristic.
  ArchiveFile? _findIconEntry(Archive archive) {
    final candidates = archive.files.where((f) {
      if (!f.isFile) return false;
      final name = f.name;
      if (!name.startsWith('res/mipmap-') && !name.startsWith('res/drawable-')) return false;
      final basename = name.substring(name.lastIndexOf('/') + 1);
      return basename.contains('ic_launcher') &&
          !basename.contains('_background') &&
          (basename.endsWith('.png') || basename.endsWith('.webp'));
    }).toList();

    if (candidates.isEmpty) return null;

    int densityScore(ArchiveFile f) {
      final name = f.name;
      for (var i = 0; i < _densityOrder.length; i++) {
        if (name.contains('-${_densityOrder[i]}')) return i;
      }
      return _densityOrder.length;
    }

    int variantScore(ArchiveFile f) {
      final basename = f.name.substring(f.name.lastIndexOf('/') + 1);
      if (basename == 'ic_launcher.png' || basename == 'ic_launcher.webp') return 0;
      if (basename.endsWith('_round.png') || basename.endsWith('_round.webp')) return 2;
      if (basename.endsWith('_foreground.png') || basename.endsWith('_foreground.webp')) return 3;
      return 1;
    }

    candidates.sort((a, b) {
      final d = densityScore(a).compareTo(densityScore(b));
      return d != 0 ? d : variantScore(a).compareTo(variantScore(b));
    });
    return candidates.first;
  }

  Future<File?> _processAdb({
    required String pkg,
    required String deviceId,
    required Set<String> pendingIcon,
  }) async {
    File? tempApk;
    try {
      final adbExe = TerminalService.adbExecutable;
      final pmResult = await Process.run(
        adbExe,
        ['-s', deviceId, 'shell', 'pm', 'path', pkg],
      );
      final pmOutput = pmResult.stdout.toString().trim();

      final allApkPaths = RegExp(r'package:(.+)')
          .allMatches(pmOutput)
          .map((m) => m.group(1)!.trim())
          .toList();

      if (allApkPaths.isEmpty) return null;

      int apkScore(String path) {
        for (var i = 0; i < _densityOrder.length; i++) {
          if (path.contains('split_config.${_densityOrder[i]}')) return i;
        }
        return _densityOrder.length;
      }

      allApkPaths.sort((a, b) => apkScore(a).compareTo(apkScore(b)));

      File? iconFile;
      tempApk = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}${pkg}_icon_tmp.apk',
      );

      if (pendingIcon.contains(pkg)) {
        // Phase A: heuristic zip scan
        for (final apkPath in allApkPaths) {
          final pullResult = await Process.run(
            adbExe,
            ['-s', deviceId, 'pull', apkPath, tempApk.path],
          );
          if (pullResult.exitCode != 0) continue;

          try {
            final archive = ZipDecoder().decodeBytes(await tempApk.readAsBytes());
            final iconEntry = _findIconEntry(archive);
            if (iconEntry != null) {
              final iconBytes = iconEntry.content as List<int>;
              final cacheFile = await AppIconCache.cacheFile(pkg);
              await cacheFile.writeAsBytes(iconBytes);
              iconFile = cacheFile;
              pendingIcon.remove(pkg);
              break;
            }
          } catch (_) {}
        }

        // Phase B: resources.arsc fallback
        if (iconFile == null) {
          iconFile = await _extractViaArsc(
            pkg: pkg,
            deviceId: deviceId,
            allApkPaths: allApkPaths,
            adbExe: adbExe,
            tempApk: tempApk,
          );
          if (iconFile != null) pendingIcon.remove(pkg);
        }
      }

      return iconFile;
    } catch (_) {
      return null;
    } finally {
      try {
        if (tempApk != null && await tempApk.exists()) await tempApk.delete();
      } catch (_) {}
    }
  }

  Future<File?> _extractViaArsc({
    required String pkg,
    required String deviceId,
    required List<String> allApkPaths,
    required String adbExe,
    required File tempApk,
  }) async {
    final basePath = allApkPaths.firstWhere(
      (p) => p.endsWith('base.apk'),
      orElse: () => allApkPaths.first,
    );

    try {
      final pullResult = await Process.run(
        adbExe, ['-s', deviceId, 'pull', basePath, tempApk.path],
      );
      if (pullResult.exitCode != 0) return null;

      final archive = ZipDecoder().decodeBytes(await tempApk.readAsBytes());

      final manifestEntry = archive.files.firstWhere(
        (f) => f.name == 'AndroidManifest.xml',
        orElse: () => ArchiveFile('', 0, Uint8List(0)),
      );
      final arscEntry = archive.files.firstWhere(
        (f) => f.name == 'resources.arsc',
        orElse: () => ArchiveFile('', 0, Uint8List(0)),
      );

      if (manifestEntry.size == 0 || arscEntry.size == 0) return null;

      final outResId = <int?>[];
      final iconPaths = resolveIconPaths(
        arscBytes: Uint8List.fromList(arscEntry.content as List<int>),
        manifestBytes: Uint8List.fromList(manifestEntry.content as List<int>),
        outResId: outResId,
      );

      // base.apk arsc gave no paths — try each density split's own arsc
      if (iconPaths.isEmpty && outResId.isNotEmpty && outResId.first != null) {
        final iconResId = outResId.first!;
        for (final splitPath in allApkPaths) {
          if (splitPath.endsWith('base.apk')) continue;
          final splitPull = await Process.run(
            adbExe, ['-s', deviceId, 'pull', splitPath, tempApk.path],
          );
          if (splitPull.exitCode != 0) continue;
          try {
            final splitArc = ZipDecoder().decodeBytes(await tempApk.readAsBytes());
            final splitArscEntry = splitArc.files.firstWhere(
              (f) => f.name == 'resources.arsc',
              orElse: () => ArchiveFile('', 0, Uint8List(0)),
            );
            if (splitArscEntry.size == 0) continue;

            final splitPaths = resolveResIdFromArsc(
              arscBytes: Uint8List.fromList(splitArscEntry.content as List<int>),
              resId: iconResId,
            );
            if (splitPaths.isEmpty) continue;

            for (final iconPath in splitPaths) {
              final entry = splitArc.files.firstWhere(
                (f) => f.isFile && f.name == iconPath,
                orElse: () => ArchiveFile('', 0, Uint8List(0)),
              );
              if (entry.size > 0) {
                final cacheFile = await AppIconCache.cacheFile(pkg);
                await cacheFile.writeAsBytes(entry.content as List<int>);
                return cacheFile;
              }
            }
          } catch (_) {}
        }
        return null;
      } else if (iconPaths.isEmpty) {
        return null;
      }

      // Search all splits for the resolved paths
      for (final apkPath in allApkPaths) {
        final pullRes = await Process.run(
          adbExe, ['-s', deviceId, 'pull', apkPath, tempApk.path],
        );
        if (pullRes.exitCode != 0) continue;
        try {
          final arc = ZipDecoder().decodeBytes(await tempApk.readAsBytes());
          for (final iconPath in iconPaths) {
            final entry = arc.files.firstWhere(
              (f) => f.isFile && f.name == iconPath,
              orElse: () => ArchiveFile('', 0, Uint8List(0)),
            );
            if (entry.size > 0) {
              final cacheFile = await AppIconCache.cacheFile(pkg);
              await cacheFile.writeAsBytes(entry.content as List<int>);
              return cacheFile;
            }
          }
        } catch (_) {}
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
