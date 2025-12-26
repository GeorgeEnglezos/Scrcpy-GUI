# Scrcpy GUI - Features Documentation

Comprehensive overview of all features and capabilities in the Scrcpy GUI application.

## Table of Contents

1. [Core Features](#core-features)
2. [Device Management](#device-management)
3. [Command Builder System](#command-builder-system)
4. [All Command Panels](#all-command-panels)
5. [User Interface Features](#user-interface-features)
6. [Data Management](#data-management)
7. [Cross-Platform Support](#cross-platform-support)
8. [Advanced Capabilities](#advanced-capabilities)

---

## Core Features

### 🎯 Visual Command Builder

**What it does:**
- Converts scrcpy command-line flags into an intuitive graphical interface
- Real-time command generation as you adjust settings
- Syntax-highlighted command display with color-coding by category

**Benefits:**
- No need to memorize command-line flags
- Visual organization of related options
- Instant preview of generated command
- Reduces syntax errors and typos

**How it works:**
- Each panel manages a specific category of options
- Options are organized into logical groups (Audio, Video, Recording, etc.)
- Changes propagate immediately to the command builder service
- Final command displayed at bottom with syntax highlighting

---

### 📱 Device Management

**Automatic Device Detection:**
- Continuous polling every 2 seconds for device changes
- Detects both USB and TCP/IP (wireless) connections
- Auto-refreshes device list on connection/disconnection
- Shows device serial number, model name, or IP:PORT

**Device Information Caching:**
- **Installed Packages**: All user-installed apps cached for package selector
- **Video Codecs**: Available H.264, H.265, AV1 encoders discovered automatically
- **Audio Codecs**: Available Opus, AAC, FLAC encoders cached per device
- **Device Properties**: Model, Android version, API level

**Multi-Device Support:**
- Handle multiple connected devices simultaneously
- Switch between devices via dropdown selector
- Each device maintains independent codec/package cache
- Clear visual indication of selected device

**Connection Types:**
- **USB**: Direct wired connection with lowest latency
- **WiFi (TCP/IP)**: Wireless connection for cable-free usage
- **Mixed**: Support both simultaneously

---

### 🔄 Wireless Connection Wizard

**One-Click Setup:**
1. Device connected via USB
2. Enter port number (default: 5555)
3. Click "Connect Wirelessly"
4. Automatic ADB commands executed in sequence
5. Success confirmation displayed
6. Remove USB cable

**Behind the Scenes:**
```bash
adb tcpip 5555                    # Enable TCP/IP on device
adb devices                       # Get device IP
adb connect <DEVICE_IP>:5555     # Connect wirelessly
```

**Features:**
- Automatic IP address detection
- Port configuration (default: 5555)
- Connection status feedback
- Persistent wireless connections across app restarts
- Manual reconnection support

---

### 🎬 Process Monitoring

**System-Wide Detection:**
- Detects ALL scrcpy processes on system (not just app-started)
- Works across multiple terminal windows
- Real-time process information
- Auto-refresh every 5 seconds

**Information Displayed:**

**Windows:**
- Process ID (PID)
- Device serial/IP address
- Window title
- Connection type (USB/Wireless)
- Process uptime
- Memory usage

**macOS/Linux:**
- Process ID (PID)
- Device serial/IP address
- Window title
- Connection type (USB/Wireless)
- Process start time

**Management Actions:**
- **Kill Process**: Terminate individual scrcpy instance
- **Kill All**: Terminate all scrcpy processes at once
- **Reconnect**: Re-execute the same command
- **View Details**: Expand/collapse detailed information
- **Manual Refresh**: Force refresh of process list

---

## Command Builder System

### Modular Architecture

**Option Groups:**

1. **GeneralCastOptions**
   - Window properties (title, size, position)
   - Display settings (orientation, crop)
   - Video encoding (codec, bitrate)
   - Power management

2. **AudioOptions**
   - Audio codec and encoder
   - Bitrate configuration
   - Buffer settings
   - Source selection

3. **ScreenRecordingOptions**
   - Output file and format
   - Quality settings
   - Recording behavior

4. **VirtualDisplayOptions**
   - Resolution and DPI
   - Display creation
   - System decorations

5. **CameraOptions**
   - Camera selection
   - Resolution and FPS
   - High-speed mode

6. **InputControlOptions**
   - Keyboard/mouse modes
   - Input forwarding
   - Text injection

7. **NetworkOptions**
   - TCP/IP configuration
   - SSH tunneling
   - ADB forwarding

8. **AdvancedOptions**
   - Verbosity levels
   - Cleanup behavior
   - V4L2 support (Linux)

9. **OTGOptions**
   - HID keyboard/mouse
   - OTG mode enabling

**Command Generation:**
```dart
// Each option group generates its portion
audioOptions.toCommand()      // → "--audio-codec opus --audio-bit-rate 192K"
recordingOptions.toCommand()  // → "--record output.mp4 --record-format mp4"

// Combined into final command
scrcpy <device_flag> <all_option_flags>
```

---

## All Command Panels

### 1. 🪟 General/Common Commands Panel

**Categories:**

**Window Management:**
- Custom window title
- Fullscreen toggle
- Borderless window
- Always on top
- Window position (X, Y)
- Window size (Width, Height)

**Screen Control:**
- Turn screen off immediately
- Stay awake while connected
- Disable screensaver
- Power off on close

**Display Configuration:**
- Crop screen (W:H:X:Y format)
- Lock orientation (0°, 90°, 180°, 270°)
- Display rotation

**Video Encoding:**
- Video bitrate (quality control)
- Video codec selection (H.264, H.265, AV1)
- Device-specific encoder selection

**Miscellaneous:**
- Print FPS counter
- Time limit for session
- Extra parameters field

---

### 2. 🎵 Audio Commands Panel

**Audio Quality:**
- Bitrate: 64K to 320K
- Buffer size: 256ms to 2048ms
- Codec options configuration

**Audio Sources:**
- System output (default)
- Media playback
- Microphone (5 variants)
  - Standard mic
  - Unprocessed
  - Camcorder mode
  - Voice recognition mode
  - Voice communication mode

**Codec Selection:**
- Opus (default, best quality)
- AAC (compatibility)
- FLAC (lossless)
- Raw (uncompressed)

**Device-Specific Encoders:**
- Auto-loaded from device
- Refreshable codec list
- Shows available hardware encoders

**Special Options:**
- Disable audio forwarding
- Audio duplication (play on both)

---

### 3. 🎥 Recording Commands Panel

**Output Configuration:**
- Enable/disable recording
- Custom filename
- Output directory selection
- Format selection (MP4, MKV, AVI, MOV, WEBM)

**Quality Control:**
- Maximum FPS limit
- Maximum resolution (max-size)
- Recording orientation lock
- Time limit for recording

**Advanced:**
- No display mode (record without mirroring)
- Combine with other options

**Smart Features:**
- Auto-add file extension
- Directory browser integration
- Default path configuration

---

### 4. 📷 Camera Commands Panel

**Camera Selection:**
- Camera ID (specific camera)
- Camera facing (front/back/external)
- List cameras command helper

**Resolution:**
- Custom resolution (WxH)
- Aspect ratio selection
- Sensor aspect ratio option

**Performance:**
- Frame rate configuration
- High-speed mode toggle
- Quality presets

**Use Cases:**
- Document camera
- Security monitoring
- Content creation
- Remote photography

---

### 5. 🖥️ Display & Window Panel

**Positioning:**
- Window X coordinate
- Window Y coordinate
- Absolute positioning

**Sizing:**
- Custom width
- Custom height
- Precise dimensions

**Display Options:**
- Display ID (multi-display)
- Display rotation (0-3)
- Display buffer size

**Rendering:**
- Render driver selection
- Force ADB forward mode

---

### 6. 🎮 Input Control Panel

**Control Modes:**
- Disable all control (view-only)
- Keyboard mode (SDK, UHID, AOA)
- Mouse mode (SDK, UHID, AOA)

**Keyboard Options:**
- Legacy paste mode
- Disable key repeat
- Raw key events
- Prefer text injection

**Mouse Options:**
- Disable hover events
- Forward all clicks
- Mouse button bindings

**Gaming Optimization:**
- UHID mode for better compatibility
- AOA mode for physical input
- Raw input support

---

### 7. 🌐 Network Connection Panel

**TCP/IP Configuration:**
- Port number setting
- Auto-select TCP/IP devices
- Disable ADB forward

**SSH Tunneling:**
- Tunnel host configuration
- Custom port support
- Remote connection setup

**Wireless Features:**
- One-click wireless setup
- Connection persistence
- Manual reconnection

---

### 8. 📺 Virtual Display Panel

**Display Creation:**
- New virtual display
- Custom resolution
- DPI configuration
- Display flags

**Behavior:**
- Destroy content on exit
- System decorations toggle
- Display ID assignment

**Use Cases:**
- Recording without main display
- Custom resolution output
- Multi-display scenarios
- Testing different screen sizes

---

### 9. ⚙️ Advanced/Developer Panel

**Debugging:**
- Verbosity levels (verbose, debug, info, warn, error)
- Log output control
- Error behavior

**Cleanup:**
- Disable cleanup on exit
- Disable auto-downsize on error
- Keep server binary

**V4L2 (Linux Only):**
- V4L2 sink device path
- Buffer delay configuration
- Virtual webcam support

---

### 10. 🔌 OTG Mode Panel

**OTG Features:**
- Enable OTG mode
- HID keyboard simulation
- HID mouse simulation

**Requirements:**
- USB connection
- Android 11+ or custom ROM
- No screen mirroring

**Applications:**
- Broken screen device control
- Low-latency input
- Physical input simulation

---

## User Interface Features

### 🎨 Syntax Highlighting

**Color-Coded Commands:**
- 🔴 **Red** - Recording flags (`--record`, `--record-format`)
- 🔵 **Blue** - Virtual display (`--new-display`, `--vd-*`)
- 🟠 **Orange** - General window/display (`--fullscreen`, `--video-codec`)
- 🟢 **Green** - Audio (`--audio-codec`, `--audio-bit-rate`)
- 🟡 **Amber** - Package selection (`--start-app`)
- ⚪ **White** - Command and unknown flags
- ⚫ **White70** - Parameter values

**Benefits:**
- Quick visual parsing
- Category identification
- Error spotting
- Professional appearance

---

### 📋 Command Actions Panel

**Primary Actions:**

**▶️ Run Button:**
- Executes generated command
- Opens in new terminal (configurable)
- Starts scrcpy process
- Green color for positive action

**⭐ Favorite Button:**
- Saves current configuration
- Stores all panel states
- Timestamp tracking
- Red/pink color when saved

**📥 Download Button:**
- Exports as .bat (Windows) or .sh script
- Intelligent filename generation
- Saves to configured directory
- One-click script creation

**🧹 Clear All Button:**
- Resets all panels to defaults
- Clears all form fields
- Keeps device selection
- Quick reset functionality

**📡 Wireless Connect:**
- Initiates wireless setup
- Port configuration
- Status feedback
- Green color for connectivity

---

### ⭐ Favorites System

**Save & Organize:**
- Save unlimited command configurations
- Automatic timestamp recording
- Execution count tracking
- Quick access from dedicated page

**Favorites Page Features:**
- List all saved commands
- Syntax-highlighted display
- Copy to clipboard
- Download as script
- Delete unwanted favorites
- Run directly from favorites

**Command History:**
- Last executed command always saved
- Most-used commands highlighted
- Chronological sorting
- Frequency tracking

---

### 🎛️ Panel Customization

**Layout Control:**
- Drag-and-drop reordering
- Show/hide individual panels
- Full-width panel option
- Reset to defaults

**Persistence:**
- Layout saved between sessions
- Per-user configuration
- Automatic state restoration

**Access:**
- Settings page → Panel Customization
- Visual editor interface
- Real-time preview

---

### 🎯 Smart Features

**Auto-Detection:**
- Device codecs discovery
- Package list caching
- IP address detection
- Process discovery

**Intelligent Naming:**
- Auto-generated .bat filenames
- Based on command content
- Unique names for conflicts
- Clean, readable format

**Validation:**
- Required field highlighting
- Valid value ranges
- Format checking
- Error prevention

---

## Data Management

### 💾 Persistent Storage

**Settings Persistence:**
```json
{
  "scrcpyPath": "C:\\scrcpy",
  "recordingsPath": "C:\\Recordings",
  "downloadsPath": "C:\\Downloads",
  "panelOrder": ["general", "audio", ...],
  "hiddenPanels": [],
  "startupTab": "home"
}
```

**Command History:**
```json
{
  "lastCommand": "scrcpy --record ...",
  "favorites": [
    {
      "command": "...",
      "timestamp": "2024-01-15T10:30:00",
      "execCount": 5
    }
  ]
}
```

**Storage Locations:**
- **Windows**: `%APPDATA%\ScrcpyGui\`
- **macOS**: `~/Documents/ScrcpyGui/`
- **Linux**: `~/Documents/ScrcpyGui/`

---

### 📂 File Export

**Batch/Script Export:**
- Windows: `.bat` files
- macOS/Linux: `.sh` files (future)
- Executable permissions set
- Double-click to run

**Export Features:**
- Automatic file extension
- Directory selection
- Filename sanitization
- Overwrite protection

---

## Cross-Platform Support

### 💻 Platform-Specific Features

**Windows:**
- Bat file generation
- Detailed process information (uptime, memory)
- WMIC process queries
- Start menu integration (future)

**macOS:**
- AppleScript terminal integration
- Homebrew path detection
- Native UI elements
- Bundle creation (future)

**Linux:**
- Shell script export
- V4L2 virtual camera support
- Multiple terminal emulator detection
- Package manager integration

---

### 🔧 Platform Adaptations

**Terminal Execution:**

**Windows:**
```bash
cmd /c start cmd /k <command>
```

**macOS:**
```applescript
tell application "Terminal" to do script "<command>"
```

**Linux:**
Auto-detects: gnome-terminal, konsole, xfce4-terminal, xterm

**Process Detection:**

**Windows:**
```bash
tasklist /FI "IMAGENAME eq scrcpy.exe" /FO CSV
WMIC process where name="scrcpy.exe" get ...
```

**Unix (macOS/Linux):**
```bash
ps aux | grep scrcpy | grep -v grep
```

---

## Advanced Capabilities

### 🔍 Codec Discovery

**Automatic Detection:**
```bash
# Video codecs
adb shell dumpsys media.player | grep -i "video codecs"

# Audio codecs
adb shell dumpsys media.player | grep -i "audio codecs"
```

**Caching Strategy:**
- Query once per device
- Store in memory map
- Refresh on device change
- Manual refresh available

---

### 📦 Package Management

**App Discovery:**
```bash
adb shell pm list packages -3  # User-installed only
```

**Features:**
- Filter system apps
- Cache package list
- Quick search
- Launch with scrcpy

---

### 🚀 Performance Optimizations

**Efficient Updates:**
- ValueNotifier for fine-grained reactivity
- Provider for global state
- Debounced command building
- Lazy loading of device info

**Resource Management:**
- Process cleanup on exit
- Timer cancellation
- Stream disposal
- Memory-efficient caching

---

### 🎓 Built-in Help System

**Resources Page:**
- Official scrcpy documentation links
- ADB command reference
- FAQ section
- Useful commands list
- Community resources
- Troubleshooting guides

**Tooltips:**
- Every field has contextual help
- Hover for detailed explanations
- Parameter format examples
- Default value information

---

## Feature Summary Matrix

| Feature | Windows | macOS | Linux |
|---------|---------|-------|-------|
| USB Connection | ✅ | ✅ | ✅ |
| Wireless Connection | ✅ | ✅ | ✅ |
| Device Detection | ✅ | ✅ | ✅ |
| Process Monitoring | ✅ Full | ✅ Basic | ✅ Basic |
| Script Export | ✅ .bat | 🚧 .sh | 🚧 .sh |
| Terminal Integration | ✅ | ✅ | ✅ |
| V4L2 Virtual Camera | ❌ | ❌ | ✅ |
| Codec Discovery | ✅ | ✅ | ✅ |
| Package List | ✅ | ✅ | ✅ |
| Favorites System | ✅ | ✅ | ✅ |
| Panel Customization | ✅ | ✅ | ✅ |
| Settings Persistence | ✅ | ✅ | ✅ |

**Legend:**
- ✅ Fully Supported
- 🚧 Planned/In Progress
- ❌ Not Applicable

---

## Upcoming Features

See [README.md Roadmap](README.md#roadmap) for planned enhancements:
- Multi-device simultaneous control
- Command templates/presets
- Built-in recording player
- Keyboard shortcuts
- Command validation
- scrcpy version management
- Export/import settings
- Localization support
- Theme customization
- Plugin system

---

**For detailed usage instructions, see [USER_GUIDE.md](USER_GUIDE.md)**

**For troubleshooting help, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**

**For developer documentation, see [API_REFERENCE.md](API_REFERENCE.md)**
