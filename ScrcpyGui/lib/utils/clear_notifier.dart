/// Utility for coordinating clear operations across multiple panels.
///
/// This file provides a simple controller that notifies listeners when
/// a clear-all operation should be performed.
library;

import 'package:flutter/material.dart';

/// Controller for broadcasting clear operations to all listening panels.
///
/// The [ClearController] extends [ChangeNotifier] to provide a simple
/// mechanism for coordinating clear operations across multiple UI panels.
/// When [clearAll] is called, all registered listeners are notified and
/// can respond by clearing their form fields.
///
/// Example:
/// ```dart
/// final clearController = ClearController();
///
/// // In a panel widget
/// clearController.addListener(() {
///   // Clear all fields in this panel
///   setState(() {
///     field1 = '';
///     field2 = false;
///   });
/// });
///
/// // Trigger clear from anywhere
/// clearController.clearAll();
/// ```
class ClearController extends ChangeNotifier {
  /// Triggers a clear operation by notifying all listeners.
  ///
  /// When called, all panels or widgets listening to this controller
  /// will receive a notification and can respond by clearing their state.
  void clearAll() {
    notifyListeners();
  }
}
