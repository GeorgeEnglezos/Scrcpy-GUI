import 'dart:io';
import 'package:path/path.dart' as p;

/// Creates macOS desktop shortcuts (.app bundles) for scrcpy app launches.
/// The bundle contains a silent shell script launcher and a proper .icns icon
/// built from the cached PNG using the built-in sips + iconutil tools.
class MacosShortcutService {
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
    if (!Platform.isMacOS) {
      return 'macOS shortcuts are only supported on macOS.';
    }

    try {
      final home = Platform.environment['HOME'];
      if (home == null) return 'Could not determine home directory.';

      final desktopPath = p.join(home, 'Desktop');
      final safeName = label.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      final appBundlePath = p.join(desktopPath, '$safeName.app');

      // Create .app bundle directory structure
      final macosDir = Directory(p.join(appBundlePath, 'Contents', 'MacOS'));
      final resourcesDir = Directory(
        p.join(appBundlePath, 'Contents', 'Resources'),
      );
      await macosDir.create(recursive: true);
      await resourcesDir.create(recursive: true);

      // Convert PNG → ICNS (non-fatal: bundle still works without an icon)
      if (iconPngFile != null && await iconPngFile.exists()) {
        await _createIcns(iconPngFile, resourcesDir.path);
      }

      // Write the launcher shell script — runs silently, no Terminal window
      final launcherPath = p.join(macosDir.path, 'launcher');
      await File(launcherPath).writeAsString('#!/bin/bash\n$scrcpyCommand\n');
      await Process.run('chmod', ['+x', launcherPath]);

      // Write Info.plist
      final plistPath = p.join(appBundlePath, 'Contents', 'Info.plist');
      await File(plistPath).writeAsString(
        _buildInfoPlist(packageName, label),
      );

      // Strip quarantine flag so Gatekeeper does not block first launch
      await Process.run('xattr', ['-rd', 'com.apple.quarantine', appBundlePath]);

      return null; // success
    } catch (e) {
      return 'Failed to create shortcut: $e';
    }
  }

  /// Converts a PNG to an ICNS file inside [resourcesPath] using the
  /// macOS built-in tools sips (resize) and iconutil (pack).
  /// Both tools ship with every macOS install — no external dependencies.
  static Future<void> _createIcns(File pngFile, String resourcesPath) async {
    final tempDir = await Directory.systemTemp.createTemp('scrcpygui_iconset');
    try {
      final iconsetPath = p.join(tempDir.path, 'app.iconset');
      await Directory(iconsetPath).create();

      // sips produces the standard sizes required by iconutil.
      // Format: icon_WxH.png and icon_WxH@2x.png (retina = 2× pixel size).
      final sizes = <(int, String)>[
        (16, 'icon_16x16.png'),
        (32, 'icon_16x16@2x.png'),
        (32, 'icon_32x32.png'),
        (64, 'icon_32x32@2x.png'),
        (128, 'icon_128x128.png'),
        (256, 'icon_128x128@2x.png'),
        (256, 'icon_256x256.png'),
        (512, 'icon_256x256@2x.png'),
        (512, 'icon_512x512.png'),
        (1024, 'icon_512x512@2x.png'),
      ];

      for (final (px, filename) in sizes) {
        await Process.run('sips', [
          '-z', '$px', '$px',
          pngFile.path,
          '--out', p.join(iconsetPath, filename),
        ]);
      }

      // Pack the iconset into a single .icns file
      final icnsPath = p.join(resourcesPath, 'app.icns');
      await Process.run('iconutil', [
        '-c', 'icns',
        iconsetPath,
        '-o', icnsPath,
      ]);
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  /// Builds a minimal Info.plist for the launcher bundle.
  static String _buildInfoPlist(String packageName, String label) {
    final escapedLabel = label
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final bundleId =
        'com.scrcpygui.shortcut.'
        '${packageName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';

    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIconFile</key>
    <string>app</string>
    <key>CFBundleIdentifier</key>
    <string>$bundleId</string>
    <key>CFBundleName</key>
    <string>$escapedLabel</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>''';
  }
}
