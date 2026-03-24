import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Creates Windows desktop shortcuts (.lnk) for scrcpy app launches.
/// Uses PNG-in-ICO embedding (supported on Vista+) so no extra tools are needed.
class WindowsShortcutService {
  /// Creates a desktop shortcut for [packageName] with the given [label].
  ///
  /// [scrcpyCommand] is the full command string used to launch the app,
  /// e.g. `scrcpy --serial=xxx --start-app=com.example.app`.
  /// [iconPngFile] is the cached PNG icon file, or null for a default icon.
  ///
  /// Returns an error string on failure, or null on success.
  static Future<String?> createAppShortcut({
    required String packageName,
    required String label,
    required String scrcpyCommand,
    File? iconPngFile,
  }) async {
    if (!Platform.isWindows) {
      return 'Desktop shortcuts are only supported on Windows.';
    }

    try {
      // Sanitize label for use as filename
      final safeName = label.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();

      // Write ICO file next to shortcut (in %APPDATA%\ScrcpyGui\shortcuts\)
      String? icoPath;
      if (iconPngFile != null && await iconPngFile.exists()) {
        icoPath = await _writeIcoFromPng(iconPngFile, packageName);
      }

      // Split the command into target executable and arguments.
      // scrcpyCommand may be just "scrcpy ..." or a full path.
      final parts = _splitCommand(scrcpyCommand);
      final target = parts.$1;
      final args = parts.$2;

      final ps = buildShortcutScript(
        safeName: safeName,
        target: target,
        args: args,
        icoPath: icoPath,
      );

      final result = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', ps.toString()],
        runInShell: false,
      );

      if (result.exitCode != 0) {
        return 'PowerShell error: ${result.stderr}'.trim();
      }

      return null; // success
    } catch (e) {
      return 'Failed to create shortcut: $e';
    }
  }

  /// Builds the PowerShell script that creates the .lnk file.
  ///
  /// Exposed for testing — does not touch the filesystem or spawn processes.
  @visibleForTesting
  static String buildShortcutScript({
    required String safeName,
    required String target,
    required String args,
    String? icoPath,
  }) {
    final escapedName = safeName.replaceAll("'", "''");
    final escapedIco = icoPath?.replaceAll("'", "''");

    final ps = StringBuffer();
    ps.writeln(r'$desktop = [Environment]::GetFolderPath("Desktop")');
    ps.writeln("\$lnkPath = Join-Path \$desktop '$escapedName.lnk'");
    ps.writeln(r'$ws = New-Object -ComObject WScript.Shell');
    ps.writeln(r'$lnk = $ws.CreateShortcut($lnkPath)');
    ps.writeln("\$lnk.TargetPath = '$target'");
    ps.writeln("\$lnk.Arguments = '${args.replaceAll("'", "''")}'");
    ps.writeln("\$lnk.WorkingDirectory = ''");
    if (escapedIco != null) {
      ps.writeln("\$lnk.IconLocation = '$escapedIco,0'");
    }
    ps.writeln(r'$lnk.Save()');
    return ps.toString();
  }

  /// Writes a PNG-in-ICO file to %APPDATA%\ScrcpyGui\shortcuts\<package>.ico.
  /// Returns the full path to the written .ico file.
  static Future<String> _writeIcoFromPng(
    File pngFile,
    String packageName,
  ) async {
    final appData = Platform.environment['APPDATA'] ?? '.';
    final shortcutsDir = Directory(p.join(appData, 'ScrcpyGui', 'shortcuts'));
    if (!await shortcutsDir.exists()) {
      await shortcutsDir.create(recursive: true);
    }

    final icoPath = p.join(shortcutsDir.path, '$packageName.ico');
    final pngBytes = await pngFile.readAsBytes();
    final icoBytes = _buildIcoFromPng(pngBytes);
    await File(icoPath).writeAsBytes(icoBytes);
    return icoPath;
  }

  /// Builds a minimal ICO file that wraps a PNG blob.
  /// ICO format: 6-byte header + one 16-byte directory entry + PNG data.
  static Uint8List _buildIcoFromPng(Uint8List pngBytes) {
    // ICO header: reserved(2) + type=1(2) + count=1(2) = 6 bytes
    // Directory entry: 16 bytes
    // PNG data starts at offset 22
    const headerSize = 6;
    const dirEntrySize = 16;
    const dataOffset = headerSize + dirEntrySize; // 22

    final buf = ByteData(dataOffset + pngBytes.length);

    // Header
    buf.setUint16(0, 0, Endian.little); // reserved
    buf.setUint16(2, 1, Endian.little); // type: 1 = icon
    buf.setUint16(4, 1, Endian.little); // image count: 1

    // Directory entry
    buf.setUint8(6, 0);  // width  (0 = 256)
    buf.setUint8(7, 0);  // height (0 = 256)
    buf.setUint8(8, 0);  // color count
    buf.setUint8(9, 0);  // reserved
    buf.setUint16(10, 1, Endian.little); // color planes
    buf.setUint16(12, 32, Endian.little); // bits per pixel
    buf.setUint32(14, pngBytes.length, Endian.little); // image data size
    buf.setUint32(18, dataOffset, Endian.little); // image data offset

    // Copy PNG bytes
    final result = Uint8List(dataOffset + pngBytes.length);
    result.setRange(0, dataOffset, buf.buffer.asUint8List());
    result.setRange(dataOffset, result.length, pngBytes);
    return result;
  }

  /// Splits a command string into (executable, arguments).
  /// Handles quoted paths, e.g. `"C:\path\scrcpy.exe" --flag`.
  static (String, String) _splitCommand(String command) {
    command = command.trim();
    if (command.startsWith('"')) {
      final close = command.indexOf('"', 1);
      if (close > 0) {
        final exe = command.substring(1, close);
        final rest = command.substring(close + 1).trim();
        return (exe, rest);
      }
    }
    final spaceIdx = command.indexOf(' ');
    if (spaceIdx < 0) return (command, '');
    return (command.substring(0, spaceIdx), command.substring(spaceIdx + 1).trim());
  }
}
