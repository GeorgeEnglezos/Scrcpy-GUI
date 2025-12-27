# API Reference

Core services and models for Scrcpy GUI Flutter.

## Services

### TerminalService
`lib/services/terminal_service.dart`

Static service for executing commands and managing processes.

**Key methods:**
```dart
static Future<String> runCommand(String command)
// Execute command and return output

static Future<void> runCommandInNewTerminal(String command)
// Open new terminal window and execute

static Future<List<Map<String, String>>> getScrcpyProcesses()
// Get all running scrcpy processes with details (PID, device, memory, etc.)

static Future<void> killProcess(int pid)
// Terminate process by PID

static Future<List<String>> adbDevices()
// List connected devices

static Future<List<String>> listPackages({required String deviceId, bool includeSystemApps = false})
// List installed packages on device

static Future<String> loadScrcpyEncoders({required String deviceId})
// Get available encoders from device

static List<String> parseVideoEncoders(String scrcpyOutput)
static List<String> parseAudioEncoders(String scrcpyOutput)
// Parse encoder output to extract codecs

static Future<String> enableTcpip(String deviceId, int port)
// Enable TCP/IP mode on device

static Future<String?> getDeviceIpAddress(String deviceId)
// Get device IP address

static Future<String> connectWireless(String ipAddress, int port)
// Connect to device wirelessly

static Future<Map<String, dynamic>> setupWirelessConnection(String deviceId, int port)
// Complete wireless connection workflow
```

### DeviceManagerService
`lib/services/device_manager_service.dart`

Manages device detection and information caching. Extends `ChangeNotifier`.

**Properties:**
```dart
static final Map<String, PhoneInfoModel> devicesInfo  // Global device cache
String? selectedDevice                                 // Currently selected device
final ValueNotifier<String?> selectedDeviceNotifier   // Device selection notifier
```

**Methods:**
```dart
Future<void> initialize()       // Start device polling (call once in main())
PhoneInfoModel? getDeviceInfo(String deviceId)  // Get cached device info
void dispose()                  // Cleanup
```

### CommandBuilderService
`lib/services/command_builder_service.dart`

Builds scrcpy commands from panel options. Extends `ChangeNotifier`.

**Properties:**
```dart
String baseCommand                              // Base scrcpy command
AudioOptions audioOptions                       // Audio settings
ScreenRecordingOptions recordingOptions         // Recording settings
VirtualDisplayOptions virtualDisplayOptions     // Virtual display settings
GeneralCastOptions generalCastOptions          // General settings
CameraOptions cameraOptions                     // Camera settings
InputControlOptions inputControlOptions         // Input control settings
DisplayWindowOptions displayWindowOptions       // Display/window settings
NetworkConnectionOptions networkConnectionOptions // Network settings
AdvancedOptions advancedOptions                // Advanced settings
OtgModeOptions otgModeOptions                  // OTG mode settings
```

**Methods:**
```dart
void updateAudioOptions(AudioOptions options)
void updateRecordingOptions(ScreenRecordingOptions options)
void updateVirtualDisplayOptions(VirtualDisplayOptions options)
void updateGeneralCastOptions(GeneralCastOptions options)
void updateCameraOptions(CameraOptions options)
void updateInputControlOptions(InputControlOptions options)
void updateDisplayWindowOptions(DisplayWindowOptions options)
void updateNetworkConnectionOptions(NetworkConnectionOptions options)
void updateAdvancedOptions(AdvancedOptions options)
void updateOtgModeOptions(OtgModeOptions options)

String get fullCommand  // Generates complete scrcpy command
```

### CommandsService
`lib/services/commands_service.dart`

Manages favorites and execution history.

```dart
Future<CommandsData> loadCommands()
Future<void> saveCommands(CommandsData data)
void trackExecution(String command)
void addFavorite(String command)
void removeFavorite(String command)
List<MostUsedCommand> getMostUsed(int count)
```

### SettingsService
`lib/services/settings_service.dart`

Application settings persistence.

```dart
Future<AppSettings> loadSettings()
Future<void> saveSettings(AppSettings settings)
```

## Models

### PhoneInfoModel
```dart
class PhoneInfoModel {
  final String deviceId;
  List<String> packages;              // Installed package names
  Map<String, String> packageLabels;  // Package name -> display label
  List<String> audioCodecs;           // Available audio codecs
  List<String> videoCodecs;           // Available video codecs
}
```

