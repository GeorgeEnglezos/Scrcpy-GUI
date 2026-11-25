# Codebase reference

How the Scrcpy GUI Flutter app is organized. App version 1.7.6, Dart SDK ^3.9.2.

## Project structure

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

## Dependencies

| Package                       | Version  | Purpose                             |
| ----------------------------- | -------- | ----------------------------------- |
| `provider`                    | ^6.0.5   | State management (`ChangeNotifier`) |
| `window_manager`              | ^0.3.8   | Desktop window title, size, focus   |
| `screen_retriever`            | ^0.1.9   | Screen sizes for window placement   |
| `path`                        | ^1.9.0   | Cross-platform path joining         |
| `meta`                        | ^1.15.0  | Annotations such as `@visibleForTesting` |
| `file_picker`                 | ^10.3.10 | File and folder picker dialogs      |
| `url_launcher`                | ^6.1.10  | Open URLs (GitHub, docs)            |
| `package_info_plus`           | ^8.0.0   | App version info                    |
| `desktop_drop`                | ^0.4.4   | Drag-and-drop file support          |
| `multi_dropdown`              | ^3.0.1   | Multi-select dropdowns              |
| `archive`                     | ^3.6.1   | ZIP extraction                      |
| `flutter_staggered_grid_view` | ^0.7.0   | Grid layouts                        |

## Models

### `AppSettings`

`lib/models/settings_model.dart`. App-wide configuration, saved as `scrcpy_gui_settings.json` in the settings folder. It is immutable, so derive changes with `copyWith`.

| Field                      | Type                  | Default         | Description                                 |
| -------------------------- | --------------------- | --------------- | ------------------------------------------- |
| `panelOrder`               | `List<PanelSettings>` | `defaultPanels` | Panel visibility and order                  |
| `scrcpyDirectory`          | `String`              | `''`            | Folder holding `scrcpy` and `adb` (empty uses PATH) |
| `recordingsDirectory`      | `String`              | `''`            | Output folder for recordings                |
| `downloadsDirectory`       | `String`              | `''`            | Where exported command scripts are saved    |
| `batDirectory`             | `String`              | `''`            | Scripts folder (`.bat`/`.sh`/`.command`)    |
| `appIconsDirectory`        | `String`              | `''`            | Where the App Drawer caches icons and labels |
| `openCmdWindows`           | `bool`                | `false`         | Open a separate terminal window per instance |
| `showBatFilesTab`          | `bool`                | `true`          | Show the Scripts tab                        |
| `showAppDrawerTab`         | `bool`                | `true`          | Show the App Drawer tab                     |
| `showManualIpInput`        | `bool`                | `false`         | Show the manual IP input for wireless       |
| `bootTab`                  | `String`              | `'Home'`        | Tab shown on startup                        |
| `colorPreset`              | `String`              | `'Dark'`        | Active color theme preset                   |
| `settingsDirectory`        | `String`              | `''`            | Custom settings folder                      |
| `shortcutMod`              | `List<String>`        | `[]`            | Modifier keys for scrcpy keyboard shortcuts |
| `checkForUpdatesOnStartup` | `bool`                | `true`          | Check GitHub releases on startup            |
| `loggingEnabled`           | `bool`                | `false`         | Console logging and the Logs tab            |
| `fileLoggingEnabled`       | `bool`                | `false`         | Write logs to disk                          |
| `defaultPreset`            | `ScrcpyCommand?`      | `null`          | Saved default command loaded on startup     |
| `windowState`              | `WindowState?`        | `null`          | Last window position, size, maximized state |
| `uiScale`                  | `double`              | `1.0`           | Interface scale                             |
| `setupCompleted`           | `bool`                | `false`         | Whether the setup wizard has run            |

### `PanelSettings`

`lib/models/settings_model.dart`. Visibility and layout of one Home panel.

| Field            | Type     | Description               |
| ---------------- | -------- | ------------------------- |
| `id`             | `String` | Unique panel identifier   |
| `displayName`    | `String` | Label shown in the UI     |
| `visible`        | `bool`   | Whether the panel shows   |
| `isFullWidth`    | `bool`   | Panel spans full width    |
| `lockedExpanded` | `bool`   | Panel cannot be collapsed |

Default panel IDs: `actions`, `package`, `audio`, `common`, `camera`, `input`, `display`, `network`, `virtual`, `recording`, `advanced`, `otg`, `running`.

### `PhoneInfoModel`

`lib/models/phone_info_model.dart`. Per-device information loaded on connection: `deviceId`, installed `packages`, `packageLabels` (package to display label), and `videoCodecs`/`audioCodecs` (codec to encoder names).

### `ScrcpyCommand`

`lib/models/scrcpy_command.dart`. One immutable class that holds all scrcpy option state, with fields grouped by panel (general and video, audio, recording, virtual display, camera, input control, display and window, network, advanced, OTG).

- `toCliString()` renders every set option as scrcpy flags.
- `ScrcpyCommand.empty()` is the all-defaults instance.
- `copyWith(...)` derives a modified command. Every panel uses it.
- JSON round-trip for persistence (`defaultPreset`, favorites).

Panels never build flag strings themselves. They set fields, and `toCliString()` renders them.

## Services

### Execution core (no Flutter imports)

