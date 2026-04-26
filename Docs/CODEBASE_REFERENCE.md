# API Reference

Developer documentation for the Scrcpy GUI Flutter codebase.  
App version: **1.7.0** · Dart SDK: **^3.9.2**

---

## Project Structure

```
ScrcpyGui/
├── lib/
│   ├── main.dart               # App entry point, Provider setup
│   ├── constants/              # Shared constants (package names, etc.)
│   ├── models/                 # Data models
│   ├── pages/                  # Top-level screens
│   │   └── home_panels/        # Home screen collapsible panels
│   ├── services/               # Business logic and platform integration
│   │   └── strategies/         # Icon/label fetch strategies
│   ├── theme/                  # Colors, constants, and theme config
│   ├── utils/                  # Misc utilities
│   └── widgets/                # Reusable UI components
```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.0.5 | State management (`ChangeNotifier`) |
| `window_manager` | ^0.3.8 | Desktop window title, size, focus |
| `path_provider` | ^2.1.1 | Settings/data directory resolution |
| `path` | ^1.9.0 | Cross-platform path joining |
| `file_picker` | ^10.3.10 | File/directory picker dialogs |
| `url_launcher` | ^6.1.10 | Open URLs (GitHub, docs) |
| `package_info_plus` | ^8.0.0 | App version info |
| `desktop_drop` | ^0.4.4 | Drag-and-drop file support |
| `multi_dropdown` | ^3.0.1 | Multi-select dropdown widgets |
| `archive` | ^3.6.1 | ZIP extraction |
| `logger` | ^2.4.0 | Structured logging |
| `flutter_staggered_grid_view` | ^0.7.0 | App drawer grid layout |

---

## Models

### `AppSettings`
**File**: `lib/models/settings_model.dart`

App-wide configuration persisted to JSON.

| Field | Type | Default | Description |
|---|---|---|---|
| `panelOrder` | `List<PanelSettings>` | `defaultPanels` | Panel visibility and order |
| `scrcpyDirectory` | `String` | `''` | Path to scrcpy executable directory |
| `recordingsDirectory` | `String` | `''` | Output path for recordings |
| `batDirectory` | `String` | `''` | Scripts folder (`.bat`/`.sh`/`.command`) |
| `openCmdWindows` | `bool` | `false` | Open separate terminal window per instance |
| `showBatFilesTab` | `bool` | `true` | Show Scripts tab in sidebar |
| `showAppDrawerTab` | `bool` | `true` | Show App Drawer tab in sidebar |
| `showManualIpInput` | `bool` | `false` | Show manual IP input in network panel |
| `bootTab` | `String` | `'Home'` | Default tab on startup |
| `shortcutMod` | `List<String>` | `[]` | Modifier keys for scrcpy keyboard shortcuts |
| `checkForUpdatesOnStartup` | `bool` | `true` | Auto-check GitHub releases |
| `loggingEnabled` | `bool` | `false` | In-app console logging + Logs tab |
| `fileLoggingEnabled` | `bool` | `false` | Write logs to disk |

### `PanelSettings`
**File**: `lib/models/settings_model.dart`

Controls visibility and layout of each home screen panel.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique panel identifier |
| `displayName` | `String` | Label shown in UI |
| `visible` | `bool` | Whether panel is shown |
| `isFullWidth` | `bool` | Panel spans full width |
| `lockedExpanded` | `bool` | Panel cannot be collapsed |

**Default panel IDs**: `actions`, `package`, `audio`, `common`, `camera`, `input`, `display`, `network`, `virtual`, `recording`, `advanced`, `otg`, `running`

### `PhoneInfoModel`
**File**: `lib/models/phone_info_model.dart`

Cached per-device information loaded on connection.

| Field | Type | Description |
|---|---|---|
| `deviceId` | `String` | ADB device identifier |
| `packages` | `List<String>` | Installed user app package names |
| `packageLabels` | `Map<String, String>` | Package name → display label |
| `videoCodecs` | `Map<String, List<String>>` | Codec → list of encoder names |
| `audioCodecs` | `Map<String, List<String>>` | Codec → list of encoder names |

### Scrcpy Option Classes
**File**: `lib/models/scrcpy_options.dart`

Command state is split into 10 typed option classes, each owned by `CommandBuilderService`. Each class has a `generateCommandPart()` method that returns its CLI fragment.

