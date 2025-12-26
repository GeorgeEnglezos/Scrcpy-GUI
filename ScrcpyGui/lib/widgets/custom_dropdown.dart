/// A custom dropdown widget that provides a consistent UI across the application.
///
/// This widget wraps Flutter's DropdownButtonFormField with custom styling
/// to match the application's design system. It supports labels, hints,
/// and automatic value validation.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A customized dropdown selector with consistent styling and behavior.
///
/// The [CustomDropdown] provides a styled dropdown menu with automatic
/// value validation to prevent assertion errors. It includes label and
/// optional hint support, with full horizontal expansion in its container.
///
/// Features:
/// - Automatic validation of selected value against items list
/// - Optional hint text for empty state
/// - Full horizontal expansion with isExpanded
/// - Custom styling matching app theme
/// - Optional check icon display
///
/// Example:
/// ```dart
/// CustomDropdown(
///   label: 'Video Codec',
///   value: 'h264',
///   items: ['h264', 'h265', 'av1'],
///   onChanged: (value) => print('Selected: $value'),
///   hint: 'Choose a codec',
/// )
/// ```
class CustomDropdown extends StatelessWidget {
  /// The label text displayed above the dropdown
  final String label;

  /// The currently selected value
  final String? value;

  /// List of available items in the dropdown
  final List<String> items;

  /// Callback invoked when selection changes
  final Function(String?) onChanged;

  /// Whether to show a check icon for selected item
  final bool showCheckIcon;

  /// Optional placeholder text shown when no value is selected
  final String? hint;

  /// Creates a custom dropdown.
  ///
  /// The [label], [value], [items], and [onChanged] parameters are required.
  /// The [showCheckIcon] defaults to false, and [hint] is optional.
  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.showCheckIcon = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null, // prevents assertion
      onChanged: onChanged,
      isExpanded: true, // ✅ makes dropdown take all available horizontal space
      dropdownColor: AppColors.surface,
      iconEnabledColor: AppColors.textSecondary,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      hint: hint != null
          ? Text(
              hint!,
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
            )
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        floatingLabelStyle: TextStyle(color: AppColors.primary, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
    );
  }
}
