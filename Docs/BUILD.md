# Building Scrcpy GUI from Source

This guide covers building the Flutter version of Scrcpy GUI for all supported platforms.

---

## Prerequisites

### Required Software

1. **Flutter SDK** (stable channel)
   - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Add Flutter to your PATH
   - Verify installation: `flutter doctor`

2. **Git**
   - Required for cloning the repository
   - Download from [git-scm.com](https://git-scm.com/)

3. **scrcpy** (for runtime)
   - Install from [official repository](https://github.com/Genymobile/scrcpy#get-the-app)
   - Must be accessible from command line

### Platform-Specific Requirements

#### Windows

- **Visual Studio 2022** with "Desktop development with C++" workload
- **Windows 10 SDK** (version 10.0.17763.0 or later)
- Alternatively, use **Visual Studio Build Tools 2022**

#### macOS

- **Xcode** (latest stable version)
- **Xcode Command Line Tools**: `xcode-select --install`
- **CocoaPods**: `sudo gem install cocoapods`

#### Linux

- **Build essentials**: `sudo apt-get install build-essential`
- **GTK+ 3.0 development libraries**: `sudo apt-get install libgtk-3-dev`
- **Ninja build system**: `sudo apt-get install ninja-build`
- **pkg-config**: `sudo apt-get install pkg-config`

For other Linux distributions, install equivalent packages using your package manager.

---

## Getting the Source Code

```bash
# Clone the repository
git clone https://github.com/GeorgeEnglezos/Scrcpy-GUI.git

# Navigate to the Flutter project directory
cd Scrcpy-GUI/ScrcpyGui
```

---

## Building

### 1. Install Dependencies

```bash
# Install all Flutter dependencies
flutter pub get
```

### 2. Verify Setup

```bash
# Check for any issues
flutter doctor -v

# Ensure your platform is ready
flutter doctor --android-licenses  # If building for Android
```

### 3. Build for Your Platform

#### Windows

```bash
# Development build
flutter run -d windows

# Release build
flutter build windows --release
```

Output location: `build/windows/x64/runner/Release/`

The release folder contains:
- `scrcpy_gui_prod.exe` - Main executable
- `flutter_windows.dll` - Flutter engine
- `data/` - Application resources

**Distribution**: Zip the entire `Release` folder for distribution.

#### macOS

```bash
# Development build
flutter run -d macos

# Release build
flutter build macos --release
```

Output location: `build/macos/Build/Products/Release/scrcpy_gui_prod.app`

**Code Signing** (for distribution):
```bash
# Ad-hoc signing (for local use)
codesign --force --deep --sign - build/macos/Build/Products/Release/scrcpy_gui_prod.app

# Developer ID signing (for distribution)
codesign --force --deep --sign "Developer ID Application: Your Name" build/macos/Build/Products/Release/scrcpy_gui_prod.app
```

**Create DMG** (optional):
```bash
# Install create-dmg
brew install create-dmg

# Create DMG
create-dmg \
  --volname "Scrcpy GUI" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 450 185 \
  "ScrcpyGUI.dmg" \
  "build/macos/Build/Products/Release/scrcpy_gui_prod.app"
```

#### Linux

```bash
# Development build
flutter run -d linux

# Release build
flutter build linux --release
```

Output location: `build/linux/x64/release/bundle/`

The bundle folder contains:
- `scrcpy_gui_prod` - Main executable
- `lib/` - Shared libraries
- `data/` - Application resources

**Distribution**: Zip or tar the entire `bundle` folder.

**Create Desktop Entry** (optional):
```bash
# Create .desktop file
cat > ~/.local/share/applications/scrcpy-gui.desktop << EOF
[Desktop Entry]
Name=Scrcpy GUI
Comment=GUI for scrcpy Android mirroring
Exec=/path/to/scrcpy_gui_prod
Icon=/path/to/icon.png
Terminal=false
Type=Application
Categories=Utility;
EOF
```

---

## Development Builds

### Hot Reload Development

```bash
# Run with hot reload
flutter run

# Select your platform when prompted
# Press 'r' to hot reload
# Press 'R' to hot restart
# Press 'q' to quit
```

### Debug Mode

```bash
# Build debug version
flutter build windows --debug  # or macos, linux

# Run with verbose logging
flutter run -v
```

---

## Build Configurations

### Release Optimizations

Release builds include:
- Code optimization
- Minification
- Tree shaking (removes unused code)
- No debugging symbols

### Profile Builds

For performance testing:

```bash
# Build profile version
flutter build windows --profile

# Run in profile mode
flutter run --profile
```

Profile builds include:
- Performance monitoring
- Some debugging capabilities
- Optimized code

---

## Troubleshooting

### Common Issues

**"Flutter SDK not found"**
- Ensure Flutter is in your PATH
- Run `flutter doctor` to verify

**"Visual Studio not found" (Windows)**
- Install Visual Studio 2022 with C++ Desktop Development workload
- Or install Visual Studio Build Tools 2022

**"Xcode not found" (macOS)**
- Install Xcode from App Store
- Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

**"GTK headers not found" (Linux)**
- Install development libraries: `sudo apt-get install libgtk-3-dev`

**Build fails with "pub get failed"**
- Delete `pubspec.lock`
- Delete `.dart_tool/` directory
- Run `flutter clean`
- Run `flutter pub get` again

**App crashes on startup**
- Ensure scrcpy is installed and in PATH
- Check that ADB is accessible
- Verify all dependencies with `flutter doctor`

### Clean Build

If encountering persistent issues:

```bash
# Clean build artifacts
flutter clean

# Re-download dependencies
flutter pub get

# Rebuild
flutter build windows --release  # or your platform
```

---

## Platform-Specific Notes

### Windows

- Built executable requires Visual C++ Runtime
- Most Windows 10/11 systems have this pre-installed
- If needed, include `vc_redist.x64.exe` with distribution

### macOS

- Apps built on Apple Silicon can run on Intel Macs (Rosetta 2)
- Apps built on Intel Macs cannot run on Apple Silicon
- For universal builds, build on Apple Silicon

### Linux

- Different distributions may require different dependencies
- Test on multiple distributions if possible
- Consider using AppImage or Flatpak for broader compatibility

---

## Continuous Integration

The project uses GitHub Actions for automated builds. See [`.github/workflows/build.yml`](../.github/workflows/build.yml) for the CI/CD configuration.

Builds are triggered on:
- Push to main branch
- Pull requests
- Version tags (creates releases)

---

## Version Management

Update version numbers in:
- `ScrcpyGui/pubspec.yaml` - `version` field
- Update `CHANGELOG.md` with changes

Version format: `MAJOR.MINOR.PATCH+BUILD`

Example: `1.6.0+1`

---

## Next Steps

After building:
1. Test the application thoroughly
2. Verify all features work on your platform
3. Check that scrcpy commands execute correctly
4. Test with multiple Android devices if possible

For development guidelines and architecture information, see:
- [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) (if applicable to Flutter version)
- [API_REFERENCE.md](API_REFERENCE.md)

---

## Getting Help

- **Build Issues**: Check [GitHub Issues](https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues)
- **Flutter Problems**: See [Flutter documentation](https://flutter.dev/docs)
- **Platform Tools**: Refer to platform-specific documentation (Visual Studio, Xcode, etc.)
