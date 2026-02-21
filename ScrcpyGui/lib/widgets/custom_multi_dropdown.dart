/// A custom multi-select dropdown widget that provides a consistent UI across the application.
///
/// This widget wraps the MultiDropdown package with custom styling to match
/// the application's design system. It supports a floating label, tooltip, and
/// chip-based display of selected values.
library;

import 'package:flutter/material.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

import '../theme/app_colors.dart';

/// A customized multi-select dropdown with consistent styling and behavior.
///
/// The [CustomMultiDropdown] provides a styled multi-select dropdown that
/// displays selected items as removable chips. It uses [FieldDecoration.inputDecoration]
/// to match the exact appearance of other form inputs in the app (same floating
/// label, borders, fill color, and padding as [CustomDropdown]).
///
/// Example:
/// ```dart
/// CustomMultiDropdown(
///   label: 'Shortcut Mod Key',
///   items: [
///     DropdownItem(label: 'lctrl', value: 'lctrl'),
///     DropdownItem(label: 'lalt', value: 'lalt'),
///   ],
///   controller: _controller,
///   onSelectionChange: (selected) => print('Selected: $selected'),
///   tooltip: 'Select one or more modifier keys.',
/// )
/// ```
class CustomMultiDropdown extends StatelessWidget {
  /// The floating label text shown above the field (matches [CustomDropdown]'s label)
  final String label;

  /// The list of selectable items
  final List<DropdownItem<String>> items;

  /// Controller for programmatic selection management (e.g. clear, restore)
  final MultiSelectController<String> controller;

  /// Callback invoked when the selection changes
  final void Function(List<String>) onSelectionChange;

  /// Optional tooltip message displayed on hover
  final String? tooltip;

  /// Creates a custom multi-select dropdown.
  ///
  /// The [label], [items], [controller], and [onSelectionChange] parameters
  /// are required. The [tooltip] parameter is optional.
  const CustomMultiDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.controller,
    required this.onSelectionChange,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final dropdown = MultiDropdown<String>(
      items: items,
      controller: controller,
      onSelectionChange: onSelectionChange,
      fieldDecoration: FieldDecoration(
        inputDecoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background,
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        ),
      ),
      dropdownDecoration: DropdownDecoration(
        backgroundColor: AppColors.surface,
        maxHeight: 250,
        borderRadius: BorderRadius.circular(8),
      ),
      dropdownItemDecoration: DropdownItemDecoration(
        selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.15),
        textColor: Colors.white70,
        selectedTextColor: Colors.white,
      ),
      chipDecoration: ChipDecoration(
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        borderRadius: BorderRadius.circular(6),
        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
        spacing: 6,
        runSpacing: 6,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: dropdown);
    }

    return dropdown;
  }
}
