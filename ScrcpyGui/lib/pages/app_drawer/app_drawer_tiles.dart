/// App Drawer grid tiles: app tile, script tile, and the small
/// checkbox-with-label row shared by the page and its dialogs.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_theme_colors.dart';

class AppTile extends StatefulWidget {
  final String packageName;
  final String label;
  final File? iconFile;
  final bool iconLoading;
  final double tileWidth;
  final bool isFavorite;
  final VoidCallback onTap;
  final void Function(Offset position) onSecondaryTap;

  const AppTile({
    super.key,
    required this.packageName,
    required this.label,
    required this.iconFile,
    required this.iconLoading,
    required this.tileWidth,
    required this.isFavorite,
    required this.onTap,
    required this.onSecondaryTap,
  });

  @override
  State<AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) =>
            widget.onSecondaryTap(details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hovered
                ? context.appPrimary.withValues(alpha: 0.12)
                : context.appSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? context.appPrimary.withValues(alpha: 0.4)
                  : context.appDivider,
            ),
          ),
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              if (widget.isFavorite)
                Positioned(
                  top: 0,
                  left: _hovered ? 0 : null,
                  right: _hovered ? null : 0,
                  child: Icon(
                    Icons.favorite,
                    size: 14,
                    color: Colors.pinkAccent,
                  ),
                ),
              if (_hovered)
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTapUp: (details) =>
                        widget.onSecondaryTap(details.globalPosition),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(bottom: 26, child: Center(child: _buildIcon())),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 26,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      widget.label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final size = (widget.tileWidth * 0.55).clamp(32.0, 96.0);

    if (widget.iconLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.appPrimary.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    if (widget.iconFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          widget.iconFile!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder(size),
        ),
      );
    }

    return _placeholder(size);
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.appPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.android,
        color: context.appPrimary.withValues(alpha: 0.6),
        size: size * 0.6,
      ),
    );
  }
}

class ScriptTile extends StatefulWidget {
  final String name;
  final double tileWidth;
  final File? iconFile;
  final VoidCallback onTap;

  const ScriptTile({
    super.key,
    required this.name,
    required this.tileWidth,
    required this.iconFile,
    required this.onTap,
  });

  @override
  State<ScriptTile> createState() => _ScriptTileState();
}

class _ScriptTileState extends State<ScriptTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = (widget.tileWidth * 0.55).clamp(32.0, 96.0);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hovered
                ? context.appPrimary.withValues(alpha: 0.12)
                : context.appSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? context.appPrimary.withValues(alpha: 0.4)
                  : context.appDivider,
            ),
          ),
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 34,
                child: Center(
                  child: widget.iconFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            widget.iconFile!,
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                _scriptPlaceholder(size),
                          ),
                        )
                      : _scriptPlaceholder(size),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 26,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      widget.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scriptPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.description_outlined,
        color: Colors.blue.withValues(alpha: 0.7),
        size: size * 0.5,
      ),
    );
  }
}

/// Compact checkbox + label row used by the fetch-method cards and dialogs.
class CheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool?) onChanged;

  const CheckboxRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: context.appPrimary,
              side: BorderSide(color: context.appTextSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: context.appTextSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
