/// Syntax highlighting utility for scrcpy command strings.
///
/// This utility provides color-coded syntax highlighting for scrcpy commands
/// to improve readability and visual distinction of different command categories.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Provides syntax highlighting for scrcpy command strings.
///
/// The [CommandSyntaxHighlighter] colorizes command flags based on their
/// category (recording, virtual display, general, audio, etc.) to make
/// commands easier to read and understand at a glance.
///
/// Color scheme:
/// - Recording flags: Red ([AppColors.recordingPrimary])
/// - Virtual Display flags: Blue ([AppColors.virtualDisplayPrimary])
/// - General flags: Orange ([AppColors.generalPrimary])
/// - Audio flags: Green ([AppColors.audioPrimary])
/// - Package flags: Amber ([AppColors.packagePrimary])
/// - Command name (scrcpy): White
/// - Values: White70
/// - Unknown flags: White
class CommandSyntaxHighlighter {
  /// Converts a command string into color-coded text spans.
  ///
  /// Takes a complete scrcpy command string and returns a list of [InlineSpan]
  /// objects with appropriate colors applied to each part.
  ///
  /// Example:
  /// ```dart
  /// final spans = CommandSyntaxHighlighter.getColorizedSpans(
  ///   'scrcpy --record file.mp4 --audio-codec opus'
  /// );
  /// // Returns spans with:
  /// // 'scrcpy' in white
  /// // '--record' and 'file.mp4' in recording color
  /// // '--audio-codec' and 'opus' in audio color
  /// ```
  static List<InlineSpan> getColorizedSpans(String command) {
    final parts = command.split(' ');
    return parts.map((part) {
      return TextSpan(
        text: "$part ",
        style: TextStyle(
          fontFamily: "monospace",
          fontSize: 14,
          color: _mapColor(part),
        ),
      );
    }).toList();
  }

  /// Maps a command part to its appropriate color based on content.
  ///
  /// This internal method determines the color for each part of the command
  /// by matching against known scrcpy flag patterns. Returns the appropriate
  /// [AppColors] constant or a default color for values and unknown flags.
  static Color _mapColor(String part) {
    if (part.startsWith("scrcpy")) return Colors.white;

    // Recording flags (Red)
    if (part.startsWith("--record") ||
        part.startsWith("--no-record") ||
        part.startsWith("--record-format") ||
        part.startsWith("--max-size") ||
        part.startsWith("--max-fps")) {
      return AppColors.recordingPrimary;
    }

    // Virtual Display flags (Blue)
    if (part.startsWith("--new-display") ||
        part.startsWith("--no-vd-destroy-content") ||
        part.startsWith("--no-vd-system-decorations")) {
      return AppColors.virtualDisplayPrimary;
    }

    // General flags (Orange)
    if (part.startsWith("--fullscreen") ||
        part.startsWith("--always-on-top") ||
        part.startsWith("--window-title") ||
        part.startsWith("--window-borderless") ||
        part.startsWith("--turn-screen-off") ||
        part.startsWith("--crop") ||
        part.startsWith("--capture-orientation") ||
        part.startsWith("--stay-awake") ||
        part.startsWith("--disable-screensaver") ||
        part.startsWith("--video-bit-rate") ||
        part.startsWith("--video-codec") ||
        part.startsWith("--video-encoder")) {
      return AppColors.generalPrimary;
    }

    // Audio flags (Green)
    if (part.startsWith("--audio-bit-rate") ||
        part.startsWith("--audio-buffer") ||
        part.startsWith("--audio-dup") ||
        part.startsWith("--no-audio") ||
        part.startsWith("--audio-codec-options") ||
        part.startsWith("--audio-codec") ||
        part.startsWith("--audio-encoder")) {
      return AppColors.audioPrimary;
    }

    // Package Selector flags (Amber)
    if (part.startsWith("--start-app")) {
      return AppColors.packagePrimary;
    }

    // Default/Unknown flags (White)
    if (part.startsWith("--")) {
      return Colors.white;
    }

    // Values
    return Colors.white70;
  }
}
