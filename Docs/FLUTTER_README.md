# Scrcpy GUI - Flutter Port

Modern Flutter-based GUI application for scrcpy (Android screen mirroring and control).

## Overview

This is a complete rewrite of the original .NET MAUI Scrcpy GUI in Flutter, providing a cross-platform graphical interface for scrcpy with enhanced features and improved performance.

## Features

- Visual command builder for all scrcpy options
- Automatic device detection (USB and wireless)
- Real-time command generation with syntax highlighting
- Process monitoring for running scrcpy instances
- Favorites system for saved configurations
- Wireless connection setup wizard
- Cross-platform support (Windows, macOS, Linux)

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- scrcpy installed and accessible from terminal
- ADB (Android Debug Bridge)
- USB debugging enabled on Android device

### Installation

1. Clone the repository
2. Navigate to the ScrcpyGui folder
3. Run `flutter pub get`
4. Run `flutter run` for development
5. Run `flutter build [platform]` for release builds

### Quick Start

1. Connect your Android device via USB
2. Accept USB debugging prompt on device
3. Launch the application
4. Select your device from dropdown
5. Configure options using the GUI panels
6. Click Run to start mirroring

## Documentation

Complete documentation available in the `/Docs` folder:

- [API Reference](../Docs/API_REFERENCE.md) - Developer API documentation
- [Changelog](../Docs/CHANGELOG.md) - Version history and changes
- [Documentation](../Docs/DOCUMENTATION.md) - Documentation overview
- [Features](../Docs/FEATURES.md) - Complete feature list
- [Troubleshooting](../Docs/TROUBLESHOOTING.md) - Common issues and solutions
- [User Guide](../Docs/USER_GUIDE.md) - Comprehensive usage guide

## Development

Built with Flutter using:
- Provider pattern for state management
- Service-based architecture
- Modular panel system
- Platform-specific implementations for terminal integration

## License

See the root LICENSE file for details.

## Support

For issues, feature requests, or contributions, please visit the GitHub repository.
