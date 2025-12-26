/// A custom search bar widget with autocomplete suggestions.
///
/// This widget provides a search input field with dropdown suggestions,
/// supporting features like clear button, reload button, and tooltip.
/// The suggestions are filtered as the user types.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart'; // new constants file

/// A sophisticated search bar with autocomplete and suggestion filtering.
///
/// The [CustomSearchBar] provides a text input field with an overlay showing
/// filtered suggestions based on user input. It supports optional clear and
/// reload buttons, and can be enabled or disabled.
///
/// Features:
/// - Real-time suggestion filtering based on user input
/// - Dropdown overlay showing matching suggestions
/// - Optional clear and reload action buttons
/// - Tooltip support for additional context
/// - Enable/disable state management
///
/// Example:
/// ```dart
/// CustomSearchBar(
///   hintText: 'Select device',
///   value: 'device-123',
///   suggestions: ['device-123', 'device-456', 'device-789'],
///   onChanged: (value) => print('Selected: $value'),
///   onClear: () => print('Cleared'),
///   onReload: () => refreshDeviceList(),
///   tooltip: 'Search for connected devices',
/// )
/// ```
class CustomSearchBar extends StatefulWidget {
  /// The hint text displayed when the field is empty
  final String hintText;

  /// The current value of the search field
  final String? value;

  /// Callback invoked when the search text changes
  final Function(String) onChanged;

  /// Optional callback for the clear button
  final VoidCallback? onClear;

  /// Optional callback for the reload button
  final VoidCallback? onReload;

  /// List of suggestions to show in the dropdown
  final List<String> suggestions;

  /// Whether the search bar is enabled or disabled
  final bool enabled;

  /// Optional tooltip message displayed on hover
  final String? tooltip;

  /// Creates a custom search bar.
  ///
  /// The [hintText] and [onChanged] parameters are required.
  /// All other parameters are optional and provide additional functionality.
  const CustomSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.value,
    this.onClear,
    this.onReload,
    this.suggestions = const [],
    this.enabled = true,
    this.tooltip,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

/// State class for [CustomSearchBar] managing suggestions and overlay display.
///
/// This class handles:
/// - Text controller and focus node management
/// - Suggestion filtering based on user input
/// - Overlay portal for displaying suggestions dropdown
/// - User interaction with suggestions (tap to select)
/// - Clear and reload button actions
class _CustomSearchBarState extends State<CustomSearchBar> {
  /// Internal text editing controller
  late TextEditingController _controller;

  /// Focus node for managing keyboard focus
  final FocusNode _focusNode = FocusNode();

  /// Layer link for positioning the overlay relative to the text field
  final LayerLink _layerLink = LayerLink();

  /// Controller for showing/hiding the suggestions overlay
  final OverlayPortalController _overlayController = OverlayPortalController();

  /// List of suggestions filtered by current input
  List<String> _filteredSuggestions = [];

  /// Flag to prevent overlay from hiding during suggestion selection
  bool _isSelectingSuggestion = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(CustomSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    if (oldWidget.suggestions != widget.suggestions) {
      _updateFilteredSuggestions();
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _updateFilteredSuggestions();
      if (_filteredSuggestions.isNotEmpty) _overlayController.show();
    } else {
      if (!_isSelectingSuggestion) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_isSelectingSuggestion) _overlayController.hide();
        });
      }
    }
  }

  void _updateFilteredSuggestions() {
    setState(() {
      if (_controller.text.isEmpty) {
        _filteredSuggestions = widget.suggestions;
      } else {
        _filteredSuggestions = widget.suggestions
            .where(
              (s) => s.toLowerCase().contains(_controller.text.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _onTextChanged(String value) {
    widget.onChanged(value);
    _updateFilteredSuggestions();

    if (_focusNode.hasFocus) {
      if (_filteredSuggestions.isNotEmpty) {
        _overlayController.show();
      } else {
        _overlayController.hide();
      }
    }
  }

  void _onSuggestionTap(String suggestion) {
    _isSelectingSuggestion = true;
    setState(() {
      _controller.text = suggestion;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: suggestion.length),
      );
    });
    widget.onChanged(suggestion);
    _overlayController.hide();
    _isSelectingSuggestion = false;
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    _updateFilteredSuggestions();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchBar = OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        final width = renderBox?.size.width ?? 300;

        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: TapRegion(
              onTapOutside: (_) {
                if (_focusNode.hasFocus) _focusNode.unfocus();
              },
              child: Material(
                color: AppColors.surface,
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final item = _filteredSuggestions[index];
                      return InkWell(
                        onTap: () => _onSuggestionTap(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kRowHorizontalPadding,
                            vertical: kRowVerticalPadding,
                          ),
                          child: Text(
                            item,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: () {
            if (!widget.enabled) return;
            if (_focusNode.hasFocus && !_overlayController.isShowing) {
              _updateFilteredSuggestions();
              if (_filteredSuggestions.isNotEmpty) _overlayController.show();
            }
          },
          child: Container(
            height: kRowHeight,
            decoration: BoxDecoration(
              color: widget.enabled
                  ? AppColors.background
                  : AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kRowHorizontalPadding,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onTextChanged,
                      enabled: widget.enabled,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: kFontSize,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontSize: kLabelFontSize,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: kRowVerticalPadding / 2,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.onReload != null)
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: widget.enabled ? widget.onReload : null,
                  ),
                if (widget.onClear != null)
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.primary, size: 20),
                    onPressed: widget.enabled ? _onClear : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: searchBar,
      );
    }

    return searchBar;
  }
}
