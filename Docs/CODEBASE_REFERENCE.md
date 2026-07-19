# Codebase Reference

Developer documentation for the Scrcpy GUI Flutter codebase.  
App version: **1.7.4** · Dart SDK: **^3.9.2**

---

## Project Structure

```
ScrcpyGui/
├── lib/
│   ├── main.dart               # App entry point, Provider setup
│   ├── constants/              # Shared constants (package names, etc.)
│   ├── models/                 # Data models
│   ├── pages/                  # Top-level screens
│   │   ├── app_drawer/         # App Drawer tiles, dialogs, context menu
│   │   └── home_panels/        # Home screen collapsible panels
│   ├── services/               # Business logic and platform integration
│   │   └── strategies/         # Icon/label fetch strategies
│   ├── theme/                  # Colors, constants, and theme config
│   ├── utils/                  # Command execution, syntax highlighting
│   └── widgets/                # Reusable UI components
```

---

## Dependencies

| Package                       | Version  | Purpose                             |
| ----------------------------- | -------- | ----------------------------------- |
| `provider`                    | ^6.0.5   | State management (`ChangeNotifier`) |
| `window_manager`              | ^0.3.8   | Desktop window title, size, focus   |
| `path_provider`               | ^2.1.1   | Settings/data directory resolution  |
| `path`                        | ^1.9.0   | Cross-platform path joining         |
| `file_picker`                 | ^10.3.10 | File/directory picker dialogs       |
| `url_launcher`                | ^6.1.10  | Open URLs (GitHub, docs)            |
| `package_info_plus`           | ^8.0.0   | App version info                    |
| `desktop_drop`                | ^0.4.4   | Drag-and-drop file support          |
| `multi_dropdown`              | ^3.0.1   | Multi-select dropdown widgets       |
| `archive`                     | ^3.6.1   | ZIP extraction                      |
| `logger`                      | ^2.4.0   | Structured logging                  |
| `flutter_staggered_grid_view` | ^0.7.0   | App drawer grid layout              |

---

## Models

### `AppSettings`

**File**: `lib/models/settings_model.dart`

App-wide configuration persisted to JSON (`scrcpy_gui_settings.json` in the settings directory). Immutable — derive changes via `copyWith`.

| Field                      | Type                  | Default         | Description                                 |
| -------------------------- | --------------------- | --------------- | ------------------------------------------- |
| `panelOrder`               | `List<PanelSettings>` | `defaultPanels` | Panel visibility and order                  |
| `scrcpyDirectory`          | `String`              | `''`            | Path to scrcpy executable directory         |
| `recordingsDirectory`      | `String`              | `''`            | Output path for recordings                  |
| `downloadsDirectory`       | `String`              | `''`            | Where exported command scripts are saved    |
| `batDirectory`             | `String`              | `''`            | Scripts folder (`.bat`/`.sh`/`.command`)    |
| `openCmdWindows`           | `bool`                | `false`         | Open separate terminal window per instance  |
| `showBatFilesTab`          | `bool`                | `true`          | Show Scripts tab in sidebar                 |
| `showAppDrawerTab`         | `bool`                | `true`          | Show App Drawer tab in sidebar              |
| `showManualIpInput`        | `bool`                | `false`         | Show manual IP input in network panel       |
| `bootTab`                  | `String`              | `'Home'`        | Default tab on startup                      |
| `colorPreset`              | `String`              | `'Dark'`        | Active color theme preset name              |
| `settingsDirectory`        | `String`              | `''`            | Custom settings directory override          |
| `shortcutMod`              | `List<String>`        | `[]`            | Modifier keys for scrcpy keyboard shortcuts |
| `checkForUpdatesOnStartup` | `bool`                | `true`          | Auto-check GitHub releases                  |
| `loggingEnabled`           | `bool`                | `false`         | In-app console logging + Logs tab           |
| `fileLoggingEnabled`       | `bool`                | `false`         | Write logs to disk                          |
| `defaultPreset`            | `ScrcpyCommand?`      | `null`          | Saved default command loaded on startup     |

### `PanelSettings`

**File**: `lib/models/settings_model.dart`

Controls visibility and layout of each home screen panel.

