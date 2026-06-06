import 'package:flutter/material.dart';
import '../widgets/command_panel.dart';
import '../widgets/surrounding_panel.dart';
import '../services/log_service.dart';
import '../services/terminal_service.dart';
import '../theme/app_theme_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_service.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  String _version = '';
  UpdateService? _nightlyResult;
  bool _hideNightlyBanner = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkNightlyOnOpen();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  Future<void> _checkNightlyOnOpen() async {
    final result = await UpdateService.checkForUpdate();
    if (result.hasNightlyUpdate && mounted) {
      setState(() => _nightlyResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Categories of external URLs
    final officialScrcpy = [
      {
        'title': 'Scrcpy',
        'description': 'Official GitHub repository for the scrcpy project.',
        'url': 'https://github.com/Genymobile/scrcpy',
      },
      {
        'title': 'Documentation',
        'description': 'Read the full README and setup instructions.',
        'url': 'https://github.com/Genymobile/scrcpy#readme',
      },
      {
        'title': 'Issues',
        'description': 'Track issues and contribute to development.',
        'url': 'https://github.com/Genymobile/scrcpy/issues',
      },
    ];

    final similarProjects = [
      {
        'title': 'QtScrcpy (by barry-ran)',
        'description':
            'A Qt-based GUI project for displaying and controlling Android devices with scrcpy.',
        'url': 'https://github.com/barry-ran/QtScrcpy',
      },
      {
        'title': 'flutter-scrcpygui (by pizi-0)',
        'description':
            'A Flutter-based scrcpy GUI project with desktop-focused controls and features.',
        'url': 'https://github.com/pizi-0/flutter-scrcpygui',
      },
    ];

    final myScrcpyGui = [
      {
        'title': 'Scrcpy GUI',
        'description':
            'The application you are currently staring at. Thank you for using it!',
        'url': 'https://github.com/GeorgeEnglezos/Scrcpy-GUI',
      },
      {
        'title': 'Documentation',
        'description':
            'I promise I will update the docs someday. Use your instinct for the time being!',
        'url': 'https://github.com/GeorgeEnglezos/Scrcpy-GUI#readme',
      },
      {
        'title': 'Issues',
        'description':
            'Any feedback is appreciated, good or bad. There are no bad ideas, only things I am bored of implementing.',
        'url': 'https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues/new',
      },
      {
        'title': 'Web Scrcpy',
        'description':
            'A very light web version of the app built with Angular.',
        'url': 'https://scrcpy-ui.web.app/',
      },
      {
        'title': 'Helper APK',
        'description':
            'The Android helper app used by ScrcpyGUI to extract app icons and labels directly from your device.',
        'url':
            'https://github.com/GeorgeEnglezos/android-icon-label-exporter-apk',
      },
      {
        'title': 'Support',
        'description':
            'Here is my Paypal if you want to support me. Thank you very much!',
        'url': 'http://paypal.me/GeorgeEnglezos',
      },
    ];

    // FAQ Questions & Answers
    final faqs = [
      {
        'question': "Why doesn't the app work?",
        'answer':
            "This app doesn't ship with scrcpy; you need to download it separately. "
            "If you have scrcpy and 'scrcpy --version' works, make sure USB debugging is enabled on your Android device.",
      },
      {
        'question': 'How do I install Scrcpy?',
        'answer':
            'You can install Scrcpy using Winget, Scoop or Chocolatey on Windows, Brew on macOS, or your '
            'distro package manager on Linux (apt for Debian/Ubuntu, pacman for Arch, dnf for Fedora, '
            'zypper for openSUSE, or snap on any distro). See the Install / Uninstall section above.',
      },
      {
        'question': 'Why can’t I see my device?',
        'answer':
            'Make sure USB debugging is enabled on your Android device and that your computer can detect it with "adb devices".',
      },
      {
        'question': 'Can I use this GUI for Scrcpy on any OS?',
        'answer':
            'Yes, the GUI is built using Flutter and runs on Windows, macOS, and Linux. '
            'If you find a bug, please specify the platform.',
      },
      {
        'question': 'Is the app in active development?',
        'answer':
            "I don't have a specific schedule for updates; they are random whenever I think of something cool or a bug is found.",
      },
      {
        'question': 'I found a bug! Where do I report it?',
        'answer':
            'Please open an issue on the GitHub repository at https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues/new with details about the bug and your platform.',
      },
    ];

    // Install / Uninstall commands for Scrcpy.
    // 'label' identifies the OS / Linux distro so users can pick the right one;
    // 'command' is the actual command that gets run / copied.
    final scrcpyCommands = [
      // Windows
      {'label': 'Winget', 'command': 'winget install Genymobile.scrcpy'},
      {'label': 'Winget', 'command': 'winget uninstall Genymobile.scrcpy'},
      {'label': 'Scoop', 'command': 'scoop install scrcpy'},
      {'label': 'Scoop', 'command': 'scoop uninstall scrcpy'},
      {'label': 'Chocolatey', 'command': 'choco install scrcpy'},
      {'label': 'Chocolatey', 'command': 'choco uninstall scrcpy'},
      // macOS
      {'label': 'Homebrew', 'command': 'brew install scrcpy'},
      {'label': 'Homebrew', 'command': 'brew uninstall scrcpy'},
      // Linux - Debian / Ubuntu (apt)
      {'label': 'Debian/Ubuntu', 'command': 'sudo apt install scrcpy'},
      {'label': 'Debian/Ubuntu', 'command': 'sudo apt remove scrcpy'},
      // Linux - Arch (pacman)
      {'label': 'Arch', 'command': 'sudo pacman -S scrcpy'},
      {'label': 'Arch', 'command': 'sudo pacman -R scrcpy'},
      // Linux - Fedora (dnf)
      {'label': 'Fedora', 'command': 'sudo dnf install scrcpy'},
      {'label': 'Fedora', 'command': 'sudo dnf remove scrcpy'},
      // Linux - openSUSE (zypper)
      {'label': 'openSUSE', 'command': 'sudo zypper install scrcpy'},
      {'label': 'openSUSE', 'command': 'sudo zypper remove scrcpy'},
      // Linux - universal (snap)
      {'label': 'Snap (any)', 'command': 'sudo snap install scrcpy'},
      {'label': 'Snap (any)', 'command': 'sudo snap remove scrcpy'},
    ];

    // Install / Uninstall commands for ADB (Android platform tools).
    final adbCommands = [
      // Windows
      {'label': 'Winget', 'command': 'winget install Google.PlatformTools'},
      {'label': 'Winget', 'command': 'winget uninstall Google.PlatformTools'},
      {'label': 'Scoop', 'command': 'scoop install adb'},
      {'label': 'Scoop', 'command': 'scoop uninstall adb'},
      {'label': 'Chocolatey', 'command': 'choco install adb'},
      {'label': 'Chocolatey', 'command': 'choco uninstall adb'},
      // macOS
      {
        'label': 'Homebrew',
        'command': 'brew install --cask android-platform-tools',
      },
      {
        'label': 'Homebrew',
        'command': 'brew uninstall --cask android-platform-tools',
      },
      // Linux - Debian / Ubuntu (apt)
      {'label': 'Debian/Ubuntu', 'command': 'sudo apt install adb'},
      {'label': 'Debian/Ubuntu', 'command': 'sudo apt remove adb'},
      // Linux - Arch (pacman)
      {'label': 'Arch', 'command': 'sudo pacman -S android-tools'},
      {'label': 'Arch', 'command': 'sudo pacman -R android-tools'},
      // Linux - Fedora (dnf)
      {'label': 'Fedora', 'command': 'sudo dnf install android-tools'},
      {'label': 'Fedora', 'command': 'sudo dnf remove android-tools'},
      // Linux - openSUSE (zypper)
      {'label': 'openSUSE', 'command': 'sudo zypper install android-tools'},
      {'label': 'openSUSE', 'command': 'sudo zypper remove android-tools'},
    ];

    // Helpful troubleshooting commands
    final helpfulCommands = [
      'adb devices',
      'adb shell pm list packages',
      'scrcpy --list-encoders',
      'scrcpy --version',
      'scrcpy --help',
    ];

    // Small badge shown before a command, naming the OS / Linux distro it
    // applies to (e.g. "Arch", "Fedora") so users can find the right one.
    Widget labelChip(String text) {
      return Container(
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: context.appPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.appPrimary,
          ),
        ),
      );
    }

    Widget buildCategory(String title, List<Map<String, String>> links) {
      final cardColor = context.appCommandSurface;
      final titleColor = context.appTextPrimary;
      final descriptionColor = context.appTextSecondary;
      return SurroundingPanel(
        icon: Icons.link,
        title: title,
        showButton: false,
        contentPadding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: links.map((link) {
            return ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 150,
                maxHeight: 150,
                maxWidth: 400,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final url = Uri.parse(link['url']!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    LogService.warning(
                      'ResourcesPage/openLink',
                      'Cannot open ${link['url']}',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cannot open ${link['url']}'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appDivider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        link['title']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        link['description']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: descriptionColor),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            // same as card tap
                            final url = Uri.parse(link['url']!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              LogService.warning(
                                'ResourcesPage/openLink',
                                'Cannot open ${link['url']}',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cannot open ${link['url']}'),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Open'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    Widget buildFaqs() {
      final titleColor = context.appTextPrimary;
      final answerColor = context.appTextSecondary;
      return SurroundingPanel(
        icon: Icons.question_answer,
        title: 'FAQs',
        showButton: false,
        contentPadding: const EdgeInsets.all(12),
        child: Column(
          children: faqs.map((faq) {
            return ExpansionTile(
              title: Text(
                faq['question']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              iconColor: context.appPrimary,
              collapsedIconColor: answerColor,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    faq['answer']!,
                    style: TextStyle(color: answerColor),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: [
          // Fixed header at the top
          Column(
            children: [
              if (_nightlyResult != null && !_hideNightlyBanner)
                _buildNightlyBanner(_nightlyResult!),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.appPrimary.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: context.appPrimary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.appPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: context.appPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Developed by George Englezos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.appPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v$_version',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.appPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCategory('Official Scrcpy', officialScrcpy),
                  const SizedBox(height: 24),
                  buildCategory('My Scrcpy GUI', myScrcpyGui),
                  const SizedBox(height: 24),
                  buildCategory(
                    'Similar Projects Worth Checking Out',
                    similarProjects,
                  ),
                  const SizedBox(height: 24),
                  buildFaqs(),
                  const SizedBox(height: 32),

                  // Responsive 3-column layout for command panels
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate number of columns based on available width
                      // 3 columns at full screen (>1000px), 2 columns at medium (>650px), 1 column at small
                      final double availableWidth = constraints.maxWidth;
                      final int columns = availableWidth > 1000
                          ? 3
                          : (availableWidth > 650 ? 2 : 1);
                      final double itemWidth =
                          (availableWidth - (24 * (columns - 1))) / columns;

                      return Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          // Scrcpy Install/Uninstall Panel
                          SizedBox(
                            width: itemWidth,
                            child: SurroundingPanel(
                              icon: Icons.download,
                              title: 'Install / Uninstall Scrcpy',
                              showButton: false,
                              contentPadding: const EdgeInsets.all(12),
                              child: Column(
                                children: scrcpyCommands.map((entry) {
                                  final cmd = entry['command']!;
                                  return CommandPanel(
                                    command: cmd,
                                    leading: labelChip(entry['label']!),
                                    showDelete: false,
                                    onTap: () async {
                                      await TerminalService.runCommandInNewTerminal(
                                        cmd,
                                      );
                                    },
                                    onDownload: null,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          // ADB Install/Uninstall Panel
                          SizedBox(
                            width: itemWidth,
                            child: SurroundingPanel(
                              icon: Icons.download,
                              title: 'Install / Uninstall ADB',
                              showButton: false,
                              contentPadding: const EdgeInsets.all(12),
                              child: Column(
                                children: adbCommands.map((entry) {
                                  final cmd = entry['command']!;
                                  return CommandPanel(
                                    command: cmd,
                                    leading: labelChip(entry['label']!),
                                    showDelete: false,
                                    onTap: () async {
                                      await TerminalService.runCommandInNewTerminal(
                                        cmd,
                                      );
                                    },
                                    onDownload: null,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          // Helpful Commands Panel
                          SizedBox(
                            width: itemWidth,
                            child: SurroundingPanel(
                              icon: Icons.build_circle,
                              title: 'Helpful Commands',
                              showButton: false,
                              contentPadding: const EdgeInsets.all(12),
                              child: Column(
                                children: helpfulCommands.map((cmd) {
                                  return CommandPanel(
                                    command: cmd,
                                    showDelete: false,
                                    onTap: () async {
                                      await TerminalService.runCommandInNewTerminal(
                                        cmd,
                                      );
                                    },
                                    onDownload: null,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNightlyBanner(UpdateService result) {
    final nightly = result.nightlyInfo!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Nightly Build Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'v${nightly.version}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () =>
                UpdateService.launchReleasePage(nightly.downloadUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Download Nightly'),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => setState(() => _hideNightlyBanner = true),
            icon: Icon(Icons.close, color: context.appTextSecondary, size: 20),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
