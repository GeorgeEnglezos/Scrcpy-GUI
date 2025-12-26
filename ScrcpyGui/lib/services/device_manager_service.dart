/// Device Manager Service
///
/// Manages Android device detection, connection monitoring, and device information caching.
/// Provides automatic polling for device changes and maintains a global device registry.
///
/// Key Responsibilities:
/// - Auto-detect connected devices via ADB (polls every 2 seconds)
/// - Load and cache device-specific data (packages, codecs)
/// - Track selected device for UI binding
/// - Broadcast device connection/disconnection events
/// - Manage both USB and wireless device connections
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/phone_info_model.dart';
import '../services/terminal_service.dart';

/// Service for managing Android device connections and information
///
/// This service uses Provider's ChangeNotifier to broadcast state changes
/// to the UI when devices are connected, disconnected, or selected.
///
/// The service starts automatic polling in [initialize] and maintains
/// a global registry of device information in [devicesInfo].
class DeviceManagerService extends ChangeNotifier {
  /// Global device information registry
  ///
  /// Maps device ID to cached device information including:
  /// - Installed packages (user apps)
  /// - Available video codecs/encoders
  /// - Available audio codecs/encoders
  ///
  /// Static to allow access without service instance reference.
  static final Map<String, PhoneInfoModel> devicesInfo = {};

  /// Polling timer for device detection (runs every 2 seconds)
  Timer? _pollingTimer;

  /// Last known list of connected devices (for change detection)
  List<String> _lastConnectedDevices = [];

  /// Internal selected device ID (null if none selected)
  String? _selectedDevice;

  /// Value notifier for selected device changes
  ///
  /// Allows widgets to listen to device selection changes without
  /// rebuilding the entire widget tree. Used in conjunction with
  /// ChangeNotifier for flexible state management.
  final ValueNotifier<String?> selectedDeviceNotifier = ValueNotifier(null);

  /// Gets the currently selected device ID
  String? get selectedDevice => _selectedDevice;

  /// Sets the currently selected device and broadcasts the change
  ///
  /// Updates both the internal state and the [selectedDeviceNotifier].
  /// Triggers [notifyListeners] to update Provider consumers.
  set selectedDevice(String? value) {
    if (_selectedDevice != value) {
      _selectedDevice = value;
      selectedDeviceNotifier.value = value; // Broadcast the change
      notifyListeners();
    }
  }

  /// Initialize the device manager service
  ///
  /// Sets up automatic device polling and loads information for any
  /// currently connected devices.
  ///
  /// Call this method once during app startup (typically in main()).
  ///
  /// Workflow:
  /// 1. Loads data for all currently connected devices
  /// 2. Starts a periodic timer (2-second interval) to check for device changes
  ///
  /// Example:
  /// ```dart
  /// final deviceManager = DeviceManagerService();
  /// await deviceManager.initialize();
  /// ```
  Future<void> initialize() async {
    await _loadDevicesOnce();

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _checkDeviceChanges();
    });
  }

  /// Load data for currently connected devices at boot
  ///
  /// Called once during [initialize] to populate device information
  /// for all devices connected at app startup.
  ///
  /// If devices are found and no device is selected, automatically
  /// selects the first device.
  Future<void> _loadDevicesOnce() async {
    final devices = await TerminalService.adbDevices();

    for (var deviceId in devices) {
      await _loadDeviceData(deviceId);
    }

    _lastConnectedDevices = devices;

    // Set selectedDevice if any device is connected
    if (devices.isNotEmpty && selectedDevice == null) {
      selectedDevice = devices.first;
    }
  }

  /// Check for newly connected or removed devices
  ///
  /// Called periodically by the polling timer to detect device changes.
  ///
  /// New device workflow:
  /// 1. Loads device data (packages, codecs)
  /// 2. Logs connection in debug output
  /// 3. Auto-selects device if none currently selected
  ///
  /// Removed device workflow:
  /// 1. Removes device from [devicesInfo] cache
  /// 2. If removed device was selected, switches to first available device or null
  ///
  /// Always calls [notifyListeners] at the end to update UI.
  Future<void> _checkDeviceChanges() async {
    final devices = await TerminalService.adbDevices();

    // Detect new devices
    final newDevices = devices.where((d) => !_lastConnectedDevices.contains(d));
    for (var deviceId in newDevices) {
      await _loadDeviceData(deviceId);
      debugPrint('New device connected: $deviceId');

      // Set as selectedDevice if none was selected
      selectedDevice ??= deviceId;
    }

    // Detect removed devices
    final removedDevices = _lastConnectedDevices.where(
      (d) => !devices.contains(d),
    );
    for (var deviceId in removedDevices) {
      devicesInfo.remove(deviceId);

      // If the removed device was selected, clear or pick first available
      if (selectedDevice == deviceId) {
        selectedDevice = devices.isNotEmpty ? devices.first : null;
      }
    }

    _lastConnectedDevices = devices;
    notifyListeners();
  }

  /// Load packages, audio, video codecs for a specific device
  ///
  /// Retrieves and caches comprehensive device information:
  /// - User-installed packages (via ADB)
  /// - Package display labels (app names)
  /// - Video codecs and encoders (via scrcpy)
  /// - Audio codecs and encoders (via scrcpy)
  ///
  /// [deviceId] The device ID to load data for
  ///
  /// Stores the result in [devicesInfo] and calls [notifyListeners].
  /// Logs completion timestamp in debug mode.
  Future<void> _loadDeviceData(String deviceId) async {
    final packages = await TerminalService.listPackages(deviceId: deviceId);
    final packageLabels = await TerminalService.listPackagesWithLabels(
      deviceId: deviceId,
    );
    final rawEncoders = await TerminalService.loadScrcpyEncoders(
      deviceId: deviceId,
    );

    final videoCodecsEncoders = TerminalService.parseVideoEncoders(rawEncoders);
    final audioCodecsEncoders = TerminalService.parseAudioEncoders(rawEncoders);

    devicesInfo[deviceId] = PhoneInfoModel(
      deviceId: deviceId,
      packages: packages,
      packageLabels: packageLabels,
      audioCodecs: audioCodecsEncoders,
      videoCodecs: videoCodecsEncoders,
    );

    notifyListeners();

    debugPrint(
      '[${DateTime.now().toIso8601String()}] Loaded device info: ${devicesInfo[deviceId]}',
    );
  }

  /// Get cached device information
  ///
  /// [deviceId] The device ID to retrieve info for
  ///
  /// Returns the cached [PhoneInfoModel] or null if device not found or not loaded
  ///
  /// Example:
  /// ```dart
  /// final info = deviceManager.getDeviceInfo('abc123');
  /// if (info != null) {
  ///   print('Packages: ${info.packages.length}');
  /// }
  /// ```
  PhoneInfoModel? getDeviceInfo(String deviceId) => devicesInfo[deviceId];

  /// Dispose resources when service is destroyed
  ///
  /// Cancels the polling timer and disposes the value notifier.
  /// Called automatically by Provider when the app is closed.
  @override
  void dispose() {
    _pollingTimer?.cancel();
    selectedDeviceNotifier.dispose();
    super.dispose();
  }
}
