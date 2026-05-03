import 'dart:convert';

import 'scrcpy_command.dart';

class PanelSettings {
  final String id;
  final bool visible;
  final bool isFullWidth;
  final bool lockedExpanded;
  final String displayName;

  const PanelSettings({
    required this.id,
    this.visible = true,
    this.isFullWidth = false,
    this.lockedExpanded = false,
    required this.displayName,
  });

  PanelSettings copyWith({
    bool? visible,
    bool? isFullWidth,
    bool? lockedExpanded,
    String? displayName,
  }) {
    return PanelSettings(
      id: id,
      visible: visible ?? this.visible,
      isFullWidth: isFullWidth ?? this.isFullWidth,
      lockedExpanded: lockedExpanded ?? this.lockedExpanded,
      displayName: displayName ?? this.displayName,
    );
  }

  factory PanelSettings.fromJson(Map<String, dynamic> json) {
    return PanelSettings(
      id: json['id'] as String,
      visible: json['visible'] as bool? ?? true,
      isFullWidth: json['isFullWidth'] as bool? ?? false,
      lockedExpanded: json['lockedExpanded'] as bool? ?? false,
      displayName: json['displayName'] as String? ?? json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visible': visible,
      'isFullWidth': isFullWidth,
      'lockedExpanded': lockedExpanded,
      'displayName': displayName,
    };
  }
}

/// Default panel order. Builds a fresh list on every call so callers can
/// safely mutate the result without affecting future calls.
List<PanelSettings> buildDefaultPanels() => [
      const PanelSettings(
        id: 'actions',
        displayName: 'Command Actions',
        isFullWidth: true,
        lockedExpanded: true,
      ),
      const PanelSettings(id: 'package', displayName: 'Package Commands'),
      const PanelSettings(id: 'audio', displayName: 'Audio Commands'),
      const PanelSettings(id: 'common', displayName: 'Common Commands'),
      const PanelSettings(
        id: 'camera',
        displayName: 'Camera Commands',
        visible: false,
      ),
      const PanelSettings(
        id: 'input',
        displayName: 'Input Control',
        visible: false,
      ),
      const PanelSettings(
        id: 'display',
        displayName: 'Display/Window',
        visible: false,
      ),
      const PanelSettings(
        id: 'network',
        displayName: 'Network/Connection',
        visible: false,
      ),
      const PanelSettings(id: 'virtual', displayName: 'Virtual Display Commands'),
      const PanelSettings(id: 'recording', displayName: 'Recording Commands'),
      const PanelSettings(
        id: 'advanced',
        displayName: 'Advanced/Developer',
        visible: false,
      ),
      const PanelSettings(id: 'otg', displayName: 'OTG Mode', visible: false),
      const PanelSettings(
        id: 'running',
        displayName: 'Running Instances',
        visible: false,
      ),
    ];

/// App-wide settings. Immutable — use [copyWith] to derive a new instance.
class AppSettings {
  final List<PanelSettings> panelOrder;
  final String scrcpyDirectory;
  final String recordingsDirectory;
  final String downloadsDirectory;
  final String batDirectory; // NOTE: Also stores .sh/.command files on macOS/Linux
  final bool openCmdWindows;
  final bool showBatFilesTab; // NOTE: Shows script files on all platforms
  final bool showAppDrawerTab;
  final bool showManualIpInput;
  final String bootTab;
  final String settingsDirectory;
  final List<String> shortcutMod;
  final bool checkForUpdatesOnStartup;
  final bool loggingEnabled;
  final bool fileLoggingEnabled;
  final ScrcpyCommand? defaultPreset;

  AppSettings({
    required List<PanelSettings> panelOrder,
    required this.scrcpyDirectory,
    required this.recordingsDirectory,
    required this.downloadsDirectory,
    required this.batDirectory,
    this.openCmdWindows = false,
    this.showBatFilesTab = true,
    this.showAppDrawerTab = true,
    this.showManualIpInput = false,
    this.bootTab = 'Home',
    this.settingsDirectory = '',
    List<String> shortcutMod = const [],
    this.checkForUpdatesOnStartup = true,
    this.loggingEnabled = false,
    this.fileLoggingEnabled = false,
    this.defaultPreset,
  })  : panelOrder = List.unmodifiable(panelOrder),
        shortcutMod = List.unmodifiable(shortcutMod);

