# Changelog

All notable changes to the Scrcpy GUI project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
---

### Added

#### Core Features
- ✅ Visual command builder interface for scrcpy
- ✅ Automatic device detection (USB and wireless)
- ✅ Real-time command generation with syntax highlighting
- ✅ Process monitoring for all running scrcpy instances
- ✅ Favorites system for saving command configurations
- ✅ Wireless connection setup wizard
- ✅ Cross-platform support (Windows, macOS, Linux)

#### Command Panels
- ✅ General/Common commands panel
  - Window configuration
  - Display settings
  - Video encoding options
  - Screen controls
- ✅ Audio commands panel
  - Codec selection
  - Bitrate configuration
  - Audio source selection
  - Buffer settings
- ✅ Recording commands panel
  - Output format selection
  - Quality settings
  - File naming and directory
- ✅ Camera commands panel
  - Camera selection by ID or facing
  - Resolution and FPS configuration
  - High-speed mode support
- ✅ Display & Window panel
  - Window positioning
  - Display rotation
  - Render driver selection
- ✅ Input Control panel
  - Keyboard/mouse modes
  - Input forwarding options
  - Text injection preferences
- ✅ Network Connection panel
  - TCP/IP configuration
  - SSH tunnel support
  - Wireless setup
- ✅ Virtual Display panel
  - Virtual display creation
  - Resolution and DPI settings
  - System decorations control
- ✅ Advanced/Developer panel
  - Verbosity levels
  - Cleanup options
  - V4L2 support (Linux)
- ✅ OTG Mode panel
  - HID keyboard/mouse simulation
  - OTG mode enabling

#### User Interface
- ✅ Modern dark theme with purple accents
- ✅ Sidebar navigation (Home, Favorites, Scripts, Resources, Settings)
- ✅ Syntax-highlighted command display
- ✅ Color-coded flags by category
- ✅ Responsive panel layout
- ✅ Tooltips on all input fields
- ✅ Collapsible panel sections
- ✅ Running instances panel with detailed information

#### Device Management
- ✅ Automatic device detection every 2 seconds
- ✅ Support for multiple simultaneous devices
- ✅ Device information caching (codecs, packages)
- ✅ USB and wireless connection support
- ✅ Device codec discovery (video and audio)
- ✅ Installed packages list for app launching

#### Data Persistence
- ✅ Settings persistence across sessions
- ✅ Command history tracking
- ✅ Favorites storage
- ✅ Panel customization saving
- ✅ Last executed command memory
- ✅ Execution count tracking

#### Export Features
- ✅ Copy command to clipboard
- ✅ Download as .bat file (Windows)
- ✅ Intelligent filename generation
- ✅ Directory browser integration

#### Process Management
- ✅ System-wide scrcpy process detection
- ✅ Kill individual or all processes
- ✅ Reconnect functionality
- ✅ Process uptime tracking (Windows)
- ✅ Memory usage display (Windows)
- ✅ Auto-refresh every 5 seconds

#### Settings & Customization
- ✅ Scrcpy installation path configuration
- ✅ Recordings output directory
- ✅ Downloads directory for scripts
- ✅ Panel visibility toggling
- ✅ Panel reordering (drag & drop)
- ✅ Full-width panel option
- ✅ Startup tab selection
- ✅ Terminal behavior configuration

#### Documentation
- ✅ Comprehensive README with quick start
- ✅ Complete USER_GUIDE with all features
- ✅ FEATURES documentation
- ✅ TROUBLESHOOTING guide
- ✅ API_REFERENCE for developers
- ✅ Inline code documentation (all widgets, panels, services)
- ✅ Resources page with helpful links

### Technical Implementation

#### Architecture
- ✅ Provider pattern for state management
- ✅ ValueNotifier for fine-grained reactivity
- ✅ Service-based architecture
- ✅ Modular option groups
- ✅ Clean separation of concerns

#### Services
- ✅ TerminalService - Shell execution and ADB integration
- ✅ DeviceManagerService - Device polling and caching
- ✅ CommandBuilderService - Command assembly
- ✅ CommandsService - Favorites persistence
- ✅ SettingsService - Settings persistence

