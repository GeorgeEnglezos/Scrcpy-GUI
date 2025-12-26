import 'dart:convert';

class PanelSettings {
  String id;
  bool visible;
  bool isFullWidth;
  bool lockedExpanded;
  String displayName;

  PanelSettings({
    required this.id,
    this.visible = true,
    this.isFullWidth = false,
    this.lockedExpanded = false,
    required this.displayName,
  });

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

/// Default panel order
List<PanelSettings> defaultPanels = [
  PanelSettings(
    id: 'actions',
    displayName: 'Command Actions',
    isFullWidth: true,
    lockedExpanded: true,
  ),
  PanelSettings(id: 'package', displayName: 'Package Commands'),
  PanelSettings(id: 'audio', displayName: 'Audio Commands'),
  PanelSettings(id: 'common', displayName: 'Common Commands'),
  PanelSettings(id: 'camera', displayName: 'Camera Commands', visible: false),
  PanelSettings(id: 'input', displayName: 'Input Control', visible: false),
  PanelSettings(id: 'display', displayName: 'Display/Window', visible: false),
  PanelSettings(id: 'network', displayName: 'Network/Connection', visible: false),
  PanelSettings(id: 'virtual', displayName: 'Virtual Display Commands'),
  PanelSettings(id: 'recording', displayName: 'Recording Commands'),
  PanelSettings(id: 'advanced', displayName: 'Advanced/Developer', visible: false),
  PanelSettings(id: 'otg', displayName: 'OTG Mode', visible: false),
  PanelSettings(id: 'running', displayName: 'Running Instances', visible: false),
];

/// App-wide settings
class AppSettings {
  List<PanelSettings> panelOrder;
  String scrcpyDirectory;
  String recordingsDirectory;
  String downloadsDirectory;
  String batDirectory; // NOTE: Also stores .sh/.command files on macOS/Linux
  bool openCmdWindows;
  bool showBatFilesTab; // NOTE: Shows script files on all platforms
  String bootTab;
  String settingsDirectory;

  AppSettings({
    required this.panelOrder,
    required this.scrcpyDirectory,
    required this.recordingsDirectory,
    required this.downloadsDirectory,
    required this.batDirectory,
    this.openCmdWindows = false,
    this.showBatFilesTab = true,
    this.bootTab = 'Home',
    this.settingsDirectory = '',
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      panelOrder: defaultPanels,
      scrcpyDirectory: '',
      recordingsDirectory: '',
      downloadsDirectory: '',
      batDirectory: '',
      openCmdWindows: false,
      showBatFilesTab: true,
      bootTab: 'Home',
      settingsDirectory: '',
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      panelOrder:
          (json['panelOrder'] as List<dynamic>?)
              ?.map((e) => PanelSettings.fromJson(e))
              .toList() ??
          defaultPanels,
      scrcpyDirectory: json['scrcpyDirectory'] as String? ?? '',
      recordingsDirectory: json['recordingsDirectory'] as String? ?? '',
      downloadsDirectory: json['downloadsDirectory'] as String? ?? '',
      batDirectory: json['batDirectory'] as String? ?? '',
      openCmdWindows: json['openCmdWindows'] as bool? ?? false,
      showBatFilesTab: json['showBatFilesTab'] as bool? ?? true,
      bootTab: json['bootTab'] as String? ?? 'Home',
      settingsDirectory: json['settingsDirectory'] as String? ?? '',
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
      'bootTab': bootTab,
      'settingsDirectory': settingsDirectory,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory AppSettings.fromJsonString(String jsonString) =>
      AppSettings.fromJson(jsonDecode(jsonString));
}