- `AdbService` (`lib/services/adb_service.dart`): static ADB and scrcpy queries for the device list, packages, encoders, wireless setup and teardown, and IP lookup, plus executable-path helpers (`scrcpyExecutable`, `quoteExecutable`, `normalizeScrcpyExecutable`, `toDisplayCommand`).
- `ScrcpyProcessService` (`lib/services/scrcpy_process_service.dart`): finds running scrcpy instances (one `Get-CimInstance` call through PowerShell on Windows, `ps` on macOS and Linux) and kills them by PID.
- `ShellRunner` (`lib/services/shell_runner.dart`): low-level process spawning. argv-based `run`/`runOut` are the default primitives. There are also shell and background variants, a per-platform new-terminal launch, `tokenizeCommand` and `openFolder`.

### `CommandExecutor`

`lib/utils/command_executor.dart`. The single UI-facing way to run commands. It wraps `ShellRunner` with snackbars, output dialogs and history tracking. `executeCommand` is the standard run flow: log, show a snackbar, record history, and honor `openCmdWindows`. It also runs script files and exports commands as `.bat`/`.sh`/`.command` scripts.

### State holders (`ChangeNotifier`, provided at the root)

- `DeviceManagerService`: device detection (a 2-second polling timer started by `initialize()`) and the per-device info cache (`static devicesInfo`, `getDeviceInfo`). Owns `selectedDevice` plus `ValueNotifier`s for targeted rebuilds.
- `CommandNotifier`: holds the command being edited (`current`, `update()`, `reset()`) and assembles `fullCommand` / `displayCommand` (executable, `--serial`, window title, shortcut mod, flags). Also loads and saves the default preset.
- `ColorThemeNotifier`: the active color preset. `setPreset(name)` switches the theme app-wide. `ColorThemeService` loads and saves the presets (`color_presets.json` in the settings folder, seeded with defaults on first run).
- `AppIconController`: icon loading for the App Drawer. It coordinates `AppIconCache` and the fetch strategies in `lib/services/strategies/`.
- `LogService`: logging (`info`/`error`, with device IDs redacted), feeding the Logs tab and optional file output. It is a singleton at `LogService.instance`.

### Persistence

- `SettingsService` (`lib/services/settings_service.dart`): loads and saves `AppSettings`. The cached copy is `static currentSettings`, and `appSettingsNotifier` fires on saves. The settings folder is `%APPDATA%\ScrcpyGui` on Windows, `~/Library/Application Support/ScrcpyGui` on macOS, and `$XDG_CONFIG_HOME/ScrcpyGui` (usually `~/.config/ScrcpyGui`) on Linux. `lib/services/app_directories.dart` resolves it.
- `CommandsService` (`lib/services/commands_service.dart`): favorites, the last command and usage counts in `commands.json`. It also updates stored scrcpy paths when the configured path changes.
- `ScriptRepository` (`lib/services/script_repository.dart`): loads and groups script files for the Scripts tab, and reads their `--start-app` package so a script can show that app's icon.

### Other

- `UpdateService` (`lib/services/update_service.dart`): checks GitHub releases on startup when `checkForUpdatesOnStartup` is on.
- `windows_shortcut_service.dart`, `macos_shortcut_service.dart`, `linux_shortcut_service.dart`: create a desktop shortcut that launches one phone app through scrcpy, used by the App Drawer's right-click menu.

## Pages

| Page            | File                         | Visible                         |
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

## Home panels

Each panel reads `CommandNotifier.current`, copies it with the changed fields, and calls `update()`.

| Panel ID    | File                                  | Contents                                     |
| ----------- | ------------------------------------- | -------------------------------------------- |
| `actions`   | `command_actions_panel.dart`          | Device selector, Run button, command preview |
| `common`    | `common_commands_panel.dart`          | Resolution, bitrate, FPS, window options     |
| `audio`     | `audio_commands_panel.dart`           | Audio codec, bitrate, source                 |
| `recording` | `recording_commands_panel.dart`       | Record to file, format, path                 |
| `camera`    | `camera_commands_panel.dart`          | Camera mirroring options                     |
| `input`     | `input_control_panel.dart`            | Keyboard and mouse settings                  |
| `display`   | `display_window_panel.dart`           | Window position, display ID, video buffer    |
| `network`   | `network_connection_panel.dart`       | TCP/IP port and device, SSH tunnel           |
| `virtual`   | `virtual_display_commands_panel.dart` | Virtual display creation                     |
| `advanced`  | `advanced_panel.dart`                 | Verbosity, v4l2, cleanup flags               |
| `otg`       | `otg_mode_panel.dart`                 | OTG mode                                     |
| `package`   | `package_selector_panel.dart`         | App to launch on connect                     |
| `running`   | `instances_panel.dart`                | Running scrcpy processes, refreshed every 5 s |

## State management

`main()` registers five `ChangeNotifier` providers at the root:

| Provider               | Purpose                                     |
| ---------------------- | ------------------------------------------- |
| `DeviceManagerService` | Device list and selected device             |
| `CommandNotifier`      | Current `ScrcpyCommand` and command assembly |
| `AppIconController`    | App icon loading for the App Drawer         |
| `ColorThemeNotifier`   | Active color theme preset                   |
| `LogService`           | Log stream for the Logs tab                 |

Settings are not provided through Provider. Read them from `SettingsService.currentSettings`.

## Adding a panel

1. Create `lib/pages/home_panels/your_panel.dart`.
2. Add the new fields to `ScrcpyCommand` (`lib/models/scrcpy_command.dart`): the field, `copyWith`, JSON, and the flag in `toCliString()`. Take exact flag names from `Official-docs/`.
3. In the panel, update state like this:
   ```dart
   final notifier = context.read<CommandNotifier>();
   notifier.update(notifier.current.copyWith(yourField: value));
   ```
4. Add a `PanelSettings` entry to `defaultPanels` in `settings_model.dart`.
5. Register the panel widget in `home_page.dart`.
