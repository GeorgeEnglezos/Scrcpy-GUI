# API Reference - Scrcpy GUI Flutter

This document provides detailed API documentation for the core services and models in the Scrcpy GUI Flutter application.

## Table of Contents

- [Services](#services)
  - [TerminalService](#terminalservice)
  - [DeviceManagerService](#devicemanagerservice)
  - [CommandBuilderService](#commandbuilderservice)
  - [CommandsService](#commandsservice)
  - [SettingsService](#settingsservice)
- [Models](#models)
  - [PhoneInfoModel](#phoneinfomodel)
  - [Option Classes](#option-classes)
  - [AppSettings](#appsettings)
- [Workflows](#workflows)

---

## Services

### TerminalService

**Location:** `lib/services/terminal_service.dart`

Static service for executing terminal commands and managing system processes.

#### Key Methods

##### Command Execution

```dart
static Future<String> runCommand(String command)
```
Executes a command synchronously and returns stdout.
- **Parameters:** `command` - Shell command to execute
- **Returns:** Command output as trimmed string, or empty string on error
- **Platform:** Windows (`cmd /c`), Unix (`bash -c`)

```dart
static Future<void> runCommandInNewTerminal(String command)
```
Opens a new terminal window and executes the command.
- **Parameters:** `command` - Shell command to execute in new window
- **Platform-specific:**
  - Windows: `cmd /k` (keeps window open)
  - Linux: Auto-detects terminal (gnome-terminal, konsole, etc.)
  - macOS: Uses AppleScript with Terminal.app
- **Side effects:** Tracks process in `_runningProcesses` map

##### Process Management

```dart
static Future<List<Map<String, String>>> getScrcpyProcesses()
```
Detects all running scrcpy processes system-wide.
- **Returns:** List of process detail maps containing:
  - `pid`: Process ID
  - `name`: Process name
  - `fullCommand`: Complete command line
  - `deviceId`: Device ID from `-s` flag
  - `windowTitle`: Title from `--window-title` flag
  - `connectionType`: 'wireless' or 'usb'
  - `startTime`: Creation timestamp (Windows only)
  - `memoryUsage`: Working set in MB (Windows only)

```dart
static Future<void> killProcess(int pid)
```
Terminates a process by PID.
- **Parameters:** `pid` - Process ID to kill
- **Behavior:**
  - If tracked: Sends SIGTERM and removes from tracking
  - Otherwise: Uses system kill command

##### ADB Integration

```dart
static Future<List<String>> adbDevices()
```
Returns list of connected device IDs via `adb devices`.
- **Returns:** List of device IDs (e.g., `['abc123', '192.168.1.100:5555']`)

```dart
static Future<List<String>> listPackages({
  required String deviceId,
  bool includeSystemApps = false,
})
```
Lists installed packages on a device.
- **Parameters:**
  - `deviceId`: Target device
  - `includeSystemApps`: If false, only shows user apps (-3 flag)
- **Returns:** List of package names

```dart
static Future<String> loadScrcpyEncoders({required String deviceId})
```
Retrieves available codecs via `scrcpy --list-encoders`.
- **Parameters:** `deviceId` - Target device
- **Returns:** Raw scrcpy encoder output

```dart
static List<String> parseVideoEncoders(String scrcpyOutput)
static List<String> parseAudioEncoders(String scrcpyOutput)
```
Parses encoder output to extract codec options.
- **Parameters:** `scrcpyOutput` - Raw output from `loadScrcpyEncoders`
- **Returns:** List of encoder flags (e.g., `['--video-codec=h264']`)

##### Wireless Connection

```dart
static Future<String> enableTcpip(String deviceId, int port)
```
Enables TCP/IP mode on device (requires USB connection).
- **Parameters:**
  - `deviceId`: Device ID (USB)
  - `port`: TCP/IP port (typically 5555)
- **Returns:** Command output

```dart
static Future<String?> getDeviceIpAddress(String deviceId)
```
Retrieves device WiFi IP address from wlan0 interface.
- **Parameters:** `deviceId` - Target device
- **Returns:** IP address or null if not found

```dart
static Future<String> connectWireless(String ipAddress, int port)
```
Establishes wireless ADB connection.
- **Parameters:**
  - `ipAddress`: Device IP
  - `port`: TCP/IP port
- **Returns:** Connection result message

```dart
static Future<Map<String, dynamic>> setupWirelessConnection(
  String deviceId,
  int port,
)
```
Complete wireless setup workflow.
- **Parameters:**
  - `deviceId`: Device ID (USB initially)
  - `port`: TCP/IP port
- **Returns:** Map with:
  - `success`: bool
  - `message`: String
  - `ipAddress`: String (if successful)

---

### DeviceManagerService

**Location:** `lib/services/device_manager_service.dart`

Manages device detection, selection, and information caching. Extends `ChangeNotifier`.

#### Properties

```dart
static final Map<String, PhoneInfoModel> devicesInfo
```
Global registry mapping device ID to cached device information.

```dart
String? selectedDevice
```
Currently selected device ID. Setting this triggers `notifyListeners()`.

```dart
final ValueNotifier<String?> selectedDeviceNotifier
```
Fine-grained notifier for device selection changes.

#### Methods

```dart
Future<void> initialize()
```
Initializes service and starts device polling.
- **Call once:** During app startup in `main()`
- **Side effects:**
  - Loads initial device data
  - Starts 2-second polling timer

```dart
PhoneInfoModel? getDeviceInfo(String deviceId)
```
Retrieves cached device information.
- **Parameters:** `deviceId` - Device to query
- **Returns:** Cached info or null

```dart
void dispose()
```
Cleanup method (cancels timer, disposes notifier).
- **Called by:** Provider automatically on app close

---

### CommandBuilderService

**Location:** `lib/services/command_builder_service.dart`

Builds scrcpy commands from panel options. Extends `ChangeNotifier`.

#### Properties

```dart
String baseCommand
```
Base scrcpy command (default: `"scrcpy.exe --pause-on-exit=if-error"`)

```dart
AudioOptions audioOptions
ScreenRecordingOptions recordingOptions
VirtualDisplayOptions virtualDisplayOptions
GeneralCastOptions generalCastOptions
```
Option objects for each command category.

#### Methods

```dart
void updateAudioOptions(AudioOptions options)
void updateRecordingOptions(ScreenRecordingOptions options)
void updateVirtualDisplayOptions(VirtualDisplayOptions options)
void updateGeneralCastOptions(GeneralCastOptions options)
```
Update respective option groups and notify listeners.
- **Parameters:** New options object
- **Side effects:** Triggers `notifyListeners()`

```dart
String get fullCommand
```
Generates complete scrcpy command.
- **Returns:** Full command string ready for execution
- **Logic:**
  - Combines all option parts
  - Generates dynamic window title
  - Adds 'record-' prefix if recording
  - Falls back to package name or "ScrcpyGui"

---

### CommandsService

**Location:** `lib/services/commands_service.dart`

Manages command favorites and execution history.

#### Methods

```dart
Future<CommandsData> loadCommands()
```
Loads saved commands from JSON file.
- **Returns:** `CommandsData` object with favorites and history

```dart
Future<void> saveCommands(CommandsData data)
```
Persists commands to JSON file.
- **Parameters:** `data` - Commands data to save

```dart
void trackExecution(String command)
```
Records command execution (updates last-command and increments counter).
- **Parameters:** `command` - Executed command string

```dart
void addFavorite(String command)
void removeFavorite(String command)
```
Manage favorite commands.

```dart
List<MostUsedCommand> getMostUsed(int count)
```
Gets top N most-used commands (excluding favorites).
- **Parameters:** `count` - Number of commands to return
- **Returns:** List of commands with execution counts

---

### SettingsService

**Location:** `lib/services/settings_service.dart`

Manages application settings persistence.

#### Methods

```dart
Future<AppSettings> loadSettings()
```
Loads settings from JSON file.
- **Returns:** `AppSettings` object (or defaults if file doesn't exist)

```dart
Future<void> saveSettings(AppSettings settings)
```
Persists settings to JSON file.
- **Parameters:** `settings` - Settings object to save

---

## Models

### PhoneInfoModel

**Location:** `lib/models/phone_info_model.dart`

Represents cached device information.

```dart
class PhoneInfoModel {
  final String deviceId;
  final List<String> packages;        // Installed user apps
  final List<String> audioCodecs;     // Available audio codecs
  final List<String> videoCodecs;     // Available video codecs
}
```

---

### Option Classes

**Location:** `lib/models/panel_models.dart`

Each option class has a `generateCommandPart()` method that returns the command flags as a string.

#### AudioOptions

```dart
class AudioOptions {
  String audioBitrate;      // '64k', '128k', '192k', '256k', '320k'
  String audioBuffer;       // '256', '512', '1024', '2048'
  String audioCodecOption;  // '--audio-codec=...'
  String audioEncoder;      // '--audio-encoder=...'
  bool noAudio;            // Disable audio
  bool audioDuplication;   // Enable audio duplication
}
```

#### ScreenRecordingOptions

```dart
class ScreenRecordingOptions {
  String maxSize;        // Max recording size
  String videoBitrate;   // Video bitrate
  String maxFps;         // Frame rate limit
  String format;         // 'mkv', 'mp4', 'm4a', 'mka', 'opus'
  String outputFile;     // Output filename
}
```

#### VirtualDisplayOptions

```dart
class VirtualDisplayOptions {
  bool newDisplay;           // Create virtual display
  String displayResolution;  // Resolution (WxH)
  String displayDpi;        // DPI value
  bool destroyContentOnDisconnect;  // Cleanup on disconnect
  bool systemDecorations;   // Show system decorations
}
```

#### GeneralCastOptions

```dart
class GeneralCastOptions {
  String windowTitle;          // Custom window title
  bool fullscreen;            // Launch fullscreen
  bool turnScreenOff;         // Turn device screen off
  bool stayAwake;            // Keep device awake
  String crop;               // Crop area (W:H:X:Y)
  String orientation;        // Screen rotation (0, 90, 180, 270)
  bool borderless;           // Borderless window
  bool alwaysOnTop;          // Window always on top
  bool disableScreensaver;   // Disable screensaver
  String videoBitrate;       // Video bitrate
  String videoCodecOption;   // '--video-codec=...'
  String videoEncoder;       // '--video-encoder=...'
  String selectedPackage;    // App package to launch
  String extraParams;        // Additional flags
}
```

---

### AppSettings

**Location:** `lib/models/settings_model.dart`

Application configuration model.

```dart
class AppSettings {
  List<PanelConfig> panelOrder;   // Panel layout configuration
  String scrcpyDirectory;         // scrcpy installation path
  String recordingsDirectory;     // Recordings output path
  String downloadsDirectory;      // Downloads path for .bat files
  bool openCmdWindows;           // Open in new terminal vs same
  String bootTab;                // 'Home' or 'Favorites'
}
```

#### PanelConfig

```dart
class PanelConfig {
  String id;              // Panel identifier
  String displayName;     // UI display name
  bool visible;          // Show/hide panel
  bool isFullWidth;      // Span both columns
}
```

---

## Workflows

### Device Connection Workflow

```dart
// 1. Service initialization (in main())
final deviceManager = DeviceManagerService();
await deviceManager.initialize();

// 2. Automatic polling starts (every 2 seconds)
// 3. On device detected:
//    - Loads packages via TerminalService.listPackages()
//    - Loads encoders via TerminalService.loadScrcpyEncoders()
//    - Parses encoders via parse* methods
//    - Stores in DeviceManagerService.devicesInfo
//    - Auto-selects if none selected

// 4. Access device info
final info = deviceManager.getDeviceInfo(deviceId);
print('Packages: ${info?.packages.length}');
```

### Command Building Workflow

```dart
// 1. Get command builder from Provider
final builder = Provider.of<CommandBuilderService>(context, listen: false);

// 2. Panel updates options
builder.updateAudioOptions(AudioOptions(
  audioBitrate: '128k',
  noAudio: false,
));

// 3. Get complete command
final command = builder.fullCommand;
// "scrcpy.exe --pause-on-exit=if-error --window-title=ScrcpyGui --audio-bitrate=128k"

// 4. Execute command
await TerminalService.runCommandInNewTerminal(command);

// 5. Track execution
final commandsService = CommandsService();
commandsService.trackExecution(command);
```

### Wireless Setup Workflow

```dart
// 1. Connect device via USB
// 2. Setup wireless connection
final result = await TerminalService.setupWirelessConnection(
  'deviceId123',
  5555,
);

// 3. Check result
if (result['success']) {
  print('Connected to ${result['ipAddress']}:5555');
  // Device now shows as '192.168.1.100:5555' in device list
} else {
  print('Error: ${result['message']}');
}

// 4. Disconnect USB cable
// 5. Use wirelessly with scrcpy
```

### Process Management Workflow

```dart
// 1. Get all running scrcpy processes
final processes = await TerminalService.getScrcpyProcesses();

// 2. Display process information
for (var proc in processes) {
  print('PID: ${proc['pid']}');
  print('Device: ${proc['deviceId']}');
  print('Type: ${proc['connectionType']}');
  print('Memory: ${proc['memoryUsage']} MB');
}

// 3. Kill a process
await TerminalService.killProcess(int.parse(proc['pid']));

// 4. Reconnect (re-execute same command)
final fullCommand = proc['fullCommand'];
await TerminalService.runCommandInNewTerminal(fullCommand);
```

---

## Data Persistence

### Storage Locations

**Windows:**
```
%APPDATA%\ScrcpyGui\
├── settings.json
└── commands.json
```

**macOS/Linux:**
```
~/Documents/ScrcpyGui/
├── settings.json
└── commands.json
```

### File Formats

**settings.json:**
```json
{
  "panelOrder": [
    {
      "id": "actions",
      "displayName": "Command Actions",
      "visible": true,
      "isFullWidth": true
    }
  ],
  "scrcpyDirectory": "C:\\path\\to\\scrcpy",
  "recordingsDirectory": "C:\\path\\to\\recordings",
  "downloadsDirectory": "C:\\path\\to\\downloads",
  "openCmdWindows": false,
  "bootTab": "Home"
}
```

**commands.json:**
```json
{
  "last-command": "scrcpy.exe --pause-on-exit=if-error ...",
  "favorites": [
    "scrcpy.exe --start-app=com.example.app"
  ],
  "most-used": [
    {
      "command": "scrcpy.exe --fullscreen",
      "count": 25
    }
  ]
}
```

---

## Error Handling

### TerminalService

- Command execution errors return empty string
- Process not found errors silently fail
- Platform-specific commands fall back gracefully

### DeviceManagerService

- Missing devices removed from cache
- Failed codec loading logged but not fatal
- Invalid device IDs skipped

### File Operations

- Missing files trigger default value creation
- JSON parsing errors fall back to defaults
- File write errors logged to stderr

---

## Platform Differences

### Terminal Commands

| Feature | Windows | Linux | macOS |
|---------|---------|-------|-------|
| Command execution | `cmd /c` | `bash -c` | `bash -c` |
| New terminal | `cmd /k start` | Auto-detect terminal | AppleScript |
| Process list | `tasklist` | `ps aux` | `ps aux` |
| Process details | WMIC | ps columns | ps columns |
| Kill process | `taskkill /F` | `kill` | `kill` |

### File Paths

| Feature | Windows | macOS/Linux |
|---------|---------|-------------|
| Settings | `%APPDATA%\ScrcpyGui\` | `~/Documents/ScrcpyGui/` |
| Path separator | `\` | `/` |
| Executable | `scrcpy.exe` | `scrcpy` |

---

## Best Practices

### Service Usage

1. **Initialize once:** Call `DeviceManagerService.initialize()` in `main()`
2. **Use Provider:** Access services via `Provider.of<T>(context)`
3. **Listen selectively:** Use `listen: false` for one-time access
4. **Dispose properly:** Let Provider handle disposal

### Error Handling

1. **Check nulls:** Device info may be null if not loaded
2. **Validate commands:** Ensure device selected before execution
3. **Handle platform differences:** Test on all target platforms

### Performance

1. **Avoid rebuilds:** Use ValueNotifier for targeted updates
2. **Cache data:** Device info cached in `devicesInfo` map
3. **Batch updates:** Update multiple options then rebuild command

---

**For more information, see the main [README.md](README.md) and inline code documentation.**
