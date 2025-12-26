/// Navigation sidebar widget for the application.
///
/// This widget provides the main navigation menu with icons and labels
/// for different sections of the application (Home, Favorites, Scripts, etc.).
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A vertical navigation sidebar with icon-based menu items.
///
/// The [Sidebar] displays navigation options with icons and labels,
/// highlighting the currently selected item. It provides navigation
/// to different pages of the application.
///
/// Example:
/// ```dart
/// Sidebar(
///   selectedIndex: 0,
///   onItemSelected: (index) => navigateToPage(index),
///   showBatFilesTab: true,
/// )
/// ```
class Sidebar extends StatelessWidget {
  /// The index of the currently selected navigation item
  final int selectedIndex;

  /// Callback invoked when a navigation item is tapped
  final Function(int) onItemSelected;

  /// Whether to show the Scripts tab (configurable in settings)
  final bool showBatFilesTab;

  /// Creates a navigation sidebar.
  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showBatFilesTab = true,
  });

  @override
  Widget build(BuildContext context) {
    final List<_SidebarItem> items = [
      const _SidebarItem(icon: Icons.home, label: 'Home'),
      const _SidebarItem(icon: Icons.favorite, label: 'Favorites'),
      if (showBatFilesTab)
        const _SidebarItem(icon: Icons.terminal, label: 'Scripts'),
      const _SidebarItem(icon: Icons.folder, label: 'Resources'),
      const _SidebarItem(icon: Icons.settings, label: 'Settings'),
    ];

    return Container(
      width: 80,
      height: double.infinity,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.phone_android, color: AppColors.primary, size: 32),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == selectedIndex;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onItemSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin:
                          const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Icon(
                              item.icon,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  const _SidebarItem({required this.icon, required this.label});
}
