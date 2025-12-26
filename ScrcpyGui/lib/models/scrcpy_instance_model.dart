enum ConnectionType { usb, wireless, unknown }

class ScrcpyInstance {
  final int pid;
  final String command;
  final String deviceId;
  final String? fullCommand;
  final String? windowTitle;
  final ConnectionType connectionType;
  final DateTime? startTime;
  final double? cpuUsage;
  final double? memoryUsage; // In MB

  ScrcpyInstance({
    required this.pid,
    required this.command,
    required this.deviceId,
    this.fullCommand,
    this.windowTitle,
    this.connectionType = ConnectionType.unknown,
    this.startTime,
    this.cpuUsage,
    this.memoryUsage,
  });

  ScrcpyInstance copyWith({
    int? pid,
    String? command,
    String? deviceId,
    String? fullCommand,
    String? windowTitle,
    ConnectionType? connectionType,
    DateTime? startTime,
    double? cpuUsage,
    double? memoryUsage,
  }) {
    return ScrcpyInstance(
      pid: pid ?? this.pid,
      command: command ?? this.command,
      deviceId: deviceId ?? this.deviceId,
      fullCommand: fullCommand ?? this.fullCommand,
      windowTitle: windowTitle ?? this.windowTitle,
      connectionType: connectionType ?? this.connectionType,
      startTime: startTime ?? this.startTime,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
    );
  }

  String get uptimeString {
    if (startTime == null) return 'Unknown';
    final duration = DateTime.now().difference(startTime!);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String get connectionTypeString {
    switch (connectionType) {
      case ConnectionType.usb:
        return 'USB';
      case ConnectionType.wireless:
        return 'Wireless';
      case ConnectionType.unknown:
        return 'Unknown';
    }
  }
}
