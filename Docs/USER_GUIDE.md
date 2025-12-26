# Scrcpy GUI - User Guide

Complete guide to using the Scrcpy GUI application for Android screen mirroring and control.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Interface Overview](#interface-overview)
3. [Device Connection](#device-connection)
4. [Command Panels Guide](#command-panels-guide)
5. [Advanced Features](#advanced-features)
6. [Tips & Best Practices](#tips--best-practices)
7. [Keyboard Shortcuts](#keyboard-shortcuts)

---

## Getting Started

### First Time Setup

1. **Install Prerequisites**
   - Ensure scrcpy is installed and accessible from terminal/command prompt
   - Install ADB (Android Debug Bridge) if not included with scrcpy
   - Enable USB debugging on your Android device

2. **Configure Application Settings**
   - Launch Scrcpy GUI
   - Navigate to Settings (gear icon in sidebar)
   - Set your scrcpy installation path if not auto-detected
   - Set default directories for recordings and downloads

3. **Connect Your Device**
   - Connect your Android device via USB
   - Accept the USB debugging prompt on your device
   - The device should appear in the device selector within 2 seconds

### Quick Start Tutorial

**Basic Screen Mirroring (5 seconds):**
```
1. Select device from dropdown
2. Click "Run" button
3. Done! Your screen is now mirroring
```

**Recording Your Screen:**
```
1. Select your device
2. Go to "Recording Commands" panel
3. Enable recording toggle
4. Enter filename (e.g., "my-video.mp4")
5. Click "Run"
6. Recording starts automatically
```

---

## Interface Overview

### Main Navigation (Sidebar)

The vertical sidebar on the left contains 5 main sections:

1. **🏠 Home** - Main command builder interface
2. **⭐ Favorites** - Your saved command configurations
3. **📄 Bat Files** - Scripts page (Windows only)
4. **📁 Resources** - Help, documentation, and useful links
5. **⚙️ Settings** - Application configuration

### Home Page Layout

The Home page is divided into several key areas:

```
┌─────────────────────────────────────────────────┐
│  Device Selector & Status                       │
├─────────────────────────────────────────────────┤
│  Command Actions Panel                          │
│  (Run, Favorite, Download, Clear All)          │
├─────────────────────────────────────────────────┤
│  Configuration Panels (arranged in grid)        │
│  - General                                       │
│  - Audio                                         │
│  - Recording                                     │
│  - Camera                                        │
│  - Display & Window                              │
│  - Input Control                                 │
│  - Network Connection                            │
│  - Virtual Display                               │
│  - Advanced/Developer                            │
│  - OTG Mode                                      │
├─────────────────────────────────────────────────┤
│  Generated Command Display                       │
│  (Syntax-highlighted, color-coded)              │
├─────────────────────────────────────────────────┤
│  Running Instances Panel                         │
│  (Active scrcpy processes)                      │
└─────────────────────────────────────────────────┘
```

### Command Display

The generated command appears at the bottom with color-coding:
- **🔴 Red** - Recording options
- **🔵 Blue** - Virtual display options
- **🟠 Orange** - General/window options
- **🟢 Green** - Audio options
- **🟡 Amber** - Package/app options
- **⚪ White** - Other flags and values

---

## Device Connection

### USB Connection

**Requirements:**
- USB cable (data transfer capable)
- USB debugging enabled on device
- Device drivers installed (Windows)

**Steps:**
1. Connect device to computer
2. On device, tap "Allow USB debugging" when prompted
3. Check "Always allow from this computer" (optional)
4. Device appears in selector as serial number or model name

**Troubleshooting USB:**
- Try different USB cable (some are charge-only)
- Use different USB port
- Reinstall device drivers (Windows)
- Run `adb devices` in terminal to verify detection

### Wireless Connection

**Requirements:**
- Android 11 or higher (recommended)
- Device and computer on same WiFi network
- Initial USB connection required for setup

**Method 1: Using the App (Easiest)**
1. Connect device via USB first
2. In Command Actions panel:
   - Enter port number (default: 5555)
   - Click "Connect Wirelessly"
3. Wait for confirmation message
4. Disconnect USB cable
5. Device appears as `IP:PORT` in selector

**Method 2: Manual ADB Connection**
1. Find device IP address (Settings → About → Status)
2. Connect via USB initially
3. Run: `adb tcpip 5555`
4. Run: `adb connect <DEVICE_IP>:5555`
5. Disconnect USB
6. Refresh device list in app

**Wireless Tips:**
- Use 2.4GHz WiFi for better range, 5GHz for better performance
- Keep devices on same subnet
- Wireless connection may have slightly higher latency
- Battery drains faster in wireless mode

### Multi-Device Management

When multiple devices are connected:
1. All devices appear in the dropdown
2. Select desired device before running commands
3. Each device has independent codec/package cache
4. Commands only execute on selected device

---

## Command Panels Guide

### General Panel

Controls the most common scrcpy options.

**Window Configuration:**
- **Window Title** - Custom window name
- **Fullscreen** - Start in fullscreen mode
- **Window Borderless** - Remove window decorations
- **Window Always on Top** - Keep window above others

**Display Settings:**
- **Screen Off** - Turn device screen off while mirroring
- **Stay Awake** - Keep device awake when plugged in
- **Crop Screen** - Format: `WIDTH:HEIGHT:X:Y`
- **Orientation** - Lock orientation (0, 90, 180, 270 degrees)

**Video Encoding:**
- **Video Bit Rate** - Quality (higher = better quality, larger file)
  - Default: 8M (8 Mbps)
  - Recommended: 4M-16M range
- **Video Codec** - Choose H.264, H.265, or AV1 (device-dependent)

**Advanced:**
- **Disable Screensaver** - Prevent computer from sleeping
- **Print FPS** - Show frame rate in console
- **Power Off on Close** - Turn device screen off when exiting
- **Time Limit** - Auto-stop after N seconds

**Extra Parameters:**
- Add any scrcpy flags not covered by GUI
- Example: `--lock-video-orientation 0`

### Audio Panel

Configure audio streaming from device to computer.

**Audio Quality:**
- **Audio Bit Rate** - Quality of audio stream
  - Default: 128K
  - Options: 64K, 128K, 192K, 256K, 320K
- **Audio Buffer** - Latency vs stability trade-off
  - Default: 50ms
  - Lower = less latency, more glitches
  - Higher = more latency, smoother audio

**Audio Source:**
- **output** - System audio output (default)
- **playback** - Audio being played
- **mic** - Device microphone
- **mic-unprocessed** - Raw microphone input
- **mic-camcorder** - Camcorder-optimized
- **mic-voice-recognition** - Voice recognition optimized
- **mic-voice-communication** - Call-optimized

**Codec Settings:**
- **Audio Codec** - Opus (default), AAC, FLAC, or Raw
- **Audio Encoder** - Device-specific encoder (auto-loaded)
- **Audio Codec Options** - Advanced codec parameters

**Options:**
- **No Audio** - Disable audio forwarding entirely
- **Audio Duplication** - Play audio on both device and computer
  - Only works with `--audio-source=playback`

### Recording Panel

Configure screen recording to video file.

**Basic Settings:**
- **Enable Recording** - Toggle recording mode
- **File Name** - Output filename (with or without extension)
- **Output Directory** - Where to save recording
  - Click folder icon to browse

**Video Settings:**
- **Output Format** - Container format
  - **MP4** - Best compatibility (H.264/H.265 only)
  - **MKV** - Supports all codecs, larger files
  - **AVI** - Legacy format
  - **MOV** - QuickTime format
  - **WEBM** - Web-optimized (VP8/VP9)
- **Max FPS** - Limit frame rate (e.g., 30, 60)
- **Max Size** - Limit resolution (e.g., 1920)
  - Format: single number for max dimension
- **Record Orientation** - Lock recording orientation

**Advanced:**
- **Time Limit** - Stop recording after N seconds
- **No Display** - Record without showing mirror window
  - Useful for background recording

**Tips:**
- Use MKV for highest quality and codec flexibility
- MP4 is most compatible for sharing
- Lower FPS reduces file size
- No Display mode is great for automation

### Camera Panel

Mirror device camera instead of screen.

**Camera Selection:**
- **Camera ID** - Specific camera identifier
  - Find IDs: `scrcpy --list-cameras`
- **Camera Facing** - front, back, or external
- **Camera Size** - Resolution (e.g., 1920x1080)
  - Find sizes: `scrcpy --list-camera-sizes`

**Performance:**
- **Camera FPS** - Frame rate (15, 30, 60)
  - Default: 30 FPS
- **Camera Aspect Ratio** - sensor, 16:9, 4:3, 1:1, or custom
  - Format: `16:9` or `1.777`
- **High Speed Mode** - Enable high-speed capture
  - Limited to specific resolutions

**Use Cases:**
- Document camera for presentations
- Security camera feed
- Remote camera access
- Content creation

### Display & Window Panel

Advanced display and rendering options.

**Window Position:**
- **Window X** - Horizontal position in pixels
- **Window Y** - Vertical position in pixels
- **Window Width** - Window width in pixels
- **Window Height** - Window height in pixels

**Display Configuration:**
- **Rotation** - Display rotation (0-3 = 0°, 90°, 180°, 270°)
- **Display ID** - Secondary display number
  - For devices with multiple screens
- **Display Buffer** - Buffer size in milliseconds
  - Default: 0 (no buffering)

**Rendering:**
- **Render Driver** - Graphics backend
  - Options: direct3d, opengl, opengles2, software
  - Usually auto-detected
- **Force ADB Forward** - Force ADB tunneling instead of reverse

### Input Control Panel

Configure keyboard and mouse behavior.

**Input Modes:**
- **No Control** - View only, disable all input
- **No Mouse Hover** - Disable hover events (reduces bandwidth)
- **Forward All Clicks** - Forward right/middle clicks to device
  - Default: only left click

**Keyboard Settings:**
- **Keyboard Mode** - Input method
  - **sdk** - Inject keystrokes (default)
  - **uhid** - Physical keyboard simulation
  - **aoa** - USB accessory mode
- **Legacy Paste** - Inject text character-by-character
  - Slower but more compatible
- **No Key Repeat** - Disable key repeat
- **Raw Key Events** - Send raw keycodes
- **Prefer Text** - Inject text when possible

**Mouse Settings:**
- **Mouse Mode** - Pointer behavior
  - **sdk** - Software pointer (default)
  - **uhid** - Physical mouse simulation
  - **aoa** - USB accessory mode
- **Mouse Bind** - Button shortcuts
  - Options: ++, +++, ++++ modifiers

**Use Cases:**
- Disable input for presentations
- UHID mode for better game compatibility
- AOA mode for physical input without screen

### Network Connection Panel

Wireless connection configuration.

**TCP/IP Settings:**
- **TCPIP Port** - Port number for wireless connection
  - Default: 5555
  - Range: 1024-65535
- **Select TCPIP** - Auto-select wireless devices only
- **No ADB Forward** - Use reverse connection instead

**SSH Tunnel:**
- **Tunnel Host** - SSH server address
- **Tunnel Port** - SSH port
  - Default: 22

**Remote Connection:**
Useful for connecting to devices over internet via SSH tunnel.

### Virtual Display Panel

Create virtual displays on device.

**Configuration:**
- **New Display** - Create new virtual display
- **Virtual Display ID** - Specific display identifier
- **Virtual Display Resolution** - Size (e.g., 1920x1080)
- **Virtual Display DPI** - Pixel density
  - Default: device default
- **Virtual Display Flags** - Advanced flags

**Behavior:**
- **No VD Destroy Content** - Keep apps on virtual display
- **No VD System Decorations** - Hide status/nav bars

**Use Cases:**
- Record screen without interrupting main display
- Create specific resolution for recording
- Multi-display testing

### Advanced/Developer Panel

Advanced options and developer features.

**Logging:**
- **Verbosity Level** - Log detail
  - verbose, debug, info (default), warn, error

**Behavior:**
- **No Cleanup** - Don't remove server binary on exit
- **No Downsize on Error** - Don't auto-reduce quality on errors

**V4L2 Options (Linux Only):**
- **V4L2 Sink** - Virtual camera device (e.g., /dev/video2)
  - Requires v4l2loopback module
- **V4L2 Buffer** - Buffering delay in milliseconds

**Use Cases:**
- Debugging scrcpy issues
- Using device as webcam (Linux)
- Development and testing

### OTG Mode Panel

Physical USB control without screen mirroring.

**Options:**
- **OTG Mode** - Enable OTG mode
- **HID Keyboard** - Simulate physical keyboard
- **HID Mouse** - Simulate physical mouse

**Requirements:**
- USB connection (wireless not supported)
- Android 11+ or custom ROM support
- No screen mirroring in OTG mode

**Use Cases:**
- Control device with broken screen
- Minimal latency input for gaming
- Automated testing with physical input

---

## Advanced Features

### Command Actions

Located at the top of the home page.

**Run Button** (▶️)
- Executes the generated command
- Opens new terminal window (configurable)
- Starts scrcpy process

**Favorite Button** (⭐)
- Saves current command to Favorites
- Includes all panel configurations
- Access saved commands in Favorites page

**Download Button** (📥)
- Exports command as .bat file (Windows) or .sh script
- Auto-generates intelligent filename
- Saves to configured downloads directory

**Clear All Button** (🧹)
- Resets all panels to default values
- Clears all input fields
- Does not clear device selection

**Wireless Connect** (📡)
- Sets up wireless ADB connection
- Requires initial USB connection
- Uses port specified in field

### Favorites Management

**Saving Favorites:**
1. Configure your desired settings
2. Click Favorite button
3. Command saved with timestamp

**Using Favorites:**
1. Navigate to Favorites page (⭐ icon)
2. View all saved commands
3. Click any command to:
   - Copy to clipboard
   - Download as script
   - Delete from favorites
   - Run directly

**Command History:**
- Last executed command always saved
- View execution count for each command
- Sort by most used or most recent

### Running Instances

Monitor and manage all active scrcpy processes.

**Information Displayed:**
- Process ID (PID)
- Device serial/IP
- Window title
- Connection type (USB/Wireless)
- Uptime (Windows only)
- Memory usage (Windows only)

**Actions:**
- **Kill** - Terminate single process
- **Kill All** - Terminate all scrcpy processes
- **Reconnect** - Re-execute same command
- **Expand/Collapse** - Toggle detailed view

**Auto-Refresh:**
- Updates every 5 seconds automatically
- Manual refresh button available
- Shows processes from all sources (not just app-started)

### Panel Customization

Customize the layout of command panels.

**Access Settings:**
1. Go to Settings page (⚙️ icon)
2. Scroll to "Panel Customization" section

**Available Options:**
- **Reorder Panels** - Drag and drop to rearrange
- **Hide Panels** - Toggle visibility
- **Full Width** - Make panel span full width
- **Reset Layout** - Restore default arrangement

**Tips:**
- Put frequently-used panels at top
- Hide panels you never use
- Use full-width for panels with many options
- Layout persists across app restarts

---

## Tips & Best Practices

### Performance Optimization

**Reduce Latency:**
- Use USB connection instead of wireless
- Lower video bit rate (4M-6M)
- Reduce max size (1280 or 1920)
- Disable audio if not needed
- Use H.264 codec (best compatibility)

**Improve Quality:**
- Increase video bit rate (12M-16M)
- Use H.265 codec (if device supports)
- Use 2.4GHz WiFi for wireless (longer range)
- Disable unnecessary background apps on device

**Battery Saving:**
- Turn screen off (`--turn-screen-off`)
- Reduce bit rate
- Use wired connection
- Disable audio forwarding

### Recording Best Practices

**High Quality Recordings:**
```
Format: MKV
Codec: H.265 (if supported) or H.264
Bit Rate: 16M
FPS: 60
Audio: Opus 192K
```

**Balanced Quality/Size:**
```
Format: MP4
Codec: H.264
Bit Rate: 8M
FPS: 30
Audio: AAC 128K
```

**Small File Size:**
```
Format: MP4
Codec: H.264
Bit Rate: 4M
Max Size: 1280
FPS: 30
Audio: AAC 64K
```

### Wireless Connection Tips

1. **Static IP Recommended**
   - Assign static IP to device in router
   - Connection persists across restarts

2. **Router Settings**
   - Disable AP isolation
   - Ensure devices can communicate
   - Port 5555 not blocked by firewall

3. **Reconnection**
   - After device reboot, reconnect via USB first
   - Re-run wireless connection setup
   - Or manually: `adb connect <IP>:5555`

### Common Workflows

**Daily Usage (Quick Mirror):**
1. Select device → Run
2. Done!

**High-Quality Recording:**
1. Select device
2. Recording panel → Configure settings
3. General panel → Set video bit rate
4. Audio panel → Set audio quality
5. Favorite for reuse
6. Click Run

**Wireless Gaming Setup:**
1. Connect wirelessly
2. General panel → Lower bit rate (4M)
3. Input panel → Set keyboard/mouse mode to UHID
4. Display panel → Set render driver
5. Run

**Presentation Mode:**
1. General panel → Borderless + Always on top
2. Input panel → No control (view only)
3. Display panel → Set window position/size
4. Run

---

## Keyboard Shortcuts

### In Scrcpy Window (Default scrcpy shortcuts)

**Display:**
- `Ctrl+F` or `Cmd+F` - Fullscreen toggle
- `Ctrl+X` or `Cmd+X` - Resize to 1:1 (pixel-perfect)
- `Ctrl+G` or `Cmd+G` - Resize to fit window
- `Ctrl+R` or `Cmd+R` - Rotate display 90° clockwise
- `Ctrl+↑/↓` or `Cmd+↑/↓` - Rotate display

**Power:**
- `Ctrl+P` or `Cmd+P` - Power button (screen on/off)
- `Ctrl+O` or `Cmd+O` - Turn device screen off
- `Ctrl+Shift+O` or `Cmd+Shift+O` - Turn device screen on

**Navigation:**
- `Ctrl+H` or `Cmd+H` - Home button
- `Ctrl+B` or `Cmd+B` - Back button
- `Ctrl+S` or `Cmd+S` - App switch (recent apps)
- `Ctrl+M` or `Cmd+M` - Menu button
- `Ctrl+N` or `Cmd+N` - Expand notification panel

**Volume:**
- `Ctrl+↑` or `Cmd+↑` - Volume up
- `Ctrl+↓` or `Cmd+↓` - Volume down

**Clipboard:**
- `Ctrl+C` or `Cmd+C` - Copy device clipboard to computer
- `Ctrl+V` or `Cmd+V` - Paste computer clipboard to device
- `Ctrl+Shift+V` or `Cmd+Shift+V` - Inject computer clipboard as text

**Other:**
- `Ctrl+I` or `Cmd+I` - Toggle FPS counter
- `Ctrl+W` or `Cmd+W` - Close window (stop mirroring)

### In Application

*(Custom shortcuts can be added in future versions)*

---

## Getting Help

### In-App Resources

Visit the **Resources** page (📁 icon) for:
- Official scrcpy documentation links
- ADB command reference
- Frequently asked questions
- Useful scrcpy commands
- Community links

### External Support

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Community help and discussions
- **scrcpy Documentation** - Official scrcpy guide
- **Android Developers** - ADB and debugging guides

### Diagnostic Information

When reporting issues, include:
- Operating system and version
- scrcpy version (`scrcpy --version`)
- ADB version (`adb version`)
- Device model and Android version
- Error messages or screenshots
- Steps to reproduce the issue

---

**Happy Mirroring! 📱 → 💻**

For more information, see:
- [README.md](README.md) - Project overview
- [API_REFERENCE.md](API_REFERENCE.md) - Developer documentation
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
