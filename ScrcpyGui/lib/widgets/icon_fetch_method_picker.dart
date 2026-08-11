/// Side-by-side cards for choosing how app icons and labels are fetched.
///
/// Shared by the App Drawer's first-load empty state and the setup wizard, so
/// the two cannot describe the same two methods differently.
library;

import 'package:flutter/material.dart';

import '../services/icon_fetch_strategy.dart';
import '../theme/app_theme_colors.dart';

/// Where the helper APK is published. Shown so the user can read what they are
/// about to install on their device.
const String kHelperApkSourceUrl =
    'https://github.com/GeorgeEnglezos/android-icon-label-exporter-apk';

const String _helperApkTitle = 'Helper APK';
const String _adbTitle = 'ADB';

/// Display name for [method], as titled on its card.
String iconFetchMethodName(IconFetchMethod method) => switch (method) {
      IconFetchMethod.helperApk => _helperApkTitle,
      IconFetchMethod.adbScrape => _adbTitle,
    };

class IconFetchMethodPicker extends StatelessWidget {
  final IconFetchMethod selected;
  final ValueChanged<IconFetchMethod> onChanged;

  /// Extra controls rendered inside the Helper APK card. The App Drawer puts
  /// its auto-install checkbox and source link here; the wizard, which cannot
  /// install anything without a connected device, passes none.
  final List<Widget> helperApkExtras;

  const IconFetchMethodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.helperApkExtras = const [],
  });

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight + stretch so both cards match the taller one, even though
    // the two descriptions differ a lot in length.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MethodCard(
              isSelected: selected == IconFetchMethod.helperApk,
              onTap: () => onChanged(IconFetchMethod.helperApk),
              icon: Icons.android,
              title: _helperApkTitle,
              description:
                  'Uses a small helper app on your device to extract icons and '
                  'labels directly. Best icon quality and results.',
              badge: 'Recommended',
              extras: helperApkExtras,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MethodCard(
              isSelected: selected == IconFetchMethod.adbScrape,
              onTap: () => onChanged(IconFetchMethod.adbScrape),
              icon: Icons.terminal,
              title: _adbTitle,
              description:
                  'Pulls each APK from the device via ADB and extracts the '
                  'launcher icon by scanning the zip for density-specific '
                  'PNG/WebP files. Falls back to parsing resources.arsc for '
                  'apps with obfuscated icon paths. Results may vary; for '
                  'better coverage, try the Helper APK method.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String description;
  final String? badge;
  final List<Widget> extras;

  const _MethodCard({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.description,
    this.badge,
    this.extras = const [],
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = badge;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appPrimary.withValues(alpha: 0.12)
              : context.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.appPrimary.withValues(alpha: 0.6)
                : context.appDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: context.appPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: context.appTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 16, color: context.appPrimary),
              ],
            ),
            if (badgeText != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.appPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: context.appPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: context.appTextSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...extras,
            ],
          ],
        ),
      ),
    );
  }
}
