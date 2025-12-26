import 'package:flutter/material.dart';
import '../widgets/command_panel.dart';
import '../widgets/surrounding_panel.dart';
import '../services/terminal_service.dart';
import '../theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Categories of external URLs
    final officialScrcpy = [
      {
        'title': 'Scrcpy',
        'description': 'Official GitHub repository for Scrcpy project.',
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
            'I promise I will update the docs some day. Use your instinct for the time being!',
        'url': 'https://github.com/GeorgeEnglezos/Scrcpy-GUI#readme',
      },
      {
        'title': 'Issues',
        'description':
            'Any feedback is appreciated, good or bad. There are no bad ideas, only things I am bored of implementing',
        'url': 'https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues',
      },
      {
        'title': 'Web Scrcpy',
        'description': 'A very light web version of the app built with Angular',
        'url': 'https://scrcpy-ui.web.app/',
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
            'You can install Scrcpy using Scoop, Chocolatey on Windows, Brew on macOS, or apt on Linux. '
            'See the Install / Uninstall section above.',
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
            'Please open an issue on the GitHub repository at https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues with details about the bug and your platform.',
      },
    ];

    // Install / Uninstall commands for Scrcpy
    final scrcpyCommands = [
      // Scoop (Windows)
      'scoop install scrcpy',
      'scoop uninstall scrcpy',
      // Chocolatey (Windows)
      'choco install scrcpy',
      'choco uninstall scrcpy',
      // Homebrew (macOS)
      'brew install scrcpy',
      'brew uninstall scrcpy',
      // APT (Linux)
      'sudo apt install scrcpy',
      'sudo apt remove scrcpy',
    ];

    // Install / Uninstall commands for ADB
    final adbCommands = [
      // Scoop (Windows)
      'scoop install adb',
      'scoop uninstall adb',
      // Chocolatey (Windows)
      'choco install adb',
      'choco uninstall adb',
      // Homebrew (macOS)
      'brew install --cask android-platform-tools',
      'brew uninstall --cask android-platform-tools',
      // APT (Linux)
      'sudo apt install adb',
      'sudo apt remove adb',
    ];

    // Helpful troubleshooting commands
    final helpfulCommands = [
      'adb devices',
      'adb shell pm list packages',
      'scrcpy --list-encoders',
      'scrcpy --version',
      'scrcpy --help',
    ];

    Widget buildCategory(String title, List<Map<String, String>> links) {
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
                maxHeight: 400,
                minWidth: 200,
                maxWidth: 400,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final url = Uri.parse(link['url']!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.commandGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link['title']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        link['description']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    faq['answer']!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Fixed header at the top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Developed by George Englezos',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'v$_version',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
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
            buildFaqs(),
            const SizedBox(height: 24),

            // Responsive 3-column layout for command panels
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate number of columns based on available width
                // 3 columns at full screen (>1000px), 2 columns at medium (>650px), 1 column at small
                final double availableWidth = constraints.maxWidth;
                final int columns = availableWidth > 1000 ? 3 : (availableWidth > 650 ? 2 : 1);
                final double itemWidth = (availableWidth - (24 * (columns - 1))) / columns;

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
                          children: scrcpyCommands.map((cmd) {
                            return CommandPanel(
                              command: cmd,
                              showDelete: false,
                              onTap: () async {
                                await TerminalService.runCommandInNewTerminal(cmd);
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
                          children: adbCommands.map((cmd) {
                            return CommandPanel(
                              command: cmd,
                              showDelete: false,
                              onTap: () async {
                                await TerminalService.runCommandInNewTerminal(cmd);
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
                                await TerminalService.runCommandInNewTerminal(cmd);
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
}
