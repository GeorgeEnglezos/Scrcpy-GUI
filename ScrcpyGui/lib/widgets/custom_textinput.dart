/// A custom text field widget that provides a consistent UI across the application.
///
/// This widget wraps Flutter's TextField with custom styling and automatic
/// controller management. It supports labels, tooltips, and value synchronization.
library;

import 'package:flutter/material.dart';
import '../theme/app_constants.dart';
import '../theme/app_colors.dart';

/// A customized text input field with consistent styling and behavior.
///
/// The [CustomTextField] provides a styled text input with automatic controller
/// management, label support, and optional tooltip functionality. It maintains
/// internal state while synchronizing with external value changes.
///
/// Example:
/// ```dart
/// CustomTextField(
///   label: 'Port Number',
///   value: '5555',
///   onChanged: (value) => print('New value: $value'),
///   tooltip: 'Enter the ADB port number',
/// )
/// ```
class CustomTextField extends StatefulWidget {
  /// The label text displayed in the text field
  final String label;

  /// The initial or external value for the text field
  final String? value;

  /// Callback invoked when the text value changes
  final Function(String) onChanged;

  /// Optional tooltip message displayed on hover
  final String? tooltip;

  /// Creates a custom text field.
  ///
  /// The [label] and [onChanged] parameters are required.
  /// The [value] and [tooltip] parameters are optional.
  const CustomTextField({
    super.key,
    required this.label,
    this.value,
    required this.onChanged,
    this.tooltip,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

/// State class for [CustomTextField] that manages the text controller lifecycle.
///
/// This class handles:
/// - Text controller initialization and disposal
/// - Synchronization between external value changes and internal state
/// - Building the styled text field UI
class _CustomTextFieldState extends State<CustomTextField> {
  /// Internal text editing controller
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textField = SizedBox(
      height: kRowHeight,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: TextStyle(color: AppColors.textSecondary, fontSize: kFontSize),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background,
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: kLabelFontSize,
          ),
          floatingLabelStyle: TextStyle(
            color: AppColors.primary,
            fontSize: kLabelFontSize - 1,
          ),
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
            horizontal: kRowHorizontalPadding,
            vertical: kRowVerticalPadding / 2,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: textField,
      );
    }

    return textField;
  }
}
