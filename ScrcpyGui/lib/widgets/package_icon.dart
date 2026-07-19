import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Small (18px) package icon rendered from a cached icon file, falling back
/// to [fallbackIcon] when the file is missing or unreadable.
class PackageIcon extends StatelessWidget {
  final File? iconFile;
  final IconData fallbackIcon;

  const PackageIcon({super.key, this.iconFile, this.fallbackIcon = Icons.apps});

  @override
  Widget build(BuildContext context) {
    final fallback =
        Icon(fallbackIcon, size: 18, color: context.appTextSecondary);
    final file = iconFile;
    if (file == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.file(
        file,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