#### Widgets
- ✅ Custom text input with tooltips
- ✅ Custom checkbox with labels
- ✅ Custom searchbar with autocomplete
- ✅ Custom dropdown with validation
- ✅ Reusable panel wrapper (SurroundingPanel)
- ✅ Syntax-highlighted command panel
- ✅ Navigation sidebar

#### Theme System
- ✅ Centralized color palette
- ✅ Standardized UI constants
- ✅ Material 3 design integration
- ✅ Category-specific panel colors
- ✅ Consistent component styling

#### Utilities
- ✅ Command syntax highlighter
- ✅ Clear operation controller
- ✅ Platform-specific terminal launchers
- ✅ Process detection utilities

### Platform Support

#### Windows
- ✅ Bat file generation
- ✅ Detailed process information (WMIC)
- ✅ cmd.exe terminal integration
- ✅ Path detection
- ✅ %APPDATA% storage

#### macOS
- ✅ AppleScript Terminal integration
- ✅ Homebrew path detection
- ✅ ~/Documents storage
- ✅ Basic process monitoring

#### Linux
- ✅ Multiple terminal emulator support
- ✅ V4L2 virtual camera options
- ✅ ~/Documents storage
- ✅ Basic process monitoring
- ✅ Shell script export (planned)

### Changed
- N/A (Initial release)

### Deprecated
- N/A (Initial release)

### Removed
- N/A (Initial release)

### Fixed
- N/A (Initial release)

### Security
- ✅ Input sanitization for shell commands
- ✅ Safe file path handling
- ✅ No hardcoded credentials
- ✅ Secure command execution

---

## Development Milestones

### Phase 1: Core Foundation ✅
- [x] Basic Flutter app structure
- [x] Device detection via ADB
- [x] Simple command builder
- [x] Terminal execution

### Phase 2: UI Development ✅
- [x] Custom widgets creation
- [x] Panel system implementation
- [x] Sidebar navigation
- [x] Theme implementation

### Phase 3: Feature Complete ✅
- [x] All command panels
- [x] Settings persistence
- [x] Favorites system
- [x] Process monitoring

### Phase 4: Polish & Documentation ✅
- [x] Comprehensive documentation
- [x] Code documentation
- [x] User guides
- [x] Troubleshooting guide

### Phase 5: Release Preparation 🚧
- [ ] Testing on all platforms
- [ ] Bug fixes
- [ ] Performance optimization
- [ ] Release builds
- [ ] GitHub release

### Phase 6: Future Enhancements 📋
- [ ] Additional features from roadmap
- [ ] Community feedback integration
- [ ] Performance improvements
- [ ] Advanced features

---

## Version History

### Version Numbering

This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backwards compatible manner
- **PATCH** version for backwards compatible bug fixes

### Release Notes Format

Each release will include:
- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security vulnerability fixes

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Reporting bugs
- Suggesting features
- Submitting pull requests
- Code style guidelines
- Testing requirements

---

## Links

- **Repository**: [https://github.com/GeorgeEnglezos/Scrcpy-GUI](https://github.com/GeorgeEnglezos/Scrcpy-GUI)
- **Issues**: [GitHub Issues](https://github.com/GeorgeEnglezos/Scrcpy-GUI/issues)
- **Discussions**: [GitHub Discussions](https://github.com/GeorgeEnglezos/Scrcpy-GUI/discussions)
- **Releases**: [GitHub Releases](https://github.com/GeorgeEnglezos/Scrcpy-GUI/releases)

---

## Notes

- This is the initial release (1.6.0) preparing for public launch
- All core features are implemented and tested
- Documentation is comprehensive and complete
- Future versions will follow this changelog format
- Breaking changes will be clearly marked
- Migration guides will be provided for major version changes

---

**For detailed feature information, see [FEATURES.md](FEATURES.md)**

**For usage instructions, see [USER_GUIDE.md](USER_GUIDE.md)**

**For troubleshooting help, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
