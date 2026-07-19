/// App Drawer dialogs: create/rename/manage groups and fetch-missing.
///
/// Top-level functions taking explicit parameters — no page state captured.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_icon_controller.dart';
import '../../services/icon_fetch_strategy.dart';
import '../../services/log_service.dart';
import '../../theme/app_theme_colors.dart';
import '../../widgets/app_snackbar.dart';
import 'app_drawer_tiles.dart';

/// Creates a new group; when [movePackage] is given, moves that package into
/// the freshly created group.
Future<void> showCreateGroupDialog(
  BuildContext context,
  AppIconController controller, {
  String? movePackage,
}) async {
  final nameController = TextEditingController();
  await showDialog(
    context: context,
    builder: (ctx) {
      void submit() {
        final name = nameController.text.trim();
        if (name.isEmpty) return;
        controller.createGroup(name);
        if (movePackage != null) {
          controller.moveToGroup(
            movePackage,
            controller.appDrawerSettings.groups.length - 1,
          );
        }
        Navigator.pop(ctx);
      }

      return AlertDialog(
        backgroundColor: ctx.appSurface,
        title: Text(
          'New Group',
          style: TextStyle(color: ctx.appTextPrimary),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: ctx.appTextPrimary),
          decoration: InputDecoration(
            hintText: 'Group name',
            hintStyle: TextStyle(color: ctx.appTextSecondary),
          ),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appTextSecondary),
            ),
          ),
          TextButton(
            onPressed: submit,
            child: Text('Create', style: TextStyle(color: context.appPrimary)),
          ),
        ],
      );
    },
  );
  nameController.dispose();
}

/// Renames the group at [index]; [setDialogState] refreshes the caller's
/// surrounding UI (manage-groups dialog or the page) after the rename.
Future<void> showRenameGroupDialog(
  BuildContext context,
  AppIconController controller,
  int index,
  void Function(void Function()) setDialogState,
) async {
  final nameController = TextEditingController(
    text: controller.appDrawerSettings.groups[index].name,
  );
  await showDialog(
    context: context,
    builder: (ctx) {
      void submit() {
        final name = nameController.text.trim();
        if (name.isEmpty) return;
        controller.renameGroup(index, name);
        setDialogState(() {});
        Navigator.pop(ctx);
      }

      return AlertDialog(
        backgroundColor: ctx.appSurface,
        title: Text(
          'Rename Group',
          style: TextStyle(color: ctx.appTextPrimary),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: ctx.appTextPrimary),
          decoration: InputDecoration(
            hintText: 'Group name',
            hintStyle: TextStyle(color: ctx.appTextSecondary),
          ),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appTextSecondary),
            ),
          ),
          TextButton(
            onPressed: submit,
            child: Text('Rename', style: TextStyle(color: context.appPrimary)),
          ),
        ],
      );
    },
  );
  nameController.dispose();
}

