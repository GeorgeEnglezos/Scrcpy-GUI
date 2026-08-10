/// UI scale selector, shared by the Settings page and the first-run wizard.
library;

import 'package:flutter/material.dart';

import 'custom_dropdown.dart';

/// Label shown at 100%, and what [uiScaleLabel] falls back to.
const String kUiScaleDefaultLabel = '100% (Default)';

/// Dropdown label mapped to the stored scale factor. Order is the order shown.
/// Lives here rather than in the model because these are presentation strings:
/// the model owns the numeric bounds the value is clamped to, not its wording.
const Map<String, double> kUiScaleOptions = {
  '120%': 1.20,
  '110%': 1.10,
  kUiScaleDefaultLabel: 1.0,
  '95%': 0.95,
  '90%': 0.90,
  '85%': 0.85,
  '80%': 0.80,
};

/// Reverse lookup with a tolerance, so a float that does not compare equal
/// cannot leave the dropdown blank. Falls back to the default rather than to
/// the first entry, which is the largest zoom.
String uiScaleLabel(double scale) {
  for (final entry in kUiScaleOptions.entries) {
    if ((entry.value - scale).abs() < 0.001) return entry.key;
  }
  return kUiScaleDefaultLabel;
}

class UiScaleDropdown extends StatelessWidget {
  /// The stored scale factor, not the label.
  final double scale;

  /// Called with the new scale factor. Never fires for an unknown label.
  final ValueChanged<double> onChanged;

  const UiScaleDropdown({
    super.key,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown(
      label: 'UI Scale',
      value: uiScaleLabel(scale),
      items: kUiScaleOptions.keys.toList(),
      onChanged: (value) {
        final selected = kUiScaleOptions[value];
        if (selected == null) return;
        onChanged(selected);
      },
    );
  }
}
