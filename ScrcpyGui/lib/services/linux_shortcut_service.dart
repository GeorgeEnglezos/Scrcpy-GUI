import 'dart:io';
import 'package:path/path.dart' as p;

/// Creates Linux desktop shortcuts (.desktop files) for scrcpy app launches.
/// Uses the XDG Desktop Entry specification — PNG icons are supported natively.
class LinuxShortcutService {
  /// Creates a desktop shortcut for [packageName] with the given [label].
  ///
  /// [scrcpyCommand] is the full command string used to launch the app.
  /// [iconPngFile] is the cached PNG icon file, or null for a default icon.
  ///
  /// Returns an error string on failure, or null on success.
  static Future<String?> createAppShortcut({
    required String packageName,
    required String label,
    required String scrcpyCommand,
    File? iconPngFile,
  }) async {
    if (!Platform.isLinux) {
      return 'Linux shortcuts are only supported on Linux.';
    }

    try {
      final desktopPath = await _getDesktopPath();
      if (desktopPath == null) {
        return 'Could not locate Desktop folder.';
      }

      // Copy icon PNG to app data dir so it persists if cache is cleared
      String? iconPath;
      if (iconPngFile != null && await iconPngFile.exists()) {
        iconPath = await _copyIcon(iconPngFile, packageName);
      }

      // Sanitize label for use as filename
      final safeName = label.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      final desktopFilePath = p.join(desktopPath, '$safeName.desktop');

      final content = _buildDesktopEntry(
        label: label,
        scrcpyCommand: scrcpyCommand,
        iconPath: iconPath,
      );

      final file = File(desktopFilePath);
      await file.writeAsString(content);

      // .desktop files must be executable to be trusted by most DEs
      await Process.run('chmod', ['+x', desktopFilePath]);

      // On GNOME, mark as trusted to suppress the "untrusted" banner
      // Silently ignore errors — not all DEs support gio
      await Process.run('gio', [
        'set',
        desktopFilePath,
        'metadata::trusted',
        'true',
      ]).catchError((_) => ProcessResult(0, 0, '', ''));

      return null; // success
    } catch (e) {
      return 'Failed to create shortcut: $e';
    }
  }

  /// Builds the XDG Desktop Entry file content.
  static String _buildDesktopEntry({
    required String label,
    required String scrcpyCommand,
    String? iconPath,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[Desktop Entry]');
    buffer.writeln('Version=1.0');
    buffer.writeln('Type=Application');
    buffer.writeln('Name=$label');
    buffer.writeln('Exec=$scrcpyCommand');
    if (iconPath != null) {
      buffer.writeln('Icon=$iconPath');
    }
    buffer.writeln('Terminal=false');
    buffer.writeln('StartupNotify=false');
    return buffer.toString();
  }

  /// Copies the PNG icon to ~/.local/share/ScrcpyGui/shortcuts/<package>.png.
  /// Returns the path to the copied file.
  static Future<String> _copyIcon(File pngFile, String packageName) async {
    final home = Platform.environment['HOME'] ?? '.';
    final shortcutsDir = Directory(
      p.join(home, '.local', 'share', 'ScrcpyGui', 'shortcuts'),
    );
    if (!await shortcutsDir.exists()) {
      await shortcutsDir.create(recursive: true);
    }
    final dest = p.join(shortcutsDir.path, '$packageName.png');
    await pngFile.copy(dest);
    return dest;
  }

  /// Returns the current user's Desktop path on Linux.
  /// Checks XDG_DESKTOP_DIR in the environment, then parses user-dirs.dirs,
  /// then falls back to ~/Desktop.
  static Future<String?> _getDesktopPath() async {
    // 1. Environment variable (set by some DEs at login)
    final envDesktop = Platform.environment['XDG_DESKTOP_DIR'];
    if (envDesktop != null && envDesktop.isNotEmpty) {
      return envDesktop;
    }

    // 2. Parse ~/.config/user-dirs.dirs
    final home = Platform.environment['HOME'];
    if (home != null) {
      final userDirsFile = File(p.join(home, '.config', 'user-dirs.dirs'));
      if (await userDirsFile.exists()) {
        final lines = await userDirsFile.readAsLines();
        for (final line in lines) {
          if (line.startsWith('XDG_DESKTOP_DIR=')) {
            var value = line.substring('XDG_DESKTOP_DIR='.length).trim();
            // Strip surrounding quotes
            if (value.startsWith('"') && value.endsWith('"')) {
              value = value.substring(1, value.length - 1);
            }
            // Replace $HOME variable
            value = value.replaceAll(r'$HOME', home);
            return value;
          }
        }
      }

      // 3. Fallback
      return p.join(home, 'Desktop');
    }

    return null;
  }
}
