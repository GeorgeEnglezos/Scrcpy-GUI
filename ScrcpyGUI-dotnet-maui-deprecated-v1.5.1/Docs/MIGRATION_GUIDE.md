# Flutter Migration Guide

> This document serves as a reference for developers migrating features from this .NET MAUI codebase to the Flutter version.

## Table of Contents
- [Overview](#overview)
- [Technology Mapping](#technology-mapping)
- [Feature Parity Checklist](#feature-parity-checklist)
- [Architecture Translation](#architecture-translation)
- [Code Examples](#code-examples)
- [Data Migration](#data-migration)
- [Testing Considerations](#testing-considerations)

---

## Overview

### Why Flutter?

The migration from .NET MAUI to Flutter addresses several limitations:

**Cross-Platform Support:**
- ❌ .NET MAUI: Windows only (Linux not supported)
- ✅ Flutter: Windows, macOS, Linux

**Performance:**
- .NET MAUI: Good performance, but heavier runtime
- Flutter: Fast Skia rendering engine, optimized for desktop

**Development Experience:**
- .NET MAUI: Good tooling, but limited hot-reload
- Flutter: Excellent hot-reload, comprehensive DevTools

**Community & Ecosystem:**
- .NET MAUI: Growing, Microsoft-backed
- Flutter: Mature, larger package ecosystem

### Migration Strategy

1. **Phase 1**: Core functionality (device management, command generation)
2. **Phase 2**: UI components and layouts
3. **Phase 3**: Settings persistence and favorites
4. **Phase 4**: Polish and platform-specific features

---

## Technology Mapping

### Framework Components

| .NET MAUI | Flutter | Notes |
|-----------|---------|-------|
| `ContentPage` | `Scaffold` | Main page structure |
| `ContentView` | `StatefulWidget` | Custom controls |
| `Grid` | `GridView` / `Row` + `Column` | Layout containers |
| `StackLayout` | `Column` / `Row` | Linear layouts |
| `ScrollView` | `SingleChildScrollView` | Scrollable content |
| `Button` | `ElevatedButton` | Click actions |
| `CheckBox` | `Checkbox` | Boolean inputs |
| `Entry` | `TextField` | Text inputs |
| `Picker` | `DropdownButton` | Selection controls |
| `Label` | `Text` | Text display |
| `Border` | `Container` with `BoxDecoration` | Visual borders |

### State Management

| .NET MAUI | Flutter | Notes |
|-----------|---------|-------|
| `INotifyPropertyChanged` | `ChangeNotifier` | Property change notifications |
| Event handlers | `ValueNotifier` / `StreamController` | Event propagation |
| Data binding | `Provider` / `Riverpod` | State management |
| Static data | `GetIt` / `Provider` | Dependency injection |

### File I/O

| .NET MAUI | Flutter | Notes |
|-----------|---------|-------|
| `File.ReadAllText()` | `File.readAsString()` | Async by default |
| `File.WriteAllText()` | `File.writeAsString()` | Async by default |
| `Path.Combine()` | `path.join()` | Requires `path` package |
| `FileSystem.AppDataDirectory` | `getApplicationDocumentsDirectory()` | From `path_provider` |

### Process Execution

| .NET MAUI | Flutter | Notes |
|-----------|---------|-------|
| `Process.Start()` | `Process.start()` | Similar API |
| `StreamReader` | `Stream<List<int>>` | Dart streams |
| `WaitForExit()` | `await process.exitCode` | Async wait |

### JSON Serialization

| .NET MAUI | Flutter | Notes |
|-----------|---------|-------|
| `Newtonsoft.Json` | `json_serializable` | Code generation |
| `JsonConvert.SerializeObject()` | `jsonEncode()` | Built-in |
| `JsonConvert.DeserializeObject()` | `jsonDecode()` | Built-in |

---

## Feature Parity Checklist

### Core Features

- [ ] **Device Management**
  - [ ] List connected USB devices
  - [ ] List connected wireless devices
  - [ ] Device selection dropdown
  - [ ] Device change detection
  - [ ] Codec/encoder querying per device

- [ ] **Command Generation**
  - [ ] General options (fullscreen, turn-screen-off, etc.)
  - [ ] Screen recording options
  - [ ] Virtual display options
  - [ ] Audio options
  - [ ] Package selection
  - [ ] Real-time command preview
  - [ ] Syntax highlighting (3 modes)

- [ ] **Command Execution**
  - [ ] Run scrcpy command
  - [ ] Display stdout/stderr
  - [ ] Error handling and alerts
  - [ ] Save to recent commands

- [ ] **Favorites Management**
  - [ ] Save command to favorites
  - [ ] Display all favorites
  - [ ] Execute from favorites
  - [ ] Copy to clipboard
  - [ ] Export as .bat/.sh file
  - [ ] Delete from favorites
  - [ ] Syntax highlighting in list

- [ ] **Wireless Connection**
  - [ ] IP address input
  - [ ] Port configuration
  - [ ] One-click connect
  - [ ] Connection status display
  - [ ] Disconnect option

- [ ] **Settings**
  - [ ] Panel visibility toggles
  - [ ] Scrcpy path configuration
  - [ ] Recording path configuration
  - [ ] Download path configuration
  - [ ] Syntax highlighting preference
  - [ ] Settings persistence

- [ ] **Status Checks**
  - [ ] ADB version check
  - [ ] Scrcpy version check
  - [ ] Device authorization status

### UI Features

- [ ] **Responsive Layout**
  - [ ] Adaptive panel arrangement
  - [ ] Breakpoint-based layouts
  - [ ] Mobile-friendly (optional)

- [ ] **Dark Theme**
  - [ ] Dark mode by default
  - [ ] Consistent color scheme
  - [ ] Syntax highlighting colors

- [ ] **Navigation**
  - [ ] Tab-based navigation
  - [ ] Home, Favorites, Settings, Info pages
  - [ ] Smooth transitions

---

## Architecture Translation

### .NET MAUI Pattern → Flutter Equivalent

#### 1. Data Models

**.NET MAUI** (`Models/ScrcpyGuiData.cs`):
```csharp
public class ScrcpyGuiData
{
    public string MostRecentCommand { get; set; }
    public List<string> FavoriteCommands { get; set; }
    public AppSettings AppSettings { get; set; }
}
```

**Flutter** (`models/scrcpy_gui_data.dart`):
```dart
import 'package:json_annotation/json_annotation.dart';

part 'scrcpy_gui_data.g.dart';

@JsonSerializable()
class ScrcpyGuiData {
  final String? mostRecentCommand;
  final List<String> favoriteCommands;
  final AppSettings appSettings;

  ScrcpyGuiData({
    this.mostRecentCommand,
    this.favoriteCommands = const [],
    required this.appSettings,
  });

  factory ScrcpyGuiData.fromJson(Map<String, dynamic> json) =>
      _$ScrcpyGuiDataFromJson(json);

  Map<String, dynamic> toJson() => _$ScrcpyGuiDataToJson(this);
}
```

#### 2. Data Persistence

**.NET MAUI** (`Services/DataStorage.cs`):
```csharp
public static class DataStorage
{
    public static ScrcpyGuiData LoadData()
    {
        if (!File.Exists(settingsPath))
            return new ScrcpyGuiData();

        string json = File.ReadAllText(settingsPath);
        return JsonConvert.DeserializeObject<ScrcpyGuiData>(json);
    }

    public static void SaveData(ScrcpyGuiData data)
    {
        string json = JsonConvert.SerializeObject(data, Formatting.Indented);
        File.WriteAllText(settingsPath, json);
    }
}
```

**Flutter** (`services/data_storage.dart`):
```dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DataStorage {
  static Future<File> _getSettingsFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File(path.join(appDir.path, 'ScrcpyGui-Data.json'));
  }

  static Future<ScrcpyGuiData> loadData() async {
    final file = await _getSettingsFile();

    if (!await file.exists()) {
      return ScrcpyGuiData.defaultSettings();
    }

    final contents = await file.readAsString();
    final json = jsonDecode(contents) as Map<String, dynamic>;
    return ScrcpyGuiData.fromJson(json);
  }

  static Future<void> saveData(ScrcpyGuiData data) async {
    final file = await _getSettingsFile();
    final json = jsonEncode(data.toJson());
    await file.writeAsString(json);
  }
}
```

#### 3. Process Execution

**.NET MAUI** (`Services/AdbCmdService.cs`):
```csharp
public static async Task<CmdCommandResponse> RunAdbCommandAsync(string arguments)
{
    var process = new Process
    {
        StartInfo = new ProcessStartInfo
        {
            FileName = "adb",
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        }
    };

    process.Start();
    string output = await process.StandardOutput.ReadToEndAsync();
    string error = await process.StandardError.ReadToEndAsync();
    await process.WaitForExitAsync();

    return new CmdCommandResponse
    {
        Output = output,
        RawError = error,
        ExitCode = process.ExitCode
    };
}
```

**Flutter** (`services/adb_cmd_service.dart`):
```dart
import 'dart:io';
import 'dart:convert';

class CmdCommandResponse {
  final String output;
  final String rawError;
  final int exitCode;

  CmdCommandResponse({
    required this.output,
    required this.rawError,
    required this.exitCode,
  });
}

class AdbCmdService {
  static Future<CmdCommandResponse> runAdbCommand(String arguments) async {
    final process = await Process.start(
      'adb',
      arguments.split(' '),
      runInShell: false,
    );

    final stdout = await process.stdout
        .transform(utf8.decoder)
        .join();

    final stderr = await process.stderr
        .transform(utf8.decoder)
        .join();

    final exitCode = await process.exitCode;

    return CmdCommandResponse(
      output: stdout,
      rawError: stderr,
      exitCode: exitCode,
    );
  }
}
```

#### 4. State Management

**.NET MAUI** (Event-based):
```csharp
public partial class OptionsPanel : ContentView
{
    public event EventHandler<string> ScrcpyCommandChanged;

    private void OnOptionChanged()
    {
        string command = BuildCommand();
        ScrcpyCommandChanged?.Invoke(this, command);
    }
}

// In MainPage
optionsPanel.ScrcpyCommandChanged += (sender, cmd) => {
    outputPanel.UpdatePreview(cmd);
};
```

**Flutter** (ChangeNotifier):
```dart
class OptionsModel extends ChangeNotifier {
  String _command = '';

  String get command => _command;

  void updateOption() {
    _command = _buildCommand();
    notifyListeners(); // Notify widgets to rebuild
  }

  String _buildCommand() {
    // Build command from options
    return 'scrcpy.exe ...';
  }
}

// In widget
class OutputPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<OptionsModel>(
      builder: (context, model, child) {
        return Text(model.command); // Auto-updates on change
      },
    );
  }
}
```

#### 5. UI Components

**.NET MAUI** (XAML + Code-behind):
```xml
<ContentView>
  <VerticalStackLayout>
    <Label Text="Fullscreen" />
    <CheckBox CheckedChanged="OnFullscreenChanged" />
  </VerticalStackLayout>
</ContentView>
```

```csharp
private void OnFullscreenChanged(object sender, CheckedChangedEventArgs e)
{
    options.Fullscreen = e.Value;
    RaiseCommandChanged();
}
```

**Flutter** (Widget tree):
```dart
class GeneralOptionsPanel extends StatefulWidget {
  @override
  _GeneralOptionsPanelState createState() => _GeneralOptionsPanelState();
}

class _GeneralOptionsPanelState extends State<GeneralOptionsPanel> {
  bool _fullscreen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Fullscreen'),
        Checkbox(
          value: _fullscreen,
          onChanged: (value) {
            setState(() {
              _fullscreen = value ?? false;
            });
            _updateCommand();
          },
        ),
      ],
    );
  }

  void _updateCommand() {
    final model = Provider.of<OptionsModel>(context, listen: false);
    model.fullscreen = _fullscreen;
    model.updateCommand();
  }
}
```

---

## Code Examples

### Complete Feature Migration: Favorites Management

#### .NET MAUI Implementation

**Model** (`Models/ScrcpyGuiData.cs`):
```csharp
public List<string> FavoriteCommands { get; set; } = new List<string>();
```

**Service** (`Services/DataStorage.cs`):
```csharp
public static void AppendFavoriteCommand(string command)
{
    var data = LoadData();
    if (!data.FavoriteCommands.Contains(command))
    {
        data.FavoriteCommands.Add(command);
        SaveData(data);
    }
}

public static void RemoveFavoriteCommandAtIndex(int index, ScrcpyGuiData data)
{
    data.FavoriteCommands.RemoveAt(index);
    SaveData(data);
}
```

**Page** (`Pages/CommandsPage.xaml.cs`):
```csharp
public partial class CommandsPage : ContentPage
{
    public ObservableCollection<string> SavedCommandsList { get; set; }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        var data = DataStorage.LoadData();
        SavedCommandsList.Clear();
        foreach (var cmd in data.FavoriteCommands)
        {
            SavedCommandsList.Add(cmd);
        }
    }

    private async void OnDeleteCommand(object sender, EventArgs e)
    {
        if (sender is ImageButton button && button.BindingContext is string cmd)
        {
            var data = DataStorage.LoadData();
            int index = data.FavoriteCommands.IndexOf(cmd);
            DataStorage.RemoveFavoriteCommandAtIndex(index, data);
            SavedCommandsList.Remove(cmd);
        }
    }
}
```

#### Flutter Implementation

**Model** (`models/scrcpy_gui_data.dart`):
```dart
@JsonSerializable()
class ScrcpyGuiData {
  final List<String> favoriteCommands;

  ScrcpyGuiData({this.favoriteCommands = const []});

  factory ScrcpyGuiData.fromJson(Map<String, dynamic> json) =>
      _$ScrcpyGuiDataFromJson(json);
  Map<String, dynamic> toJson() => _$ScrcpyGuiDataToJson(this);

  ScrcpyGuiData copyWith({List<String>? favoriteCommands}) {
    return ScrcpyGuiData(
      favoriteCommands: favoriteCommands ?? this.favoriteCommands,
    );
  }
}
```

**Service** (`services/data_storage.dart`):
```dart
class DataStorage {
  static Future<void> appendFavoriteCommand(String command) async {
    final data = await loadData();

    if (!data.favoriteCommands.contains(command)) {
      final updated = data.copyWith(
        favoriteCommands: [...data.favoriteCommands, command],
      );
      await saveData(updated);
    }
  }

  static Future<void> removeFavoriteCommand(String command) async {
    final data = await loadData();
    final updated = data.copyWith(
      favoriteCommands: data.favoriteCommands.where((c) => c != command).toList(),
    );
    await saveData(updated);
  }
}
```

**Provider** (`providers/favorites_provider.dart`):
```dart
class FavoritesProvider extends ChangeNotifier {
  List<String> _favorites = [];

  List<String> get favorites => _favorites;

  Future<void> loadFavorites() async {
    final data = await DataStorage.loadData();
    _favorites = data.favoriteCommands;
    notifyListeners();
  }

  Future<void> addFavorite(String command) async {
    await DataStorage.appendFavoriteCommand(command);
    await loadFavorites();
  }

  Future<void> removeFavorite(String command) async {
    await DataStorage.removeFavoriteCommand(command);
    await loadFavorites();
  }
}
```

**Page** (`pages/commands_page.dart`):
```dart
class CommandsPage extends StatefulWidget {
  @override
  _CommandsPageState createState() => _CommandsPageState();
}

class _CommandsPageState extends State<CommandsPage> {
  @override
  void initState() {
    super.initState();
    // Load favorites when page appears
    Future.microtask(() =>
      Provider.of<FavoritesProvider>(context, listen: false).loadFavorites()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorites')),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, child) {
          if (provider.favorites.isEmpty) {
            return Center(child: Text('No favorites saved'));
          }

          return ListView.builder(
            itemCount: provider.favorites.length,
            itemBuilder: (context, index) {
              final command = provider.favorites[index];
              return ListTile(
                title: Text(command),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await provider.removeFavorite(command);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Command deleted')),
                    );
                  },
                ),
                onTap: () => _executeCommand(command),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _executeCommand(String command) async {
    final result = await AdbCmdService.runScrcpyCommand(command);
    // Handle result...
  }
}
```

---

## Data Migration

### Settings File Compatibility

The JSON structure should remain compatible between versions:

**Shared Format** (`ScrcpyGui-Data.json`):
```json
{
  "mostRecentCommand": "scrcpy.exe --fullscreen",
  "favoriteCommands": [
    "scrcpy.exe --fullscreen --turn-screen-off",
    "scrcpy.exe --record=output.mp4"
  ],
  "appSettings": {
    "scrcpyPath": "C:\\scrcpy",
    "recordingPath": "C:\\Users\\...\\Videos",
    "downloadPath": "C:\\Users\\...\\Desktop",
    "homeCommandPreviewCommandColors": "Complete",
    "favoritesPageCommandColors": "Important",
    "hideTcpPanel": false,
    "hideStatusPanel": false,
    "hideOutputPanel": false,
    "hideRecordingPanel": false,
    "hideVirtualMonitorPanel": false
  },
  "screenRecordingOptions": {
    "enableRecording": false,
    "recordingPath": "",
    "maxSize": 0,
    "maxFps": 0,
    "recordFormat": "mp4"
  },
  "virtualDisplayOptions": {
    "enableVirtualDisplay": false,
    "noVdDestroyContent": false,
    "noVdSystemDecorations": false
  },
  "audioOptions": {
    "noAudio": false,
    "audioBitrate": "",
    "audioBuffer": "",
    "audioCodec": "",
    "audioEncoder": ""
  },
  "generalCastOptions": {
    "fullscreen": false,
    "turnScreenOff": false,
    "stayAwake": false,
    "windowTitle": "",
    "videoBitrate": "",
    "windowBorderless": false,
    "alwaysOnTop": false,
    "disableScreensaver": false,
    "videoCodec": "",
    "videoEncoder": "",
    "captureOrientation": "",
    "crop": ""
  }
}
```

### Migration Script

For users switching from .NET MAUI to Flutter:

```dart
// lib/services/migration_service.dart
class MigrationService {
  static Future<void> migrateFromDotNetMaui() async {
    // Check for .NET MAUI settings file
    final dotNetMauiPath = await _getDotNetMauiSettingsPath();
    final dotNetMauiFile = File(dotNetMauiPath);

    if (!await dotNetMauiFile.exists()) {
      return; // No migration needed
    }

    try {
      // Read .NET MAUI settings
      final contents = await dotNetMauiFile.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;

      // Parse into Flutter model
      final data = ScrcpyGuiData.fromJson(json);

      // Save to Flutter location
      await DataStorage.saveData(data);

      print('Successfully migrated settings from .NET MAUI version');
    } catch (e) {
      print('Migration failed: $e');
      // Continue with default settings
    }
  }

  static Future<String> _getDotNetMauiSettingsPath() async {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      return path.join(
        localAppData!,
        'ScrcpyGUI',
        'ScrcpyGui-Data.json',
      );
    }
    // macOS/Linux paths would differ
    throw UnimplementedError('Platform not supported for migration');
  }
}
```

---

## Testing Considerations

### Unit Tests

**.NET MAUI** (xUnit):
```csharp
[Fact]
public void GenerateCommandPart_WithFullscreen_ReturnsCorrectCommand()
{
    var options = new GeneralCastOptions { Fullscreen = true };
    string result = options.GenerateCommandPart();
    Assert.Contains("--fullscreen", result);
}
```

**Flutter** (test package):
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GenerateCommandPart with fullscreen returns correct command', () {
    final options = GeneralCastOptions(fullscreen: true);
    final result = options.generateCommandPart();
    expect(result, contains('--fullscreen'));
  });
}
```

### Widget Tests

**Flutter** (flutter_test):
```dart
testWidgets('Favorites page displays saved commands', (tester) async {
  final provider = FavoritesProvider();
  provider.favorites.addAll(['scrcpy.exe --fullscreen']);

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider.value(
        value: provider,
        child: CommandsPage(),
      ),
    ),
  );

  expect(find.text('scrcpy.exe --fullscreen'), findsOneWidget);
});
```

### Integration Tests

**Flutter** (integration_test):
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-end command execution', (tester) async {
    await tester.pumpWidget(MyApp());

    // Navigate to home page
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // Select fullscreen option
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    // Verify command preview updated
    expect(find.text('--fullscreen'), findsOneWidget);

    // Run command
    await tester.tap(find.text('Run Command'));
    await tester.pumpAndSettle();

    // Verify output displayed
    expect(find.text('Success'), findsOneWidget);
  });
}
```

---

## Resources

### Flutter Learning
- **Flutter Documentation**: https://flutter.dev/docs
- **Dart Language Tour**: https://dart.dev/guides/language/language-tour
- **Provider Pattern**: https://pub.dev/packages/provider
- **JSON Serialization**: https://pub.dev/packages/json_annotation

### Packages for Migration

**Essential**:
- `provider` - State management
- `json_serializable` - JSON serialization
- `path_provider` - File system access
- `path` - Path manipulation

**UI**:
- `flutter_syntax_view` - Syntax highlighting
- `file_picker` - Folder selection

**Utilities**:
- `shared_preferences` - Simple key-value storage
- `clipboard` - Clipboard access

---

**Last Updated**: 2025-12-22
**Version**: 1.5 (.NET MAUI - Legacy)