### Option Classes
All have `generateCommandPart()` method that returns command flags.

**AudioOptions:**
- `audioBitRate`, `audioBuffer`, `audioCodecOptions`, `audioCodecEncoderPair`
- `audioCodec`, `audioSource`, `noAudio`, `audioDup`

**ScreenRecordingOptions:**
- `maxSize`, `bitrate`, `framerate`, `outputFormat`, `outputFile`
- `recordOrientation`, `videoCodec`

**VirtualDisplayOptions:**
- `newDisplay`, `resolution`, `dpi`
- `noVdDestroyContent`, `noVdSystemDecorations`

**GeneralCastOptions:**
- Window: `windowTitle`, `fullscreen`, `borderless`, `alwaysOnTop`
- Display: `turnScreenOff`, `stayAwake`, `crop`, `orientation`
- Video: `videoBitrate`, `videoCodec`, `videoEncoder`
- Misc: `disableScreensaver`, `selectedPackage`, `extraParams`

**CameraOptions:**
- `cameraId`, `cameraFacing`, `cameraSize`, `cameraFps`
- `cameraAspectRatio`, `cameraHighSpeed`

**InputControlOptions:**
- `noControl`, `noMouseHover`, `forwardAllClicks`
- `keyboardMode`, `legacyPaste`, `noKeyRepeat`, `rawKeyEvents`, `preferText`
- `mouseMode`, `mouseBind`

**DisplayWindowOptions:**
- `windowX`, `windowY`, `windowWidth`, `windowHeight`
- `rotation`, `displayId`, `displayBuffer`, `renderDriver`, `forceAdbForward`

**NetworkConnectionOptions:**
- `tcpipPort`, `selectTcpip`, `noAdbForward`
- `tunnelHost`, `tunnelPort`

**AdvancedOptions:**
- `verbosity`, `noCleanup`, `noDownsizeOnError`
- `v4l2Sink`, `v4l2Buffer`

**OtgModeOptions:**
- `otg`, `hidKeyboard`, `hidMouse`

### AppSettings
```dart
class AppSettings {
  List<PanelSettings> panelOrder;   // Panel layout (was PanelConfig)
  String scrcpyDirectory;           // scrcpy path
  String recordingsDirectory;       // Recordings path
  String downloadsDirectory;        // Downloads path
  String batDirectory;              // Script files directory
  bool openCmdWindows;             // Open in new terminal
  bool showBatFilesTab;            // Show scripts tab
  String bootTab;                  // Startup tab
  String settingsDirectory;        // Settings storage path
}
```

### PanelSettings
```dart
class PanelSettings {
  String id;              // Panel identifier
  String displayName;     // UI display name
  bool visible;          // Show/hide panel
  bool isFullWidth;      // Span both columns
  bool lockedExpanded;   // Keep panel expanded
}
```

## Common Workflows

### Device Connection
```dart
// Initialize service
final deviceManager = DeviceManagerService();
await deviceManager.initialize();

// Auto-polling starts, devices appear in devicesInfo
final info = deviceManager.getDeviceInfo(deviceId);
```

### Command Building
```dart
final builder = Provider.of<CommandBuilderService>(context, listen: false);

builder.updateAudioOptions(AudioOptions(audioBitRate: '128k'));

final command = builder.fullCommand;
await TerminalService.runCommandInNewTerminal(command);
```

### Wireless Setup
```dart
final result = await TerminalService.setupWirelessConnection('deviceId', 5555);
if (result['success']) {
  print('Connected to ${result['ipAddress']}:5555');
}
```

## Data Persistence

**Storage:**
- Windows: `%APPDATA%\ScrcpyGui\`
- macOS/Linux: `~/Documents/ScrcpyGui/`

**Files:**
- `settings.json` - App settings
- `commands.json` - Favorites and history

## Platform Differences

| Feature | Windows | macOS/Linux |
|---------|---------|-------------|
| Command execution | `cmd /c` | `bash -c` |
| New terminal | `cmd /k start` | AppleScript / auto-detect |
| Process list | `tasklist` + WMIC | `ps aux` |
| Settings path | `%APPDATA%` | `~/Documents` |
