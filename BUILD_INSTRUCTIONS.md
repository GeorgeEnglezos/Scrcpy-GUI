# Build and Run Instructions

> **DEPRECATION NOTICE**: This .NET MAUI application is being replaced by a Flutter version.

## Quick Start

### For Development (Debug Mode)

```bash
# Clone the repository
git clone https://github.com/GeorgeEnglezos/Scrcpy-GUI.git
cd Scrcpy-GUI

# Restore dependencies
dotnet restore

# Build and run
dotnet run -f net9.0-windows10.0.19041.0
```

The application will launch in debug mode with full debugging symbols.

### For Distribution (Release Mode)

```bash
# Build optimized release version
dotnet build -c Release -f net9.0-windows10.0.19041.0

# Publish as single-file executable
dotnet publish -c Release -f net9.0-windows10.0.19041.0 -p:PublishSingleFile=true

# Output location:
# bin/Release/net9.0-windows10.0.19041.0/win-x64/publish/ScrcpyGUI.exe
```

---

## Prerequisites

### Required Software

1. **.NET 9.0 SDK** or later
   - Download: https://dotnet.microsoft.com/download/dotnet/9.0
   - Verify installation: `dotnet --version`

2. **.NET MAUI Workload**
   ```bash
   dotnet workload install maui
   ```

   Verify installation:
   ```bash
   dotnet workload list
   ```

   Expected output:
   ```
   Installed Workload Id      Manifest Version
   -------------------------------------------
   maui-windows              9.0.x
   ```

3. **Visual Studio 2022** (Optional but recommended)
   - Version 17.8 or later
   - Workload: ".NET Multi-platform App UI development"
   - Download: https://visualstudio.microsoft.com/

4. **Windows 10/11**
   - Build 19041 (Windows 10 version 2004) or later
   - Windows 11 fully supported

### External Dependencies

These are **not** required for building, but are needed to run the application:

1. **Scrcpy** - The screen mirroring tool
   - Download: https://github.com/Genymobile/scrcpy/releases
   - Extract to a permanent location (e.g., `C:\scrcpy`)
   - You'll configure this path in the app settings

2. **ADB (Android Debug Bridge)** - For device communication
   - Included with Scrcpy
   - Or download Android Platform Tools: https://developer.android.com/tools/releases/platform-tools
   - Add to PATH or use full path in app

---

## Build Commands Reference

### Development Builds

**Debug Build (with symbols):**
```bash
dotnet build -f net9.0-windows10.0.19041.0
```

**Run without building:**
```bash
dotnet run -f net9.0-windows10.0.19041.0
```

**Clean build artifacts:**
```bash
dotnet clean
```

**Full rebuild:**
```bash
dotnet clean && dotnet build -f net9.0-windows10.0.19041.0
```

### Release Builds

**Standard release build:**
```bash
dotnet build -c Release -f net9.0-windows10.0.19041.0
```

**Single-file executable (recommended):**
```bash
dotnet publish -c Release -f net9.0-windows10.0.19041.0 -p:PublishSingleFile=true
```

**Advanced publish options:**
```bash
# With ReadyToRun compilation (faster startup)
dotnet publish -c Release -f net9.0-windows10.0.19041.0 \
  -p:PublishSingleFile=true \
  -p:PublishReadyToRun=true

# Framework-dependent deployment (smaller size, requires .NET runtime on target)
dotnet publish -c Release -f net9.0-windows10.0.19041.0 \
  -p:PublishSingleFile=true \
  -p:SelfContained=false
```

**⚠️ Parameters to Avoid:**

These parameters may cause issues with .NET MAUI applications:
- `-p:SelfContained=true` - Can cause compatibility issues
- `-p:PublishTrimmed=true` - May break reflection-based features
- `-p:PublishAot=true` - Not supported for MAUI

---

## Build Output Locations

### Debug Build
```
ScrcpyGUI/
└── bin/
    └── Debug/
        └── net9.0-windows10.0.19041.0/
            └── win-x64/
                └── ScrcpyGUI.exe
```

### Release Build
```
ScrcpyGUI/
└── bin/
    └── Release/
        └── net9.0-windows10.0.19041.0/
            └── win-x64/
                └── ScrcpyGUI.exe
```

### Published Release
```
ScrcpyGUI/
└── bin/
    └── Release/
        └── net9.0-windows10.0.19041.0/
            └── win-x64/
                └── publish/
                    └── ScrcpyGUI.exe  ← Distribute this file
```

---

## Using Visual Studio

### Opening the Project

1. Launch Visual Studio 2022
2. `File > Open > Project/Solution`
3. Navigate to `ScrcpyGUI.sln`
4. Click `Open`

### Building

**Debug Build:**
- Menu: `Build > Build Solution` (Ctrl+Shift+B)
- Or: Click `Build` in toolbar

**Release Build:**
1. Change configuration dropdown to `Release`
2. Menu: `Build > Build Solution`

### Running

**Debug Mode:**
- Menu: `Debug > Start Debugging` (F5)
- Or: Click green play button

**Run Without Debugging:**
- Menu: `Debug > Start Without Debugging` (Ctrl+F5)

### Publishing