| Class | Key Fields | Generated Flags |
|---|---|---|
| `GeneralCastOptions` | fullscreen, turnScreenOff, videoBitRate, maxSize, maxFps, videoOrientation, crop, stayAwake, windowTitle, windowBorderless, windowAlwaysOnTop, disableScreensaver, selectedPackage, printFps, timeLimit, powerOffOnClose, extraParameters, videoCodecEncoderPair | `--fullscreen`, `--video-bit-rate`, `--max-size`, `--capture-orientation`, `--start-app`, etc. |
| `AudioOptions` | noAudio, audioBitRate, audioBuffer, audioSource, audioCodec, audioCodecEncoderPair, audioCodecOptions, audioDup | `--no-audio`, `--audio-bit-rate`, `--audio-source`, `--audio-dup`, etc. |
| `ScreenRecordingOptions` | outputFile, outputFormat, recordOrientation | `--record`, `--record-format`, `--record-orientation` |
| `CameraOptions` | cameraId, cameraSize, cameraFacing, cameraFps, cameraAr, cameraHighSpeed | `--video-source=camera`, `--camera-id`, `--camera-facing`, etc. |
| `InputControlOptions` | noControl, keyboardMode, mouseMode, mouseBind, noMouseHover, legacyPaste, noKeyRepeat, rawKeyEvents, preferText | `--no-control`, `--keyboard`, `--mouse`, `--mouse-bind`, etc. |
| `DisplayWindowOptions` | windowX, windowY, windowWidth, windowHeight, rotation, displayId, displayBuffer, renderDriver, forceAdbForward | `--window-x`, `--display-orientation`, `--display-id`, `--video-buffer`, etc. |
| `NetworkConnectionOptions` | tcpipPort, selectTcpip, tunnelHost, tunnelPort, noAdbForward | `--tcpip`, `--select-tcpip`, `--tunnel-host`, `--force-adb-forward` |
| `VirtualDisplayOptions` | newDisplay, resolution, dpi, noVdDestroyContent, noVdSystemDecorations | `--new-display`, `--no-vd-destroy-content`, `--no-vd-system-decorations` |
| `AdvancedOptions` | verbosity, noCleanup, noDownsizeOnError, v4l2Sink, v4l2Buffer | `--verbosity`, `--no-cleanup`, `--v4l2-sink`, etc. |
| `OtgModeOptions` | otg | `--otg` |

---

## Services

### `DeviceManagerService`
**File**: `lib/services/device_manager_service.dart`  
**Type**: `ChangeNotifier` (provided at root)

Manages device detection and device information caching.

| Member | Description |
|---|---|
| `static devicesInfo` | Global `Map<deviceId, PhoneInfoModel>` registry |
| `selectedDevice` | Currently selected device ID (getter/setter, notifies listeners) |
| `selectedDeviceNotifier` | `ValueNotifier<String?>` for targeted widget rebuilds |
| `initialize()` | Starts 2-second polling timer; call once at startup |
| `getDeviceInfo(id)` | Returns cached `PhoneInfoModel` or `null` |

### `CommandBuilderService`
**File**: `lib/services/command_builder_service.dart`  
**Type**: `ChangeNotifier` (provided at root)

Owns all 10 option class instances and assembles the final scrcpy CLI string.

| Member | Description |
|---|---|
| `fullCommand` | Complete scrcpy command string (includes device serial, window title, shortcut mod) |
| `displayCommand` | UI-safe version of `fullCommand` with full path replaced by `scrcpy` |
| `baseCommand` | `scrcpy --pause-on-exit=if-error` (uses configured path or PATH) |
| `audioOptions` | `AudioOptions` instance |
| `recordingOptions` | `ScreenRecordingOptions` instance |
| `virtualDisplayOptions` | `VirtualDisplayOptions` instance |
| `generalCastOptions` | `GeneralCastOptions` instance |
| `cameraOptions` | `CameraOptions` instance |
| `inputControlOptions` | `InputControlOptions` instance |
| `displayWindowOptions` | `DisplayWindowOptions` instance |
| `networkConnectionOptions` | `NetworkConnectionOptions` instance |
| `advancedOptions` | `AdvancedOptions` instance |
| `otgModeOptions` | `OtgModeOptions` instance |
| `updateXxxOptions(options)` | One update method per option class; calls `notifyListeners()` |
| `resetToDefaults()` | Resets all option classes to defaults |
| `deviceManagerService` | Setter — wires up device selection listener |

### `CommandsService`
**File**: `lib/services/commands_service.dart`

Manages favorites, last command, and usage frequency. Persists to `commands.json` in the settings directory. Automatically migrates stored scrcpy executable paths when the configured path changes.

| Member | Description |
|---|---|
| `static currentCommands` | Cached `CommandsData` (last loaded) |
| `loadCommands()` | Loads from disk; seeds defaults on first launch |
| `saveCommands(data)` | Persists to disk |
| `trackCommandExecution(cmd)` | Updates `lastCommand` and `mostUsed` counter |
| `addToFavorites(cmd)` | Adds command string to favorites list |
| `removeFromFavorites(cmd)` | Removes from favorites |
| `isFavorite(cmd)` | Returns `bool` |

### `SettingsService`
**File**: `lib/services/settings_service.dart`

Loads and saves `AppSettings` to JSON. Resolves the settings file path per platform.

- `static currentSettings` — in-memory cached `AppSettings`
- `loadSettings()` — reads from disk
- `saveSettings(settings)` — persists to disk
- `getSettingsDirectory()` — returns platform-appropriate path

### `LogService`
**File**: `lib/services/log_service.dart`  
**Type**: `ChangeNotifier` (provided at root)

Centralized logging with optional in-app display and file output.

