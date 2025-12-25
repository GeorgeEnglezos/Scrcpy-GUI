# Scrcpy-GUI API Reference

> **DEPRECATION NOTICE**: This .NET MAUI application is being replaced by a Flutter version. This documentation serves as a reference for the legacy codebase.

## Table of Contents
- [Services](#services)
  - [DataStorage](#datastorage)
  - [AdbCmdService](#adbcmdservice)
- [Models](#models)
  - [ScrcpyGuiData](#scrcpyguidata)
  - [ConnectedDevice](#connecteddevice)
  - [CmdCommandResponse](#cmdcommandresponse)
- [Controls](#controls)
  - [OptionsPanel](#optionspanel)
  - [OutputPanel](#outputpanel)

---

## Services

### DataStorage

Static service class for persisting and retrieving application data using JSON serialization.

#### Properties

##### `settingsPath`
```csharp
public static readonly string settingsPath
```
**Description**: File path where application settings are stored.
**Value**: `{AppDataDirectory}/ScrcpyGui-Data.json`

##### `staticSavedData`
```csharp
public static ScrcpyGuiData staticSavedData
```
**Description**: Cached instance of loaded application data.
**Access**: Public static

#### Methods

##### `LoadData()`
```csharp
public static ScrcpyGuiData LoadData()
```
**Description**: Loads application data from the JSON settings file. Creates a new file with defaults if it doesn't exist.

**Returns**: `ScrcpyGuiData` - Loaded or default application data

**Example**:
```csharp
var data = DataStorage.LoadData();
Console.WriteLine($"Recent command: {data.MostRecentCommand}");
```

##### `SaveData(ScrcpyGuiData data)`
```csharp
public static void SaveData(ScrcpyGuiData data)
```
**Description**: Serializes and saves application data to JSON file.

**Parameters**:
- `data` (ScrcpyGuiData): Data object to persist

**Example**:
```csharp
data.AppSettings.ScrcpyPath = "C:\\scrcpy";
DataStorage.SaveData(data);
```

##### `AppendFavoriteCommand(string command)`
```csharp
public static void AppendFavoriteCommand(string command)
```
**Description**: Adds a command to the favorites list if not already present.

**Parameters**:
- `command` (string): Scrcpy command to save

**Example**:
```csharp
DataStorage.AppendFavoriteCommand("scrcpy.exe --fullscreen");
```

##### `RemoveFavoriteCommandAtIndex(int index, ScrcpyGuiData data)`
```csharp
public static void RemoveFavoriteCommandAtIndex(int index, ScrcpyGuiData data)
```
**Description**: Removes a favorite command at the specified index and saves changes.

**Parameters**:
- `index` (int): Zero-based index of command to remove
- `data` (ScrcpyGuiData): Current data instance

**Example**:
```csharp
var data = DataStorage.LoadData();
DataStorage.RemoveFavoriteCommandAtIndex(2, data);
```

##### `SaveMostRecentCommand(string command)`
```csharp
public static void SaveMostRecentCommand(string command)
```
**Description**: Updates the most recently executed command.

**Parameters**:
- `command` (string): Command that was just executed

**Example**:
```csharp
DataStorage.SaveMostRecentCommand("scrcpy.exe --record=output.mp4");
```

##### `ValidateAndCreatePath(string folderPath, string fallbackPath = null)`
```csharp
public static string ValidateAndCreatePath(string folderPath, string fallbackPath = null)
```
**Description**: Validates that a folder exists, creating it if necessary. Uses fallback if creation fails.

**Parameters**:
- `folderPath` (string): Primary path to validate
- `fallbackPath` (string, optional): Alternative path if primary fails

**Returns**: `string` - Valid existing path

**Example**:
```csharp
string recordPath = DataStorage.ValidateAndCreatePath(
    userPath,
    Environment.GetFolderPath(Environment.SpecialFolder.MyVideos)
);
```

##### `CopyToClipboardAsync(string text)`
```csharp
public static async Task<string> CopyToClipboardAsync(string text)
```
**Description**: Copies text to clipboard and displays a confirmation dialog. Handles platform-specific errors.

**Parameters**:
- `text` (string): Text to copy

**Returns**: `Task<string>` - Empty string on completion

**Example**:
```csharp
await DataStorage.CopyToClipboardAsync("scrcpy.exe --max-size=1920");
```

---

### AdbCmdService

Static service class for executing ADB and Scrcpy commands, managing device connections.

#### Enumerations

##### `CommandEnum`
```csharp
public enum CommandEnum
{
    GetPackages,
    RunScrcpy,
    CheckAdbVersion,
    CheckScrcpyVersion,
    GetCodecsEncoders,
    ListDevices,
    InstallApk,
    UninstallPackage,
    ConnectTCP,
    DisconnectTCP,
    RestartServer,
    PairDevice
}
```
**Description**: Enumeration of supported command types.

#### Properties

##### `scrcpyPath`
```csharp
public static string scrcpyPath
```
**Description**: Path to the scrcpy executable directory.

#### Methods

##### `RunScrcpyCommand(string command)`
```csharp
public static async Task<CmdCommandResponse> RunScrcpyCommand(string command)
```
**Description**: Executes a Scrcpy command on the selected device. Automatically prepends device selection.

**Parameters**:
- `command` (string): Scrcpy command parameters

**Returns**: `Task<CmdCommandResponse>` - Command execution results

**Example**:
```csharp
var result = await AdbCmdService.RunScrcpyCommand("--fullscreen --turn-screen-off");
if (string.IsNullOrEmpty(result.RawError))
{
    Console.WriteLine("Scrcpy started successfully");
}
```

##### `RunAdbCommandAsync(CommandEnum commandType, string arguments = "")`
```csharp
public static async Task<CmdCommandResponse> RunAdbCommandAsync(
    CommandEnum commandType,
    string arguments = ""
)
```
**Description**: Executes an ADB command with the specified type and arguments.

**Parameters**:
- `commandType` (CommandEnum): Type of command to execute
- `arguments` (string, optional): Additional command arguments

**Returns**: `Task<CmdCommandResponse>` - Command execution results

**Example**:
```csharp
var result = await AdbCmdService.RunAdbCommandAsync(
    CommandEnum.InstallApk,
    "C:\\app.apk"
);
```

##### `GetAdbDevices()`
```csharp
public static List<ConnectedDevice> GetAdbDevices()
```
**Description**: Retrieves a list of all connected Android devices with their codec/encoder capabilities.

**Returns**: `List<ConnectedDevice>` - List of connected devices

**Example**:
```csharp
var devices = AdbCmdService.GetAdbDevices();
foreach (var device in devices)
{
    Console.WriteLine($"Device: {device.DisplayName} ({device.DeviceId})");
}
```

##### `GetPackageList(string selectedDevice)`
```csharp
public static async Task<List<string>> GetPackageList(string selectedDevice)
```
**Description**: Queries all installed packages on the specified device.

**Parameters**:
- `selectedDevice` (string): Device ID (serial or IP:port)

**Returns**: `Task<List<string>>` - List of package names

**Example**:
```csharp
var packages = await AdbCmdService.GetPackageList("192.168.1.100:5555");
var gamePackages = packages.Where(p => p.Contains("game")).ToList();
```

##### `ConnectWireless(string ipAddress, string port)`
```csharp
public static async Task<CmdCommandResponse> ConnectWireless(
    string ipAddress,
    string port
)
```
**Description**: Establishes wireless ADB connection to a device.

**Parameters**:
- `ipAddress` (string): Device IP address
- `port` (string): ADB port (typically "5555")

**Returns**: `Task<CmdCommandResponse>` - Connection result

**Example**:
```csharp
var result = await AdbCmdService.ConnectWireless("192.168.1.100", "5555");
if (result.Output.Contains("connected"))
{
    Console.WriteLine("Wireless connection established");
}
```

##### `SetScrcpyPath()`
```csharp
public static void SetScrcpyPath()
```
**Description**: Updates the scrcpy executable path from saved settings.

**Example**:
```csharp
AdbCmdService.SetScrcpyPath();
// Now scrcpyPath is set from DataStorage.staticSavedData
```

##### `CheckAdbVersion()`
```csharp
public static async Task<string> CheckAdbVersion()
```
**Description**: Retrieves the installed ADB version.

**Returns**: `Task<string>` - ADB version string

**Example**:
```csharp
string version = await AdbCmdService.CheckAdbVersion();
Console.WriteLine($"ADB Version: {version}");
```

##### `CheckScrcpyVersion()`
```csharp
public static async Task<string> CheckScrcpyVersion()
```
**Description**: Retrieves the installed Scrcpy version.

**Returns**: `Task<string>` - Scrcpy version string

**Example**:
```csharp
string version = await AdbCmdService.CheckScrcpyVersion();
Console.WriteLine($"Scrcpy Version: {version}");
```

---

## Models

### ScrcpyGuiData

Root data model containing all application settings and user data.

#### Properties

##### `MostRecentCommand`
```csharp
public string MostRecentCommand { get; set; }
```
**Description**: The most recently executed Scrcpy command.

##### `FavoriteCommands`
```csharp
public List<string> FavoriteCommands { get; set; }
```
**Description**: List of user-saved favorite commands.

##### `AppSettings`
```csharp
public AppSettings AppSettings { get; set; }
```
**Description**: Application configuration and preferences.

##### `ScreenRecordingOptions`
```csharp
public ScreenRecordingOptions ScreenRecordingOptions { get; set; }
```
**Description**: Screen recording configuration.

##### `VirtualDisplayOptions`
```csharp
public VirtualDisplayOptions VirtualDisplayOptions { get; set; }
```
**Description**: Virtual display settings.

##### `AudioOptions`
```csharp
public AudioOptions AudioOptions { get; set; }
```
**Description**: Audio streaming configuration.

##### `GeneralCastOptions`
```csharp
public GeneralCastOptions GeneralCastOptions { get; set; }
```
**Description**: General Scrcpy casting options.

---

### AppSettings

Application-level settings for UI and paths.

#### Properties

```csharp
public bool OpenCmds { get; set; }
public bool HideTcpPanel { get; set; }
public bool HideStatusPanel { get; set; }
public bool HideOutputPanel { get; set; }
public bool HideRecordingPanel { get; set; }
public bool HideVirtualMonitorPanel { get; set; }
public string HomeCommandPreviewCommandColors { get; set; }
public string FavoritesPageCommandColors { get; set; }
public string ScrcpyPath { get; set; }
public string RecordingPath { get; set; }
public string DownloadPath { get; set; }
```

**Color Settings Values**:
- `"None"` - No syntax highlighting
- `"Important"` - Highlight key parameters only
- `"Complete"` - Full syntax highlighting
- `"Package Only"` - Only highlight package selection

---

### ConnectedDevice

Represents a connected Android device.

#### Properties

##### `DeviceId`
```csharp
public string DeviceId { get; set; }
```
**Description**: Unique device identifier (serial number or IP:port for wireless).

##### `DisplayName`
```csharp
public string DisplayName { get; set; }
```
**Description**: Human-readable device name for UI display.

##### `VideoCodecEncoderPairs`
```csharp
public List<string> VideoCodecEncoderPairs { get; set; }
```
**Description**: List of supported video codec/encoder combinations.

##### `AudioCodecEncoderPairs`
```csharp
public List<string> AudioCodecEncoderPairs { get; set; }
```
**Description**: List of supported audio codec/encoder combinations.

#### Methods

##### `AreDeviceListsEqual(List<ConnectedDevice> a, List<ConnectedDevice> b)`
```csharp
public static bool AreDeviceListsEqual(
    List<ConnectedDevice> a,
    List<ConnectedDevice> b
)
```
**Description**: Compares two device lists to determine if they contain the same device IDs.

**Parameters**:
- `a` (List<ConnectedDevice>): First list
- `b` (List<ConnectedDevice>): Second list

**Returns**: `bool` - True if lists contain identical device IDs

**Example**:
```csharp
var oldDevices = GetDevices();
// ... wait for device change
var newDevices = GetDevices();
if (!ConnectedDevice.AreDeviceListsEqual(oldDevices, newDevices))
{
    Console.WriteLine("Device list changed!");
}
```

---

### CmdCommandResponse

Encapsulates the result of a command-line execution.

#### Properties

##### `Output`
```csharp
public string Output { get; set; }
```
**Description**: Processed output (prioritizes error output if present).

##### `RawOutput`
```csharp
public string RawOutput { get; set; }
```
**Description**: Raw standard output stream.

##### `RawError`
```csharp
public string RawError { get; set; }
```
**Description**: Raw standard error stream.

##### `ExitCode`
```csharp
public int ExitCode { get; set; }
```
**Description**: Process exit code (0 = success).

**Example**:
```csharp
var result = await AdbCmdService.RunScrcpyCommand("--fullscreen");
if (result.ExitCode == 0 && string.IsNullOrEmpty(result.RawError))
{
    Console.WriteLine("Success!");
}
else
{
    Console.WriteLine($"Error: {result.RawError}");
}
```

---

## Controls

### OptionsPanel

Control for building Scrcpy commands through UI inputs.

#### Events

##### `ScrcpyCommandChanged`
```csharp
public event EventHandler<string> ScrcpyCommandChanged
```
**Description**: Raised when the generated command changes.

**Event Args**: `string` - The new complete command

**Example**:
```csharp
optionsPanel.ScrcpyCommandChanged += (sender, command) => {
    Console.WriteLine($"Command updated: {command}");
};
```

#### Methods

##### `ApplySavedVisibilitySettings()`
```csharp
public void ApplySavedVisibilitySettings()
```
**Description**: Shows/hides child panels based on user preferences.

##### `SubscribeToEvents()`
```csharp
public void SubscribeToEvents()
```
**Description**: Subscribes to child panel events and initializes data.

##### `UnsubscribeToEvents()`
```csharp
public void UnsubscribeToEvents()
```
**Description**: Unsubscribes from events to prevent memory leaks.

##### `SetOutputPanelReferenceFromMainPage(OutputPanel outputPanel)`
```csharp
public void SetOutputPanelReferenceFromMainPage(OutputPanel outputPanel)
```
**Description**: Establishes reference to OutputPanel for cross-panel communication.

**Parameters**:
- `outputPanel` (OutputPanel): The OutputPanel instance

---

### OutputPanel

Control for displaying command preview and execution controls.

#### Events

##### `PageRefreshed`
```csharp
public event EventHandler<string> PageRefreshed
```
**Description**: Raised when the page needs to be refreshed.

#### Methods

##### `UpdateCommandPreview(string commandText)`
```csharp
public void UpdateCommandPreview(string commandText)
```
**Description**: Updates the command preview with syntax highlighting.

**Parameters**:
- `commandText` (string): Command to display

**Example**:
```csharp
outputPanel.UpdateCommandPreview("scrcpy.exe --fullscreen --max-fps=60");
```

##### `ApplySavedVisibilitySettings()`
```csharp
public void ApplySavedVisibilitySettings()
```
**Description**: Applies visibility settings to child panels (status, wireless, output).

##### `SubscribeToEvents()`
```csharp
public void SubscribeToEvents()
```
**Description**: Subscribes to child panel events.

##### `UnsubscribeToEvents()`
```csharp
public void UnsubscribeToEvents()
```
**Description**: Unsubscribes from events.

##### `SetOptionsPanelReferenceFromMainPage(OptionsPanel optionsPanel)`
```csharp
public void SetOptionsPanelReferenceFromMainPage(OptionsPanel optionsPanel)
```
**Description**: Establishes event subscription to OptionsPanel.

**Parameters**:
- `optionsPanel` (OptionsPanel): The OptionsPanel instance

---

## Usage Examples

### Complete Workflow Example

```csharp
// 1. Load saved data
var data = DataStorage.LoadData();

// 2. Get connected devices
var devices = AdbCmdService.GetAdbDevices();
if (devices.Count == 0)
{
    Console.WriteLine("No devices connected");
    return;
}

// 3. Select first device
var device = devices[0];
Console.WriteLine($"Using device: {device.DisplayName}");

// 4. Get installed packages
var packages = await AdbCmdService.GetPackageList(device.DeviceId);
var launcher = packages.FirstOrDefault(p => p.Contains("launcher"));

// 5. Build command
string command = "scrcpy.exe --fullscreen --turn-screen-off";
if (!string.IsNullOrEmpty(launcher))
{
    command += $" --start-app={launcher}";
}

// 6. Execute command
var result = await AdbCmdService.RunScrcpyCommand(command);
if (result.ExitCode == 0)
{
    // 7. Save to favorites and recent
    DataStorage.AppendFavoriteCommand(command);
    DataStorage.SaveMostRecentCommand(command);
    Console.WriteLine("Command executed and saved!");
}
else
{
    Console.WriteLine($"Error: {result.RawError}");
}
```

### Wireless Connection Example

```csharp
// 1. Connect to device wirelessly
var connectResult = await AdbCmdService.ConnectWireless("192.168.1.100", "5555");
if (!connectResult.Output.Contains("connected"))
{
    Console.WriteLine($"Connection failed: {connectResult.Output}");
    return;
}

// 2. Refresh device list
var devices = AdbCmdService.GetAdbDevices();
var wirelessDevice = devices.FirstOrDefault(d => d.DeviceId.Contains("192.168.1.100"));

if (wirelessDevice != null)
{
    Console.WriteLine($"Wireless device ready: {wirelessDevice.DisplayName}");

    // 3. Check supported codecs
    Console.WriteLine("Video codecs:");
    foreach (var codec in wirelessDevice.VideoCodecEncoderPairs)
    {
        Console.WriteLine($"  - {codec}");
    }
}
```

---

**Last Updated**: 2025-12-22
**Version**: 1.5 (.NET MAUI - Legacy)
