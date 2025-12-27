/// Search bar with autocomplete dropdown and optional clear/reload buttons
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final String? value;
  final Function(String) onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onReload;
  final List<String> suggestions;
  final bool enabled;
  final String? tooltip;

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
