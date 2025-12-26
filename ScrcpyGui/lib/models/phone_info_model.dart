class PhoneInfoModel {
  final String deviceId;
  List<String> packages; // package names
  Map<String, String> packageLabels; // package name -> display label
  List<String> audioCodecs; // audio codecs / encoders
  List<String> videoCodecs; // video codecs / encoders

  PhoneInfoModel({
    required this.deviceId,
    this.packages = const [],
    this.packageLabels = const {},
    this.audioCodecs = const [],
    this.videoCodecs = const [],
  });

  @override
  String toString() {
    return 'PhoneInfo(deviceId: $deviceId, packages: ${packages.length}, '
        'audioCodecs: ${audioCodecs.length}, videoCodecs: ${videoCodecs.length})';
  }
}
