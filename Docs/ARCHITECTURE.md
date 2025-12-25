# Scrcpy-GUI Architecture Documentation

> **DEPRECATION NOTICE**: This .NET MAUI application is being replaced by a Flutter version. This documentation serves as a reference for the legacy codebase.

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Key Design Patterns](#key-design-patterns)
- [Technology Stack](#technology-stack)

## Overview

Scrcpy-GUI is a .NET MAUI desktop application that provides a graphical user interface for the [scrcpy](https://github.com/Genymobile/scrcpy) command-line tool. The application enables users to:

- Generate complex scrcpy commands through an intuitive UI
- Manage multiple Android device connections
- Save and execute favorite commands
- Configure screen recording, virtual displays, and audio settings
- Connect to devices wirelessly with one-click setup

## Project Structure

```
ScrcpyGUI/
├── App.xaml.cs                      # Application entry point and lifecycle
├── AppShell.xaml.cs                 # Navigation shell and routing
├── MauiProgram.cs                   # Bootstrap configuration
│
├── Models/                          # Data models and business logic
│   ├── CmdCommandResponse.cs        # Command execution results
│   └── ScrcpyGuiData.cs            # Application data (9 classes)
│       ├── ScrcpyGuiData           # Root data model
│       ├── AppSettings             # User preferences
│       ├── ScreenRecordingOptions  # Recording configuration
│       ├── VirtualDisplayOptions   # Virtual display settings
│       ├── AudioOptions            # Audio configuration
│       ├── GeneralCastOptions      # General scrcpy options
│       └── ConnectedDevice         # Device information
│
├── Services/                        # Business logic and external interactions
│   ├── DataStorage.cs              # JSON persistence service
│   └── AdbCmdService.cs            # ADB/Scrcpy command execution
│
├── Pages/                           # Application screens
│   ├── MainPage.xaml.cs            # Primary UI with panels
│   ├── SettingsPage.xaml.cs        # Configuration interface
│   ├── CommandsPage.xaml.cs        # Saved commands management
│   └── InfoPage.xaml.cs            # Documentation and resources
│
└── Controls/                        # Reusable UI components
    ├── OptionsPanel.xaml.cs        # Command builder panel
    ├── OutputPanel.xaml.cs         # Preview and execution panel
    ├── SettingsPanelChildren/      # Option sub-panels
    ├── OutputChildren/             # Output sub-panels
    └── SharedControls/             # Common UI elements
```

## Core Components

### 1. Application Layer

#### **App.xaml.cs**
- Manages application lifecycle (startup, shutdown)
- Loads and validates configuration paths
- Applies dark theme globally
- Registers cleanup handlers

#### **AppShell.xaml.cs**
- Defines navigation structure using Shell
- Implements tab-based navigation
- Handles routing between pages

#### **MauiProgram.cs**
- **Single-Instance Enforcement**: Uses named Mutex to prevent multiple app instances
- **Win32 Interop**: P/Invoke helpers for window management
- **Dependency Registration**: Configures fonts and resources

### 2. Data Layer

#### **Models Namespace**

**ScrcpyGuiData** (Root Model)
```csharp
- MostRecentCommand: string
- FavoriteCommands: List<string>
- AppSettings: AppSettings
- ScreenRecordingOptions: ScreenRecordingOptions
- VirtualDisplayOptions: VirtualDisplayOptions
- AudioOptions: AudioOptions
- GeneralCastOptions: GeneralCastOptions
```

**AppSettings**
- UI visibility flags (panels to show/hide)
- File paths (Scrcpy, recordings, downloads)
- Command coloring preferences

**ConnectedDevice**
- Device identification (serial/IP)
- Display name
- Supported codec/encoder pairs
- List comparison utilities

### 3. Service Layer

#### **DataStorage.cs**
Centralized persistence service using JSON serialization:

**Key Methods:**
- `LoadData()`: Deserialize settings from AppData
- `SaveData()`: Serialize and persist changes
- `ValidateAndCreatePath()`: Ensure directories exist
- `AppendFavoriteCommand()`: Add to favorites list
- `RemoveFavoriteCommandAtIndex()`: Delete from favorites
- `SaveMostRecentCommand()`: Update last command
- `CopyToClipboardAsync()`: Clipboard helper with error handling

**Storage Location:**
- Windows: `%LOCALAPPDATA%/ScrcpyGUI/ScrcpyGui-Data.json`

#### **AdbCmdService.cs**
Handles all ADB and Scrcpy command execution:

**Key Capabilities:**
- Execute scrcpy with generated parameters
- List connected devices (USB and TCP/IP)
- Query device codecs and encoders
- Install/uninstall APKs
- Wireless connection management
- Package listing and filtering
- ADB version checking

**Command Types:**
```csharp
enum CommandEnum {
    GetPackages,
    RunScrcpy,
    CheckAdbVersion,
    CheckScrcpyVersion,
    GetCodecsEncoders,
    ConnectTCP,
    DisconnectTCP,
    RestartServer,
    // ... more
}
```

### 4. Presentation Layer

#### **MainPage.xaml.cs**
The primary interface orchestrating the two main panels:

**Responsibilities:**
- Responsive layout management (1250px breakpoint)
- Cross-panel event coordination
- Device change propagation
- Visibility settings application

**Layout Modes:**
- **Wide (≥1250px)**: Side-by-side panels (2 columns, 1 row)
- **Narrow (<1250px)**: Stacked panels (1 column, 2 rows)

#### **OptionsPanel.xaml.cs**
Left panel for building scrcpy commands:

**Features:**
- Device selection dropdown
- Package selector with search
- General options (fullscreen, window title, etc.)
- Screen recording settings
- Virtual display configuration
- Audio settings
- Real-time command generation

**Event System:**
- Raises `ScrcpyCommandChanged` when options update
- Subscribes to child panel value changes
- Notifies OutputPanel of command updates

#### **OutputPanel.xaml.cs**
Right panel for command preview and execution:

**Features:**
- Syntax-highlighted command preview (3 modes: None, Partial, Complete)
- Run command button
- Save to favorites button
- Status checks panel
- Wireless connection panel
- ADB output display

**Color Mapping:**
- General options: Blue
- Audio options: Purple
- Virtual display: Green
- Recording: Orange
- Package selection: Cyan

#### **CommandsPage.xaml.cs**
Manages favorite commands:

**Features:**
- Display all saved commands
- Syntax highlighting with configurable modes
- Tap to execute
- Copy to clipboard
- Export as .bat file (auto-named by package)
- Delete from favorites
- Show most recent command

**CommandColorConverter**
- XAML value converter for syntax highlighting
- Reuses color mapping logic from OutputPanel

#### **SettingsPage.xaml.cs**
User preferences configuration:

**Settings Categories:**
1. **Panel Visibility**: Toggle display of UI sections
2. **Folder Paths**:
   - Scrcpy installation directory
   - Screen recording output
   - Command downloads
3. **Command Colors**: Choose highlighting level for previews

**Responsive Layout:**
- Breakpoint: 950px
- Vertical: Stacked settings and folder pickers
- Horizontal: Side-by-side layout

#### **InfoPage.xaml.cs**
Simple resource page with links to:
- Scrcpy-GUI GitHub repository
- Scrcpy-GUI documentation
- Official Scrcpy repository
- Official Scrcpy documentation
- Diagnostic command copy (`dotnet --info`)

## Data Flow

### Command Generation Flow

```
User Input (OptionsPanel)
    ↓
GenerateCommandPart() methods in option classes
    ↓
Concatenation in OptionsPanel
    ↓
ScrcpyCommandChanged event raised
    ↓
OutputPanel receives command string
    ↓
UpdateCommandPreview() applies syntax highlighting
    ↓
FinalCommandPreview label updated
```

### Command Execution Flow

```
User clicks "Run Command" (OutputPanel)
    ↓
OnRunGeneratedCommand() handler
    ↓
AdbCmdService.RunScrcpyCommand(command)
    ↓
Process.Start() with scrcpy.exe
    ↓
Capture stdout/stderr
    ↓
Return CmdCommandResponse
    ↓
Display output in AdbOutputLabel
    ↓
Save to MostRecentCommand (DataStorage)
```

### Device Selection Flow

```
User selects device (FixedHeader)
    ↓
DeviceChanged event raised
    ↓
MainPage.OnDeviceChanged() handler
    ↓
Parallel operations:
    ├─ LoadPackages() - Query installed apps
    ├─ ReloadCodecsEncoders() - Update video options
    └─ ReloadCodecsEncoders() - Update audio options
```

### Settings Persistence Flow

```
User modifies setting (SettingsPage/OptionsPanel)
    ↓
Property updated in ScrcpyGuiData instance
    ↓
DataStorage.SaveData(scrcpyData)
    ↓
Newtonsoft.Json.JsonConvert.SerializeObject()
    ↓
File.WriteAllText() to AppDataDirectory
```

## Key Design Patterns

### 1. **Observer Pattern**
- Event-driven communication between panels
- `ScrcpyCommandChanged`, `DeviceChanged`, `StatusRefreshed` events
- Loose coupling between UI components

### 2. **Repository Pattern**
- `DataStorage` acts as repository for application state
- Centralized data access and persistence
- Abstracts JSON serialization details

### 3. **Command Pattern**
- `CommandEnum` defines discrete operations
- `AdbCmdService` executes commands with consistent interface
- `CmdCommandResponse` encapsulates results

### 4. **Singleton Pattern**
- Single application instance enforced via Mutex
- Static `DataStorage.staticSavedData` for global access
- Static `AdbCmdService` methods

### 5. **Builder Pattern**
- Option classes build command fragments
- `GenerateCommandPart()` methods construct parameters
- Final assembly in OptionsPanel

### 6. **Strategy Pattern**
- Color mapping strategies (None, Partial, Complete)
- Swappable dictionaries based on user preference
- `ChooseColorMapping()` selects appropriate strategy

### 7. **Facade Pattern**
- `AdbCmdService` provides simplified interface to ADB/Scrcpy
- Hides Process management complexity
- Unified API for diverse operations

## Technology Stack

### **Framework**
- **.NET 9.0**: Latest .NET runtime
- **.NET MAUI**: Cross-platform UI framework (Windows target)
- **C# 12**: Modern language features

### **Dependencies**
- **Newtonsoft.Json**: JSON serialization
- **CommunityToolkit.Maui**: Extended MAUI controls
- **System.Diagnostics.Process**: External command execution

### **Platform-Specific**
- **Windows 10/11 (Build 19041+)**: Target platform
- **Win32 APIs**: Window management via P/Invoke
- **Named Mutex**: Single-instance enforcement

### **External Tools**
- **ADB (Android Debug Bridge)**: Device communication
- **Scrcpy**: Screen mirroring engine

## Responsive Design

### Breakpoints

| Component | Breakpoint | Behavior |
|-----------|-----------|----------|
| MainPage | 1250px | Panel layout switch |
| SettingsPage | 950px | Settings layout switch |
| OutputPanel | 750px | Status/wireless panel layout |

### Layout Strategies

**Grid Reconfiguration**
- Clear existing definitions
- Add new row/column definitions
- Reposition child elements with Grid.SetRow/SetColumn

**Visibility-Based Layout**
- OutputPanel adjusts when child panels hidden
- Ensures optimal use of available space

## Security Considerations

1. **Command Injection Prevention**
   - All user input sanitized before process execution
   - No shell=true in Process.Start()
   - Parameterized command building

2. **Path Validation**
   - `ValidateAndCreatePath()` checks directory existence
   - Fallback to safe defaults (Desktop, AppData)
   - No arbitrary path traversal

3. **Single Instance**
   - Mutex prevents multiple instances
   - Brings existing window to foreground

4. **Error Handling**
   - Try-catch blocks around all external operations
   - User-friendly error messages
   - No sensitive data in error logs

## Performance Optimizations

1. **Lazy Initialization**
   - Color mappings cached on first use
   - `_colorMappingInitialized` flag prevents rebuilds

2. **Async Operations**
   - All ADB commands use async/await
   - UI remains responsive during execution
   - Background task for long-running operations

3. **Event Unsubscription**
   - Explicit cleanup in OnDisappearing
   - Prevents memory leaks
   - Proper IDisposable patterns

4. **Selective Updates**
   - Command preview only rebuilds on changes
   - Device list only refreshes when needed
   - Codec queries cached per device

## Known Limitations

1. **Windows-Only**: .NET MAUI doesn't support Linux builds
2. **macOS Experimental**: Requires VM testing
3. **Single Scrcpy Path**: Assumes one scrcpy installation
4. **No Scrcpy Installation**: User must install scrcpy separately
5. **English-Only UI**: No localization support

## Future Migration

The application is being migrated to Flutter for:
- Cross-platform support (Linux, macOS)
- Better performance on lower-end hardware
- More mature ecosystem for desktop apps
- Improved hot-reload development experience

This .NET MAUI version serves as the reference implementation and will be maintained alongside the Flutter port during transition.

---

**Last Updated**: 2025-12-22
**Version**: 1.5 (.NET MAUI - Legacy)