  /// Returns a new instance with the given fields replaced. To set
  /// [defaultPreset] back to null explicitly, pass [clearDefaultPreset] = true.
  AppSettings copyWith({
    List<PanelSettings>? panelOrder,
    String? scrcpyDirectory,
    String? recordingsDirectory,
    String? downloadsDirectory,
    String? batDirectory,
    bool? openCmdWindows,
    bool? showBatFilesTab,
    bool? showAppDrawerTab,
    bool? showManualIpInput,
    String? bootTab,
    String? settingsDirectory,
    List<String>? shortcutMod,
    bool? checkForUpdatesOnStartup,
    bool? loggingEnabled,
    bool? fileLoggingEnabled,
    ScrcpyCommand? defaultPreset,
    bool clearDefaultPreset = false,
  }) {
    return AppSettings(
      panelOrder: panelOrder ?? this.panelOrder,
      scrcpyDirectory: scrcpyDirectory ?? this.scrcpyDirectory,
      recordingsDirectory: recordingsDirectory ?? this.recordingsDirectory,
      downloadsDirectory: downloadsDirectory ?? this.downloadsDirectory,
      batDirectory: batDirectory ?? this.batDirectory,
      openCmdWindows: openCmdWindows ?? this.openCmdWindows,
      showBatFilesTab: showBatFilesTab ?? this.showBatFilesTab,
      showAppDrawerTab: showAppDrawerTab ?? this.showAppDrawerTab,
      showManualIpInput: showManualIpInput ?? this.showManualIpInput,
      bootTab: bootTab ?? this.bootTab,
      settingsDirectory: settingsDirectory ?? this.settingsDirectory,
      shortcutMod: shortcutMod ?? this.shortcutMod,
      checkForUpdatesOnStartup:
          checkForUpdatesOnStartup ?? this.checkForUpdatesOnStartup,
      loggingEnabled: loggingEnabled ?? this.loggingEnabled,
      fileLoggingEnabled: fileLoggingEnabled ?? this.fileLoggingEnabled,
      defaultPreset:
          clearDefaultPreset ? null : (defaultPreset ?? this.defaultPreset),
    );
  }

  factory AppSettings.defaultSettings() {
    return AppSettings(
      panelOrder: buildDefaultPanels(),
      scrcpyDirectory: '',
      recordingsDirectory: '',
      downloadsDirectory: '',
      batDirectory: '',
      openCmdWindows: false,
      showBatFilesTab: true,
      showAppDrawerTab: true,
      showManualIpInput: false,
      bootTab: 'Home',
      settingsDirectory: '',
      shortcutMod: const [],
      checkForUpdatesOnStartup: true,
      loggingEnabled: false,
      fileLoggingEnabled: false,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      panelOrder:
          (json['panelOrder'] as List<dynamic>?)
              ?.map((e) => PanelSettings.fromJson(e))
              .toList() ??
          buildDefaultPanels(),
      scrcpyDirectory: json['scrcpyDirectory'] as String? ?? '',
      recordingsDirectory: json['recordingsDirectory'] as String? ?? '',
      downloadsDirectory: json['downloadsDirectory'] as String? ?? '',
      batDirectory: json['batDirectory'] as String? ?? '',
      openCmdWindows: json['openCmdWindows'] as bool? ?? false,
      showBatFilesTab: json['showBatFilesTab'] as bool? ?? true,
      showAppDrawerTab: json['showAppDrawerTab'] as bool? ?? true,
      showManualIpInput: json['showManualIpInput'] as bool? ?? false,
      bootTab: json['bootTab'] as String? ?? 'Home',
      shortcutMod:
          (json['shortcutMod'] as List<dynamic>?)?.cast<String>() ?? [],
      checkForUpdatesOnStartup: json['checkForUpdatesOnStartup'] as bool? ?? true,
      loggingEnabled: json['loggingEnabled'] as bool? ?? false,
      fileLoggingEnabled: json['fileLoggingEnabled'] as bool? ?? false,
      defaultPreset: json['defaultPreset'] != null
          ? ScrcpyCommand.fromJson(
              json['defaultPreset'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'panelOrder': panelOrder.map((e) => e.toJson()).toList(),
      'scrcpyDirectory': scrcpyDirectory,
      'recordingsDirectory': recordingsDirectory,
      'downloadsDirectory': downloadsDirectory,
      'batDirectory': batDirectory,
      'openCmdWindows': openCmdWindows,
      'showBatFilesTab': showBatFilesTab,
      'showAppDrawerTab': showAppDrawerTab,
      'showManualIpInput': showManualIpInput,
      'bootTab': bootTab,
      'shortcutMod': shortcutMod,
      'checkForUpdatesOnStartup': checkForUpdatesOnStartup,
      'loggingEnabled': loggingEnabled,
      'fileLoggingEnabled': fileLoggingEnabled,
      if (defaultPreset != null) 'defaultPreset': defaultPreset!.toJson(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory AppSettings.fromJsonString(String jsonString) =>
      AppSettings.fromJson(jsonDecode(jsonString));
}
