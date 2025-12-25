# Scrcpy-GUI Development Guide

> **DEPRECATION NOTICE**: This .NET MAUI application is being replaced by a Flutter version. This documentation serves as a reference for developers maintaining the legacy codebase or porting features to the Flutter version.

## Table of Contents
- [Development Environment Setup](#development-environment-setup)
- [Project Configuration](#project-configuration)
- [Building and Running](#building-and-running)
- [Code Organization](#code-organization)
- [Adding New Features](#adding-new-features)
- [Debugging Tips](#debugging-tips)
- [Common Issues](#common-issues)
- [Testing](#testing)
- [Contributing Guidelines](#contributing-guidelines)

---

## Development Environment Setup

### Prerequisites

**Required:**
- **Visual Studio 2022** (17.8 or later) with the following workloads:
  - .NET Multi-platform App UI development
  - .NET desktop development
- **.NET 9.0 SDK** or later
- **Windows 10/11** (Build 19041 or later)
- **ADB (Android Debug Bridge)** - Part of Android Platform Tools
- **Scrcpy** - Install from [official repository](https://github.com/Genymobile/scrcpy)

**Optional:**
- **Git** for version control
- **VS Code** with C# extension (alternative to Visual Studio)
- **Windows Terminal** for better command-line experience

### Installing .NET MAUI Workload

If you prefer using the .NET CLI:

```bash
# Install MAUI workload
dotnet workload install maui

# Verify installation
dotnet workload list
```

You should see:
```
Installed Workload Id      Manifest Version
-------------------------------------------
maui-windows              9.0.x
```

### Installing ADB and Scrcpy

**ADB (Android Debug Bridge):**
1. Download Android Platform Tools: https://developer.android.com/tools/releases/platform-tools
2. Extract to a permanent location (e.g., `C:\Android\platform-tools`)
3. Add to PATH environment variable

**Scrcpy:**
1. Download from https://github.com/Genymobile/scrcpy/releases
2. Extract to a permanent location (e.g., `C:\scrcpy`)
3. Note this path - you'll configure it in the app

**Verify Installation:**
```bash
adb version
scrcpy --version
```

---

## Project Configuration

### Solution Structure

```
ScrcpyGUI.sln
└── ScrcpyGUI/
    ├── ScrcpyGUI.csproj          # Project file with dependencies
    ├── App.xaml                   # Application resources
    ├── AppShell.xaml              # Navigation shell
    ├── MauiProgram.cs             # Entry point
    ├── Models/
    ├── Services/
    ├── Pages/
    ├── Controls/
    ├── Resources/                 # Images, fonts, styles
    └── Platforms/                 # Platform-specific code
        └── Windows/               # Windows-specific implementations
```

### Project File (ScrcpyGUI.csproj)

Key configuration sections:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>net9.0-windows10.0.19041.0</TargetFrameworks>
    <OutputType>WinExe</OutputType>
    <RootNamespace>ScrcpyGUI</RootNamespace>
    <UseMaui>true</UseMaui>
    <SingleProject>true</SingleProject>

    <!-- Windows Specific -->
    <WindowsPackageType>None</WindowsPackageType>
    <EnableWindowsTargeting>true</EnableWindowsTargeting>

    <!-- App Info -->
    <ApplicationTitle>Scrcpy GUI</ApplicationTitle>
    <ApplicationId>com.scrcpygui.app</ApplicationId>
    <ApplicationDisplayVersion>1.5</ApplicationDisplayVersion>
    <ApplicationVersion>1</ApplicationVersion>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Maui.Controls" Version="9.0.0" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
    <PackageReference Include="CommunityToolkit.Maui" Version="7.0.0" />
  </ItemGroup>
</Project>
```

### App Configuration

**App.xaml** - Global resources and theme:
```xml
<Application xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
             xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
             x:Class="ScrcpyGUI.App">
    <Application.Resources>
        <ResourceDictionary>
            <!-- Color Resources -->
            <Color x:Key="General">#4A9EFF</Color>
            <Color x:Key="Audio">#B84AFF</Color>
            <Color x:Key="VirtualDisplay">#4AFFB8</Color>
            <Color x:Key="Recording">#FFAD4A</Color>
            <Color x:Key="PackageSelector">#4ADBFF</Color>
        </ResourceDictionary>
    </Application.Resources>
</Application>
```

---

## Building and Running

### Using Visual Studio

1. **Open Solution**: `File > Open > Project/Solution` → Select `ScrcpyGUI.sln`
2. **Set Startup Project**: Right-click `ScrcpyGUI` → `Set as Startup Project`
3. **Select Configuration**:
   - Debug (for development with debugging)
   - Release (for optimized builds)
4. **Select Platform**: `Windows Machine`
5. **Build**: `Build > Build Solution` (Ctrl+Shift+B)
6. **Run**: `Debug > Start Debugging` (F5)

### Using .NET CLI

**Debug Build and Run:**
```bash
# Navigate to project directory
cd ScrcpyGUI

# Restore dependencies
dotnet restore

# Build
dotnet build -f net9.0-windows10.0.19041.0

# Run
dotnet run -f net9.0-windows10.0.19041.0
```

**Release Build:**
```bash
# Build optimized release
dotnet build -c Release -f net9.0-windows10.0.19041.0

# Publish single-file executable
dotnet publish -c Release -f net9.0-windows10.0.19041.0 -p:PublishSingleFile=true

# Output location:
# bin/Release/net9.0-windows10.0.19041.0/win-x64/publish/ScrcpyGUI.exe
```

### Using VS Code

1. Install C# extension (ms-dotnettools.csharp)
2. Open folder containing ScrcpyGUI.sln
3. Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build",
      "command": "dotnet",
      "type": "process",
      "args": [
        "build",
        "${workspaceFolder}/ScrcpyGUI/ScrcpyGUI.csproj",
        "-f",
        "net9.0-windows10.0.19041.0"
      ]
    },
    {
      "label": "run",
      "command": "dotnet",
      "type": "process",
      "args": [
        "run",
        "--project",
        "${workspaceFolder}/ScrcpyGUI/ScrcpyGUI.csproj",
        "-f",
        "net9.0-windows10.0.19041.0"
      ]
    }
  ]
}
```

4. Run task: `Terminal > Run Task > build/run`

---

## Code Organization

### Naming Conventions

**Files:**
- Page classes: `MainPage.xaml.cs`
- Control classes: `OptionsPanel.xaml.cs`
- Model classes: `ConnectedDevice.cs`
- Service classes: `AdbCmdService.cs`

**Classes:**
- PascalCase: `ScrcpyGuiData`, `CommandEnum`
- Descriptive names: `CmdCommandResponse` not `CmdCmdResp`

**Methods:**
- PascalCase: `LoadData()`, `GetAdbDevices()`
- Verb-based: `SaveData()`, `ValidateAndCreatePath()`
- Async suffix: `RunAdbCommandAsync()`

**Properties:**
- PascalCase: `DeviceId`, `MostRecentCommand`
- No Hungarian notation

**Private Fields:**
- camelCase: `command`, `parentPage`
- Underscores for backing fields: `_mostRecentCommandText`

**Constants:**
- camelCase: `baseScrcpyCommand`, `scrcpy_gui_url`
- ALL_CAPS for truly immutable: Not commonly used in this codebase

### File Organization Best Practices

**Models** (`Models/`):
- Pure data classes
- No business logic
- Include `GenerateCommandPart()` for command builders
- Serializable to JSON

**Services** (`Services/`):
- Static utility classes
- External system interaction (file I/O, process execution)
- No UI dependencies
- Testable independently

**Pages** (`Pages/`):
- One page per file
- Code-behind contains only UI logic
- Delegate complex operations to services
- Use data binding where possible

**Controls** (`Controls/`):
- Reusable UI components
- Expose events for parent communication
- Self-contained functionality
- Clear public API

### Dependency Management

**Add NuGet Package:**
```bash
dotnet add package PackageName --version X.Y.Z
```

**Current Dependencies:**
- `Microsoft.Maui.Controls` (9.0+) - Core MAUI framework
- `Newtonsoft.Json` (13.0+) - JSON serialization
- `CommunityToolkit.Maui` (7.0+) - Extended controls

---

## Adding New Features

### Example: Adding a New Scrcpy Option

Let's add support for the `--power-off-on-close` parameter.

#### Step 1: Update Data Model

**File**: `Models/ScrcpyGuiData.cs`

```csharp
public class GeneralCastOptions
{
    // Existing properties...
    public bool Fullscreen = false;
    public bool TurnScreenOff = false;

    // NEW: Add the new option
    public bool PowerOffOnClose = false;

    public string GenerateCommandPart()
    {
        string commandPart = "";

        // Existing command building...
        if (Fullscreen) commandPart += " --fullscreen";
        if (TurnScreenOff) commandPart += " --turn-screen-off";

        // NEW: Add to command generation
        if (PowerOffOnClose) commandPart += " --power-off-on-close";

        return commandPart;
    }
}
```

#### Step 2: Update UI Control

**File**: `Controls/SettingsPanelChildren/GeneralPanel.xaml`

```xml
<!-- Existing checkboxes... -->
<custom:CustomCheckbox
    x:Name="FullscreenCheckbox"
    LabelText="Fullscreen"
    CheckedChanged="OnFullscreenChanged"/>

<!-- NEW: Add checkbox for new option -->
<custom:CustomCheckbox
    x:Name="PowerOffOnCloseCheckbox"
    LabelText="Power off on close"
    CheckedChanged="OnPowerOffOnCloseChanged"/>
```

**File**: `Controls/SettingsPanelChildren/GeneralPanel.xaml.cs`

```csharp
/// <summary>
/// Handles changes to the power off on close checkbox.
/// Updates the GeneralCastOptions and notifies parent of command change.
/// </summary>
private void OnPowerOffOnCloseChanged(object sender, CheckedChangedEventArgs e)
{
    generalOptions.PowerOffOnClose = e.Value;
    OnGeneralOptionsChanged();
}
```

#### Step 3: Update Syntax Highlighting

**File**: `Controls/OutputPanel.xaml.cs`

```csharp
Dictionary<string, Color> completeColorMappings = new Dictionary<string, Color>
{
    // Existing mappings...
    { "--fullscreen", (Color)Application.Current.Resources["General"] },
    { "--turn-screen-off", (Color)Application.Current.Resources["General"] },

    // NEW: Add to color mapping
    { "--power-off-on-close", (Color)Application.Current.Resources["General"] },
};
```

Also update `partialColorMappings` if this is an "important" parameter.

#### Step 4: Test

1. Run application
2. Navigate to General options
3. Toggle "Power off on close" checkbox
4. Verify command preview shows `--power-off-on-close`
5. Verify syntax highlighting works
6. Execute command and test functionality

---

### Example: Adding a New Page

Let's add a "Help" page.

#### Step 1: Create Page Files

**File**: `Pages/HelpPage.xaml`
```xml
<?xml version="1.0" encoding="utf-8" ?>
<ContentPage xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
             xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
             x:Class="ScrcpyGUI.HelpPage"
             Title="Help">
    <ScrollView>
        <VerticalStackLayout Padding="20" Spacing="10">
            <Label Text="Scrcpy-GUI Help"
                   FontSize="24"
                   FontAttributes="Bold"/>
            <Label Text="How to use this application..."
                   FontSize="14"/>
            <!-- More content -->
        </VerticalStackLayout>
    </ScrollView>
</ContentPage>
```

**File**: `Pages/HelpPage.xaml.cs`
```csharp
namespace ScrcpyGUI;

/// <summary>
/// Help page providing user guidance and documentation.
/// DEPRECATED: This .NET MAUI application is being replaced by a Flutter version.
/// </summary>
public partial class HelpPage : ContentPage
{
    /// <summary>
    /// Initializes a new instance of the HelpPage class.
    /// </summary>
    public HelpPage()
    {
        InitializeComponent();
    }
}
```

#### Step 2: Register Route

**File**: `AppShell.xaml`
```xml
<TabBar>
    <ShellContent Title="Home" ContentTemplate="{DataTemplate local:MainPage}" />
    <ShellContent Title="Favorites" ContentTemplate="{DataTemplate local:CommandsPage}" />

    <!-- NEW: Add Help tab -->
    <ShellContent Title="Help" ContentTemplate="{DataTemplate local:HelpPage}" />

    <ShellContent Title="Settings" ContentTemplate="{DataTemplate local:SettingsPage}" />
    <ShellContent Title="Info" ContentTemplate="{DataTemplate local:InfoPage}" />
</TabBar>
```

#### Step 3: Test Navigation

1. Run application
2. Verify "Help" tab appears
3. Click tab and verify page loads
4. Test navigation between tabs

---

## Debugging Tips

### Enable Detailed Logging

**File**: `MauiProgram.cs`
```csharp
public static MauiApp CreateMauiApp()
{
    var builder = MauiApp.CreateBuilder();
    builder
        .UseMauiApp<App>()
        .ConfigureFonts(fonts => { /* ... */ });

#if DEBUG
    // Enable detailed MAUI logging
    builder.Logging.AddDebug();
    builder.Logging.SetMinimumLevel(LogLevel.Trace);
#endif

    return builder.Build();
}
```

### Debugging ADB Commands

Add diagnostic output to `AdbCmdService`:

```csharp
private static async Task<CmdCommandResponse> ExecuteCommand(string command)
{
    Debug.WriteLine($"[ADB] Executing: {command}");

    var result = await RunProcessAsync(command);

    Debug.WriteLine($"[ADB] Exit Code: {result.ExitCode}");
    Debug.WriteLine($"[ADB] Output: {result.Output}");
    if (!string.IsNullOrEmpty(result.RawError))
    {
        Debug.WriteLine($"[ADB] Error: {result.RawError}");
    }

    return result;
}
```

### Debugging Data Persistence

```csharp
public static void SaveData(ScrcpyGuiData data)
{
    try
    {
        string json = JsonConvert.SerializeObject(data, Formatting.Indented);
        Debug.WriteLine($"[Storage] Saving to: {settingsPath}");
        Debug.WriteLine($"[Storage] Data: {json}");

        File.WriteAllText(settingsPath, json);
    }
    catch (Exception ex)
    {
        Debug.WriteLine($"[Storage] Save failed: {ex.Message}");
        throw;
    }
}
```

### Breakpoint Best Practices

**Strategic Breakpoint Locations:**
1. **Event Handlers**: First line of `OnXxxChanged` methods
2. **Service Methods**: Entry point of `AdbCmdService` methods
3. **Command Generation**: Inside `GenerateCommandPart()` methods
4. **Data Loading**: `LoadData()` and `SaveData()` methods

**Conditional Breakpoints:**
```csharp
// Break only when specific device selected
if (selectedDevice == "192.168.1.100:5555")
{
    // Breakpoint here
    var packages = await GetPackageList(selectedDevice);
}
```

### Common Debug Scenarios

**Problem**: Command not updating in preview
1. Breakpoint in option change handler
2. Verify `OnXxxChanged()` raises event
3. Check `OutputPanel.OnScrcpyCommandChanged()` receives event
4. Verify `UpdateCommandPreview()` is called

**Problem**: Settings not persisting
1. Breakpoint in `DataStorage.SaveData()`
2. Verify JSON serialization succeeds
3. Check file write permissions
4. Verify `LoadData()` reads updated file

**Problem**: Device not appearing
1. Breakpoint in `GetAdbDevices()`
2. Check `adb devices` output manually
3. Verify ADB path is correct
4. Check device authorization status

---

## Common Issues

### Issue: Application Won't Build

**Error**: `The name 'InitializeComponent' does not exist in the current context`

**Solution**: XAML files not generating code-behind. Clean and rebuild:
```bash
dotnet clean
dotnet build
```

**Error**: `Platform 'net9.0-windows10.0.19041.0' not found`

**Solution**: Install Windows SDK or update target framework:
```bash
# Check installed SDKs
dotnet --list-sdks

# Install MAUI workload
dotnet workload install maui-windows
```

### Issue: App Crashes on Startup

**Error**: `System.InvalidOperationException: No ResourceDictionary found`

**Solution**: Ensure `App.xaml` has proper ResourceDictionary structure:
```xml
<Application.Resources>
    <ResourceDictionary>
        <!-- Resources here -->
    </ResourceDictionary>
</Application.Resources>
```

**Error**: `FileNotFoundException: Could not load file or assembly 'Newtonsoft.Json'`

**Solution**: Restore NuGet packages:
```bash
dotnet restore
```

### Issue: ADB Commands Failing

**Problem**: `'adb' is not recognized as an internal or external command`

**Solution**: Add ADB to PATH or specify full path in `AdbCmdService`:
```csharp
private const string ADB_PATH = @"C:\Android\platform-tools\adb.exe";
```

**Problem**: `error: device unauthorized`

**Solution**:
1. Check device for authorization popup
2. Accept "Always allow from this computer"
3. Restart ADB: `adb kill-server && adb start-server`

### Issue: Scrcpy Not Working

**Problem**: Scrcpy path not configured

**Solution**:
1. Run app
2. Go to Settings page
3. Set Scrcpy folder path
4. Restart app

**Problem**: `scrcpy.exe` fails with codec errors

**Solution**: Device doesn't support requested codec. Use `GetCodecsEncoders()` to query supported codecs first.

---

## Testing

### Manual Testing Checklist

#### Startup
- [ ] Application starts without errors
- [ ] Dark theme applied
- [ ] Settings loaded correctly
- [ ] Default command shows in preview

#### Device Management
- [ ] USB device detected
- [ ] Wireless connection works
- [ ] Multiple devices shown correctly
- [ ] Device switching updates UI

#### Command Building
- [ ] Checkboxes update command preview
- [ ] Text inputs update command preview
- [ ] Package selection works
- [ ] Codec/encoder selection works

#### Command Execution
- [ ] Run command button works
- [ ] Scrcpy window opens
- [ ] Errors displayed properly
- [ ] Output shown in panel

#### Favorites
- [ ] Save command adds to favorites
- [ ] Favorites page shows saved commands
- [ ] Tap to execute works
- [ ] Copy to clipboard works
- [ ] Export to .bat works
- [ ] Delete from favorites works

#### Settings
- [ ] Folder pickers work
- [ ] Panel visibility toggles work
- [ ] Color scheme changes work
- [ ] Settings persist after restart

### Unit Testing (Future Enhancement)

The current project doesn't have automated tests. Here's a recommended structure:

```
ScrcpyGUI.Tests/
├── Models/
│   ├── ScrcpyGuiDataTests.cs
│   └── ConnectedDeviceTests.cs
├── Services/
│   ├── DataStorageTests.cs
│   └── AdbCmdServiceTests.cs
└── ScrcpyGUI.Tests.csproj
```

**Example Test**:
```csharp
using Xunit;

namespace ScrcpyGUI.Tests.Models;

public class GeneralCastOptionsTests
{
    [Fact]
    public void GenerateCommandPart_WithFullscreen_ReturnsCorrectCommand()
    {
        // Arrange
        var options = new GeneralCastOptions { Fullscreen = true };

        // Act
        string result = options.GenerateCommandPart();

        // Assert
        Assert.Contains("--fullscreen", result);
    }
}
```

---

## Contributing Guidelines

### Code Style

**Follow C# Conventions:**
- Use XML documentation comments for public members
- Keep methods focused (single responsibility)
- Prefer `async/await` for I/O operations
- Use LINQ for collection operations

**Example**:
```csharp
/// <summary>
/// Retrieves packages matching the specified filter.
/// </summary>
/// <param name="filter">Package name filter (e.g., "game").</param>
/// <returns>List of matching package names.</returns>
public async Task<List<string>> GetFilteredPackages(string filter)
{
    var allPackages = await GetPackageList(selectedDevice);
    return allPackages
        .Where(p => p.Contains(filter, StringComparison.OrdinalIgnoreCase))
        .OrderBy(p => p)
        .ToList();
}
```

### Pull Request Process

1. **Fork** the repository
2. **Create** feature branch: `git checkout -b feature/new-option`
3. **Make** changes following code style
4. **Add** XML documentation to new members
5. **Test** thoroughly (manual checklist)
6. **Commit** with clear message: `git commit -m "Add power-off-on-close option"`
7. **Push** to fork: `git push origin feature/new-option`
8. **Open** pull request with description of changes

### Commit Message Format

```
[Type] Brief description (50 chars max)

Detailed explanation of what changed and why.
Reference any related issues.

- Bullet points for multiple changes
- Keep each line under 72 characters

Fixes #123
```

**Types:**
- `[Feature]` - New functionality
- `[Fix]` - Bug fix
- `[Docs]` - Documentation only
- `[Refactor]` - Code restructuring
- `[Style]` - Formatting changes
- `[Test]` - Adding tests

---

## Performance Considerations

### Async Best Practices

**DO**:
```csharp
public async Task<List<string>> GetPackagesAsync()
{
    return await Task.Run(() => QueryPackages());
}
```

**DON'T**:
```csharp
public List<string> GetPackages()
{
    return Task.Run(() => QueryPackages()).Result; // Blocks UI thread!
}
```

### Memory Management

**Unsubscribe from events**:
```csharp
protected override void OnDisappearing()
{
    base.OnDisappearing();

    // Prevent memory leaks
    optionsPanel.ScrcpyCommandChanged -= OnCommandChanged;
}
```

**Dispose of resources**:
```csharp
using (var process = new Process())
{
    // Process automatically disposed
}
```

### UI Responsiveness

**Long operations in background**:
```csharp
private async void OnExecuteCommand(object sender, EventArgs e)
{
    // Show loading indicator
    LoadingSpinner.IsVisible = true;

    try
    {
        // Run on background thread
        var result = await Task.Run(() =>
            AdbCmdService.RunScrcpyCommand(command)
        );

        // Update UI on main thread
        await MainThread.InvokeOnMainThreadAsync(() => {
            ResultLabel.Text = result.Output;
        });
    }
    finally
    {
        LoadingSpinner.IsVisible = false;
    }
}
```

---

## Resources

### Official Documentation
- **.NET MAUI**: https://learn.microsoft.com/en-us/dotnet/maui/
- **C# Guide**: https://learn.microsoft.com/en-us/dotnet/csharp/
- **Scrcpy**: https://github.com/Genymobile/scrcpy
- **ADB**: https://developer.android.com/tools/adb

### Community
- **Scrcpy-GUI Issues**: https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues
- **.NET MAUI Discord**: https://aka.ms/maui-discord
- **Stack Overflow**: Tag `[.net-maui]`

---

**Last Updated**: 2025-12-22
**Version**: 1.5 (.NET MAUI - Legacy)