- `LogService.info(tag, message)` — informational log
- `LogService.error(tag, message)` — error log
- `LogService.sanitizeDevice(id)` — redacts device ID for privacy
- `LogService.instance` — singleton for Provider

### `AppIconController`
**File**: `lib/services/app_icon_controller.dart`  
**Type**: `ChangeNotifier` (provided at root)

Manages app icon loading for the App Drawer page. Coordinates between `AppIconCache` and fetch strategies.

### `UpdateService`
**File**: `lib/services/update_service.dart`

Checks GitHub releases API for newer versions on startup (respects `checkForUpdatesOnStartup` setting).

- `static checkForUpdate()` → `UpdateService` result with `hasUpdate`, `latestVersion`, `downloadUrl`
- `static launchReleasePage(url)` — opens download URL in browser

### Platform Shortcut Services

| Service | File | Platform |
|---|---|---|
| `WindowsShortcutService` | `windows_shortcut_service.dart` | Windows |
| `MacosShortcutService` | `macos_shortcut_service.dart` | macOS |
| `LinuxShortcutService` | `linux_shortcut_service.dart` | Linux |

Each creates a desktop shortcut to the app executable.

### `TerminalService`
**File**: `lib/services/terminal_service.dart`

Executes ADB and scrcpy commands as subprocesses.

Key methods:
- `adbDevices()` — returns `List<String>` of connected device IDs
- `listPackages({deviceId})` — returns installed user packages
- `loadScrcpyEncoders({deviceId})` — returns raw scrcpy encoder output
- `parseVideoEncoders(raw)` / `parseAudioEncoders(raw)` — parse encoder lists
- `runCommand(cmd)` — run scrcpy in background
- `runCommandInNewTerminal(cmd)` — run in a new terminal window
- `getScrcpyProcesses()` — returns running scrcpy process list
- `killProcess(pid)` — terminates a process by PID
- `static scrcpyExecutable` — resolved path to scrcpy binary
- `static normalizeScrcpyExecutable(cmd)` — rewrites stored executable paths

---

## Pages

| Page | File | Visibility |
|---|---|---|
| `HomePage` | `pages/home_page.dart` | Always |
| `FavoritesPage` | `pages/favorites_page.dart` | Always |
| `AppDrawerPage` | `pages/app_drawer_page.dart` | When `showAppDrawerTab` is true |
| `ScriptsPage` | `pages/scripts_page.dart` | When `showBatFilesTab` is true |
| `ResourcesPage` | `pages/resources_page.dart` | Always |
| `ShortcutsPage` | `pages/shortcuts_page.dart` | Always |
| `LogsPage` | `pages/logs_page.dart` | When `loggingEnabled` is true |
| `SettingsPage` | `pages/settings_page.dart` | Always |

---

## Home Panels

Each panel reads/writes its specific option class on `CommandBuilderService` via `context.read<CommandBuilderService>()`.

| Panel ID | File | Description |
|---|---|---|
| `actions` | `command_actions_panel.dart` | Device selector, Run button, command preview |
| `common` | `common_commands_panel.dart` | Resolution, bitrate, FPS, window options |
| `audio` | `audio_commands_panel.dart` | Audio codec, bitrate, source |
| `recording` | `recording_commands_panel.dart` | Record to file, format, path |
| `camera` | `camera_commands_panel.dart` | Camera mirroring options |
| `input` | `input_control_panel.dart` | Keyboard/mouse passthrough settings |
| `display` | `display_window_panel.dart` | Window position, display ID, video buffer |
| `network` | `network_connection_panel.dart` | Wireless connect, TCP/IP, SSH tunnels |
| `virtual` | `virtual_display_commands_panel.dart` | Virtual display creation |
| `advanced` | `advanced_panel.dart` | Verbosity, v4l2, cleanup flags |
| `otg` | `otg_mode_panel.dart` | OTG (On-The-Go) mode |
| `package` | `package_selector_panel.dart` | Launch specific app on connect |
| `running` | `instances_panel.dart` | Active scrcpy process list (poll every 5s) |

---

## State Management

Four `ChangeNotifier` providers registered at app root in `main()`:

| Provider | Scope | Purpose |
|---|---|---|
| `DeviceManagerService` | Root | Device list and selected device |
| `CommandBuilderService` | Root | All scrcpy option state + command assembly |
| `AppIconController` | Root | App icon loading for App Drawer |
| `LogService` | Root | Log stream for Logs tab |

Settings are **not** provided via Provider — access via `SettingsService.currentSettings` (static cached value).

---

## Adding a New Panel

1. Create `lib/pages/home_panels/your_panel.dart`
2. Call the relevant `CommandBuilderService` update method when options change:
   ```dart
   context.read<CommandBuilderService>().updateGeneralCastOptions(newOptions);
   ```
3. Add a new option class to `scrcpy_options.dart` if the flags don't fit an existing class, and wire it into `CommandBuilderService`
4. Add a `PanelSettings` entry to `defaultPanels` in `settings_model.dart`
5. Register the panel widget in `home_page.dart`'s panel map