| Field            | Type     | Description               |
| ---------------- | -------- | ------------------------- |
| `id`             | `String` | Unique panel identifier   |
| `displayName`    | `String` | Label shown in UI         |
| `visible`        | `bool`   | Whether panel is shown    |
| `isFullWidth`    | `bool`   | Panel spans full width    |
| `lockedExpanded` | `bool`   | Panel cannot be collapsed |

**Default panel IDs**: `actions`, `package`, `audio`, `common`, `camera`, `input`, `display`, `network`, `virtual`, `recording`, `advanced`, `otg`, `running`

### `PhoneInfoModel`

**File**: `lib/models/phone_info_model.dart`

Cached per-device information loaded on connection: `deviceId`, installed `packages`, `packageLabels` (package → display label), and `videoCodecs`/`audioCodecs` (codec → encoder names).

### `ScrcpyCommand`

**File**: `lib/models/scrcpy_command.dart`

Single immutable class holding **all** scrcpy option state, with fields grouped by panel (general/video, audio, recording, virtual display, camera, input control, display/window, network, advanced, OTG). Key members:

- `toCliString()` — renders every set option into the scrcpy CLI flag string
- `ScrcpyCommand.empty()` — all-defaults instance
- `copyWith(...)` — derive a modified command (used by every panel)
- JSON round-trip for persistence (`defaultPreset`, favorites)

Panels never build flag strings themselves — they set fields and `toCliString()` does the rendering.

---

## Services

### Execution core (no Flutter imports)

- **`AdbService`** (`lib/services/adb_service.dart`) — static ADB/scrcpy queries: device list, packages, encoders, wireless setup/teardown, IP lookup, plus executable-path helpers (`scrcpyExecutable`, `quoteExecutable`, `normalizeScrcpyExecutable`, `toDisplayCommand`).
- **`ScrcpyProcessService`** (`lib/services/scrcpy_process_service.dart`) — detects running scrcpy instances (one `Get-CimInstance` call on Windows, `ps` on Unix) and kills them by PID.
- **`ShellRunner`** (`lib/services/shell_runner.dart`) — low-level process spawning: argv-based `run`/`runOut` (the default primitives), shell/background variants, new-terminal launch per platform, `tokenizeCommand`, `openFolder`.

### `CommandExecutor`

**File**: `lib/utils/command_executor.dart`

The one UI-facing execution entry point — wraps `ShellRunner` with snackbars, output dialogs, and history tracking. `executeCommand` is the canonical run flow (log → snackbar → track history → respect `openCmdWindows`); also runs script files and exports commands as `.bat`/`.sh`/`.command` scripts.

### State holders (`ChangeNotifier`, provided at root)

- **`DeviceManagerService`** — device detection (2-second polling timer started by `initialize()`) and the per-device info cache (`static devicesInfo`, `getDeviceInfo`). Owns `selectedDevice` plus `ValueNotifier`s for targeted rebuilds.
- **`CommandNotifier`** — holds the in-progress `ScrcpyCommand` (`current`, `update()`, `reset()`) and assembles `fullCommand` / `displayCommand` (executable, `--serial`, window title, shortcut mod, flags). Also loads/saves the default preset.
- **`ColorThemeNotifier`** — active color preset; `setPreset(name)` switches themes app-wide. Presets themselves are loaded/persisted by **`ColorThemeService`** (`color_presets.json` in the settings directory, defaults seeded on first run).
- **`AppIconController`** — app icon loading for the App Drawer; coordinates `AppIconCache` and the fetch strategies in `lib/services/strategies/`.
- **`LogService`** — centralized logging (`info`/`error`, device-ID redaction) with optional in-app Logs tab and file output; singleton via `LogService.instance`.

### Persistence services

- **`SettingsService`** (`lib/services/settings_service.dart`) — loads/saves `AppSettings` to `scrcpy_gui_settings.json`; cached at `static currentSettings`; `appSettingsNotifier` fires on saves. Settings directory: `%APPDATA%\ScrcpyGui` (Windows), `~/Library/Application Support/ScrcpyGui` (macOS), `~/ScrcpyGui` (Linux).
- **`CommandsService`** (`lib/services/commands_service.dart`) — favorites, last command, and usage frequency in `commands.json`; migrates stored scrcpy paths when the configured path changes.
- **`ScriptRepository`** (`lib/services/script_repository.dart`) — loads and groups script files for the Scripts tab; extracts `--start-app` packages to pair scripts with app icons.

