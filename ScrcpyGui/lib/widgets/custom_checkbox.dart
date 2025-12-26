/// A custom checkbox widget that provides a consistent UI across the application.
///
/// This widget creates a styled checkbox with a label and optional tooltip,
/// matching the application's design system. The entire row is clickable.
library;

import 'package:flutter/material.dart';
import '../theme/app_constants.dart';
import '../theme/app_colors.dart';

/// A customized checkbox with label and consistent styling.
///
/// The [CustomCheckbox] provides a clickable row containing a label and checkbox.
/// The entire container is interactive, with visual feedback showing the selected state.
/// The border color changes to primary when checked, providing clear visual feedback.
///
/// Example:
/// ```dart
/// CustomCheckbox(
///   label: 'Stay Awake',
///   value: true,
///   onChanged: (value) => print('Checkbox is now: $value'),
///   tooltip: 'Keep the device screen on',
/// )
/// ```
class CustomCheckbox extends StatelessWidget {
  /// The label text displayed next to the checkbox
  final String label;

  /// The current checked state of the checkbox
  final bool value;

  /// Callback invoked when the checkbox state changes
  final Function(bool) onChanged;

  /// Optional tooltip message displayed on hover
  final String? tooltip;

  /// Creates a custom checkbox.
  ///
  /// The [label], [value], and [onChanged] parameters are required.
  /// The [tooltip] parameter is optional.
  const CustomCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final checkbox = SizedBox(
      height: kRowHeight - 2, // slightly shorter than text input
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kRowHorizontalPadding,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: value ? Colors.white : AppColors.textSecondary,
                    fontSize: kFontSize,
                  ),
                ),
              ),
              SizedBox(
                width: kCheckboxSize,
                height: kCheckboxSize,
                child: Checkbox(
                  value: value,
                  onChanged: (val) => onChanged(val ?? false),
                  activeColor: AppColors.primary,
                  checkColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    vertical: -4,
                    horizontal: -4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: checkbox,
      );
    }

    return checkbox;
  }
}