void showManageGroupsDialog(
  BuildContext context,
  AppIconController controller,
) {
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final groups = controller.appDrawerSettings.groups;
        return AlertDialog(
          backgroundColor: ctx.appSurface,
          title: Row(
            children: [
              Icon(Icons.folder_outlined, color: context.appPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Manage Groups',
                style: TextStyle(color: ctx.appTextPrimary, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: groups.isEmpty
                      ? Center(
                          child: Text(
                            'No groups yet. Create one below.',
                            style: TextStyle(
                              color: ctx.appTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: groups.length,
                          itemBuilder: (ctx, index) {
                            final group = groups[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: ctx.appBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ctx.appDivider),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.folder,
                                    size: 20,
                                    color: context.appPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => showRenameGroupDialog(
                                        context,
                                        controller,
                                        index,
                                        setDialogState,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              group.name,
                                              style: TextStyle(
                                                color: ctx.appTextPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${group.items.length})',
                                            style: TextStyle(
                                              color: ctx.appTextSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (group.isAutoGenerated) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: context.appPrimary
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'auto',
                                                style: TextStyle(
                                                  color: context.appPrimary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_upward,
                                      size: 18,
                                      color: index > 0
                                          ? ctx.appTextSecondary
                                          : ctx.appDivider,
                                    ),
                                    onPressed: index > 0
                                        ? () {
                                            controller.reorderGroup(
                                              index,
                                              index - 1,
                                            );
                                            setDialogState(() {});
                                          }
                                        : null,
                                    splashRadius: 16,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_downward,
                                      size: 18,
                                      color: index < groups.length - 1
                                          ? ctx.appTextSecondary
                                          : ctx.appDivider,
                                    ),
                                    onPressed: index < groups.length - 1
                                        ? () {
                                            controller.reorderGroup(
                                              index,
                                              index + 1,
                                            );
                                            setDialogState(() {});
                                          }
                                        : null,
                                    splashRadius: 16,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red.shade300,
                                    ),
                                    onPressed: () {
                                      controller.deleteGroup(index);
                                      setDialogState(() {});
                                    },
                                    splashRadius: 16,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showCreateGroupDialog(
                      context,
                      controller,
                    ).then((_) => setDialogState(() {})),
                    icon: Icon(Icons.add, size: 18, color: context.appPrimary),
                    label: Text(
                      'Add Group',
                      style: TextStyle(color: context.appPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.appPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Done', style: TextStyle(color: context.appPrimary)),
            ),
          ],
        );
      },
    ),
  );
}

/// Shows the fetch-missing-icons dialog and starts the fetch on confirm.
Future<void> showFetchMissingDialog(BuildContext context) async {
  final controller = context.read<AppIconController>();

  final missingCount = controller.labels.keys.where((pkg) {
    final hasIcon =
        controller.icons[pkg] != null && controller.icons[pkg]!.path.isNotEmpty;
    final hasLabel = controller.labels[pkg] != pkg;
    return !hasIcon || !hasLabel;
  }).length;

  var autoInstall = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          backgroundColor: ctx.appSurface,
          title: Text(
            'Fetch Missing Icons & Labels',
            style: TextStyle(color: ctx.appTextPrimary),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  missingCount > 0
                      ? '$missingCount app${missingCount == 1 ? '' : 's'} '
                            'have missing icons or labels.'
                      : 'All apps are up to date.',
                  style: TextStyle(
                    color: ctx.appTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Fetch method',
                  style: TextStyle(
                    color: ctx.appTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: ctx.appBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ctx.appDivider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.appDrawerSettings.iconFetchMethod.name,
                      isDense: true,
                      isExpanded: true,
                      style: TextStyle(
                        color: ctx.appTextPrimary,
                        fontSize: 13,
                      ),
                      dropdownColor: ctx.appSurface,
                      items: const [
                        DropdownMenuItem(
                          value: 'helperApk',
                          child: Text('Helper APK'),
                        ),
                        DropdownMenuItem(
                          value: 'adbScrape',
                          child: Text('ADB'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            controller.setIconFetchMethod(
                              iconFetchMethodFromString(value),
                            );
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (controller.appDrawerSettings.iconFetchMethod ==
                    IconFetchMethod.helperApk) ...[
                  const SizedBox(height: 10),
                  CheckboxRow(
                    label: 'Auto-install via ADB',
                    value: autoInstall,
                    onChanged: (v) =>
                        setDialogState(() => autoInstall = v ?? false),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(
                        'https://github.com/GeorgeEnglezos/android-icon-label-exporter-apk',
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: ctx.appTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Source: github.com/GeorgeEnglezos/android-icon-label-exporter-apk',
                            style: TextStyle(
                              color: ctx.appTextSecondary,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: ctx.appTextSecondary),
              ),
            ),
            TextButton(
              onPressed: missingCount > 0
                  ? () {
                      Navigator.pop(ctx);
                      controller.fetchMissingOnly(
                        helperApkAutoInstall: autoInstall,
                        onError: (message) {
                          LogService.error(
                            'AppDrawer/fetchMissingOnly',
                            message,
                          );
                          if (!context.mounted) return;
                          showAppSnackBar(
                            context,
                            message,
                            type: AppSnackBarType.error,
                            duration: const Duration(seconds: 6),
                          );
                        },
                      );
                    }
                  : null,
              child: Text(
                'Continue',
                style: TextStyle(
                  color: missingCount > 0
                      ? context.appPrimary
                      : ctx.appTextSecondary,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