### Other

- **`UpdateService`** (`lib/services/update_service.dart`) — checks GitHub releases on startup (respects `checkForUpdatesOnStartup`).
- **Platform shortcut services** — `windows_shortcut_service.dart` / `macos_shortcut_service.dart` / `linux_shortcut_service.dart`, one per platform, each creating a desktop shortcut to the app executable.

---

## Pages

| Page            | File                         | Visibility                      |
| --------------- | ---------------------------- | ------------------------------- |
| `HomePage`      | `pages/home_page.dart`       | Always                          |
| `FavoritesPage` | `pages/favorites_page.dart`  | Always                          |
| `AppDrawerPage` | `pages/app_drawer_page.dart` | When `showAppDrawerTab` is true |
| `ScriptsPage`   | `pages/scripts_page.dart`    | When `showBatFilesTab` is true  |
| `ResourcesPage` | `pages/resources_page.dart`  | Always                          |
| `ShortcutsPage` | `pages/shortcuts_page.dart`  | Always                          |
| `LogsPage`      | `pages/logs_page.dart`       | When `loggingEnabled` is true   |
| `SettingsPage`  | `pages/settings_page.dart`   | Always                          |

App Drawer sub-widgets (tiles, dialogs, context menu) live in `pages/app_drawer/`.

---

## Home Panels

Each panel reads `CommandNotifier.current`, copies it with changed fields, and calls `update()`.

| Panel ID    | File                                  | Description                                  |
| ----------- | ------------------------------------- | -------------------------------------------- |
| `actions`   | `command_actions_panel.dart`          | Device selector, Run button, command preview |
| `common`    | `common_commands_panel.dart`          | Resolution, bitrate, FPS, window options     |
| `audio`     | `audio_commands_panel.dart`           | Audio codec, bitrate, source                 |
| `recording` | `recording_commands_panel.dart`       | Record to file, format, path                 |
| `camera`    | `camera_commands_panel.dart`          | Camera mirroring options                     |
| `input`     | `input_control_panel.dart`            | Keyboard/mouse passthrough settings          |
| `display`   | `display_window_panel.dart`           | Window position, display ID, video buffer    |
| `network`   | `network_connection_panel.dart`       | Wireless connect, TCP/IP, SSH tunnels        |
| `virtual`   | `virtual_display_commands_panel.dart` | Virtual display creation                     |
| `advanced`  | `advanced_panel.dart`                 | Verbosity, v4l2, cleanup flags               |
| `otg`       | `otg_mode_panel.dart`                 | OTG (On-The-Go) mode                         |
| `package`   | `package_selector_panel.dart`         | Launch specific app on connect               |
| `running`   | `instances_panel.dart`                | Active scrcpy process list (poll every 5s)   |

---

## State Management

Five `ChangeNotifier` providers registered at app root in `main()`:

| Provider               | Scope | Purpose                                     |
| ---------------------- | ----- | ------------------------------------------- |
| `DeviceManagerService` | Root  | Device list and selected device             |
| `CommandNotifier`      | Root  | Current `ScrcpyCommand` + command assembly  |
| `AppIconController`    | Root  | App icon loading for App Drawer             |
| `ColorThemeNotifier`   | Root  | Active color theme preset                   |
| `LogService`           | Root  | Log stream for Logs tab                     |

Settings are **not** provided via Provider — access via `SettingsService.currentSettings` (static cached value).

---

## Adding a New Panel

1. Create `lib/pages/home_panels/your_panel.dart`
2. Add the new fields to `ScrcpyCommand` (`lib/models/scrcpy_command.dart`): field, `copyWith`, JSON, and the flag rendering in `toCliString()` (exact flag names: `Official-docs/`)
3. In the panel, update state via:
   ```dart
   final notifier = context.read<CommandNotifier>();
   notifier.update(notifier.current.copyWith(yourField: value));
   ```
4. Add a `PanelSettings` entry to `defaultPanels` in `settings_model.dart`
5. Register the panel widget in `home_page.dart`'s panel map
