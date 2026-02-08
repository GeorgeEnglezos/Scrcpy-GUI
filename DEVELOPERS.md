# Developer Guide

## Prerequisites

This is a Flutter desktop application targeting Windows, macOS, and Linux.

### Flutter SDK

The [Flutter install guide](https://docs.flutter.dev/install/quick) covers full details. Two common approaches:

1. **Manual install** -- Download the SDK from [Flutter Manual Install](https://docs.flutter.dev/install/manual) and add `flutter/bin` to your PATH.
2. **Via VS Code** -- Install the Flutter extension. It will prompt you to download the SDK and select a folder. You may need to manually add `flutter/bin` to your PATH afterwards.

### ADB / scrcpy

This app builds command lines for [scrcpy](https://github.com/Genymobile/scrcpy) but does not bundle it. Download the latest release from [scrcpy/releases](https://github.com/Genymobile/scrcpy/releases) and ensure it is on your PATH. scrcpy ships with Android's `adb`, so no additional tools are needed.

## Build & Run

### Code generation (required)

The project uses [freezed](https://pub.dev/packages/freezed) + [json_serializable](https://pub.dev/packages/json_serializable) for immutable models and JSON serialization. Generated files (`*.freezed.dart`, `*.g.dart`) are **not** checked into source control, so you must run code generation before the first build and any time you modify model fields:

```
dart run build_runner build --delete-conflicting-outputs
```

Without this step the app will not compile.

### Running
Running will also compile the code at the same time.

```
flutter run -d windows    # or linux, macos
```

To produce a release build:

```
flutter build windows     # or linux, macos
```

### VS Code workspace

Open the workspace at the `ScrcpyGui/` directory (e.g. `X:\sources\Scrcpy-GUI\ScrcpyGui`). Pre-configured tasks are available via **Command Palette > Run Task** (e.g. "flutter - run windows"). If Flutter is not found, add `flutter/bin` to your PATH and restart VS Code.

## Architecture Overview

```
lib/
  models/
    scrcpy_options.dart        # option classes + OptionsBundle (freezed)
    scrcpy_options.freezed.dart # generated -- do not edit
    scrcpy_options.g.dart       # generated -- do not edit
  services/
    command_builder_service.dart # central ChangeNotifier, builds CLI command
    options_state_service.dart   # JSON persistence to disk
    settings_service.dart        # app settings (UI prefs, paths)
    commands_service.dart        # saved command management
    device_manager_service.dart  # ADB device detection
  pages/home_panels/
    *_panel.dart                 # 11 UI panels (one per option category)
  utils/
    app_paths.dart               # centralized app data directory resolution
```

**Data flow:** Each panel reads its options via `context.select<CommandBuilderService, XxxOptions>` (granular rebuilds) and writes via `context.read<CommandBuilderService>().updateXxxOptions(...)`. The service holds an immutable `OptionsBundle` and uses `copyWith` to produce new state on every change. A debounced timer (4 seconds) auto-saves the bundle to `%APPDATA%/ScrcpyGui/scrcpy_options_state.json`.

## Adding a New Option

1. **Define the field** in the appropriate `@freezed` class in `lib/models/scrcpy_options.dart`. For example, to add a camera option:

   ```dart
   @freezed
   class CameraOptions with _$CameraOptions {
     const CameraOptions._();
     const factory CameraOptions({
       // ... existing fields ...
       @Default('') String myNewOption,    // <-- add here
     }) = _CameraOptions;
     // ...
   }
   ```

   That single `@Default('') String myNewOption` line gives you the field declaration, constructor parameter with default, `copyWith` support, JSON serialization, and equality -- all generated automatically by freezed.

2. **Add the CLI flag** in the `generateCommandPart()` method of the same class:

   ```dart
   if (myNewOption.isNotEmpty) cmd += ' --my-new-option=$myNewOption';
   ```

3. **Re-run code generation:**

   ```
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Add the UI widget** in the corresponding panel file under `lib/pages/home_panels/`. Follow the existing pattern:

   ```dart
   CustomTextField(
     label: 'My New Option',
     value: opts.myNewOption,
     onChanged: (val) {
       cmdService.updateCameraOptions(opts.copyWith(myNewOption: val));
       debugPrint('[CameraPanel] Updated CameraOptions');
     },
   ),
   ```

No changes are needed in the service layer, persistence, or serialization -- freezed and the `OptionsBundle` handle everything automatically.

## State Persistence

Options are persisted as JSON to `%APPDATA%/ScrcpyGui/scrcpy_options_state.json` (Windows) or the equivalent `getApplicationSupportDirectory()` path on other platforms. The centralized `AppPaths` utility resolves and caches this base directory.

- **Auto-save:** A 4-second debounced timer writes after each change or when closing.

- **Deserialization safety:** If the saved JSON is corrupt or has missing/renamed fields, the app falls back to defaults via try/catch. Freezed's `@Default` annotations handle missing fields gracefully.