1. Right-click project in Solution Explorer
2. Select `Publish`
3. Choose `Folder` target
4. Configure publish profile:
   - Target Framework: `net9.0-windows10.0.19041.0`
   - Deployment Mode: `Framework-dependent`
   - Target Runtime: `win-x64`
   - Single File: `Yes`
5. Click `Publish`

---

## Using VS Code

### Setup

1. Install extensions:
   - C# (ms-dotnettools.csharp)
   - C# Dev Kit (ms-dotnettools.csdevkit)

2. Open folder containing `ScrcpyGUI.sln`

3. VS Code will prompt to install recommended extensions - click `Install`

### Building and Running

**Using Command Palette (Ctrl+Shift+P):**
- `Tasks: Run Build Task` → Select `build`
- `Tasks: Run Task` → Select `run`

**Using Terminal:**
```bash
# Build
dotnet build -f net9.0-windows10.0.19041.0

# Run
dotnet run -f net9.0-windows10.0.19041.0
```

### Recommended tasks.json

Create `.vscode/tasks.json`:

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
      ],
      "problemMatcher": "$msCompile",
      "group": {
        "kind": "build",
        "isDefault": true
      }
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
      ],
      "problemMatcher": "$msCompile"
    },
    {
      "label": "publish",
      "command": "dotnet",
      "type": "process",
      "args": [
        "publish",
        "${workspaceFolder}/ScrcpyGUI/ScrcpyGUI.csproj",
        "-c",
        "Release",
        "-f",
        "net9.0-windows10.0.19041.0",
        "-p:PublishSingleFile=true"
      ],
      "problemMatcher": "$msCompile"
    }
  ]
}
```

---

## Platform Target Information

### Target Framework
- **TFM**: `net9.0-windows10.0.19041.0`
- **Windows Version**: 10.0.19041 (Windows 10, version 2004 - May 2020 Update)
- **Minimum OS**: Windows 10 version 2004 or later
- **Recommended OS**: Windows 11

### Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Windows 10 (Build 19041+) | ✅ Fully Supported | Minimum required version |
| Windows 11 | ✅ Fully Supported | Recommended |
| macOS | ❌ Not Supported | .NET MAUI macOS requires different configuration |
| Linux | ❌ Not Supported | .NET MAUI doesn't support Linux desktop |

---

## Troubleshooting

### Build Errors

**Error**: `The name 'InitializeComponent' does not exist`
```bash
# Solution: Clean and rebuild
dotnet clean
dotnet build -f net9.0-windows10.0.19041.0
```

**Error**: `Could not find a part of the path`
```bash
# Solution: Shorten project path or use shorter directory names
# Windows has a 260 character path limit
```

**Error**: `NETSDK1045: The current .NET SDK does not support targeting .NET 9.0`
```bash
# Solution: Update .NET SDK
dotnet --version  # Check current version
# Download latest SDK from dotnet.microsoft.com
```

**Error**: `Platform 'net9.0-windows10.0.19041.0' not found`
```bash
# Solution: Install MAUI workload
dotnet workload install maui-windows
```

### Runtime Errors

**Error**: Application won't start after publish
```bash
# Check if Windows version is supported:
winver  # Should show Version 2004 (Build 19041) or higher

# Try framework-dependent build instead:
dotnet publish -c Release -f net9.0-windows10.0.19041.0 \
  -p:PublishSingleFile=true \
  -p:SelfContained=false
```

**Error**: `The application requires .NET Desktop Runtime`
```
Solution: Install .NET 9.0 Runtime
Download: https://dotnet.microsoft.com/download/dotnet/9.0
Select: ".NET Desktop Runtime"
```

### Performance Issues

**Slow build times:**
```bash
# Enable parallel builds
dotnet build -f net9.0-windows10.0.19041.0 -m

# Or set in environment
$env:UseSharedCompilation = 'true'
```

**Large output size:**
```bash
# Use framework-dependent deployment
dotnet publish -c Release -f net9.0-windows10.0.19041.0 \
  -p:PublishSingleFile=true \
  -p:SelfContained=false

# Result: ~10-20 MB instead of ~100+ MB
# Requires .NET runtime on target machine
```

---

## CI/CD Integration

### GitHub Actions Example

`.github/workflows/build.yml`:
```yaml
name: Build Scrcpy-GUI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '9.0.x'

    - name: Install MAUI workload
      run: dotnet workload install maui-windows

    - name: Restore dependencies
      run: dotnet restore

    - name: Build
      run: dotnet build -c Release -f net9.0-windows10.0.19041.0

    - name: Publish
      run: dotnet publish -c Release -f net9.0-windows10.0.19041.0 -p:PublishSingleFile=true

    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: ScrcpyGUI-Release
        path: ScrcpyGUI/bin/Release/net9.0-windows10.0.19041.0/win-x64/publish/
```

---

## Additional Resources

- **Full Development Guide**: See [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)
- **Architecture Documentation**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **API Reference**: See [API_REFERENCE.md](API_REFERENCE.md)
- **.NET MAUI Documentation**: https://learn.microsoft.com/en-us/dotnet/maui/
- **Scrcpy Documentation**: https://github.com/Genymobile/scrcpy

---

**Last Updated**: 2025-12-22
**Project Version**: 1.5 (.NET MAUI - Legacy)
