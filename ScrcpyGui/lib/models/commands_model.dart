import 'dart:convert';

class CommandsData {
  String lastCommand;
  List<String> favorites;
  Map<String, int> mostUsed;

  /// Default showcase commands that appear on first launch
  static List<String> get defaultFavorites => [
    'scrcpy --new-display=1920x1080/420 --start-app=com.magneticchen.daijishou --turn-screen-off --stay-awake',
    'scrcpy --new-display=1920x1080/420 --start-app=org.videolan.vlc --turn-screen-off --stay-awake',
    'scrcpy --new-display=1920x1080/420 --start-app=com.retroarch --turn-screen-off --stay-awake',
    'scrcpy --new-display=1920x1080/420 --start-app=com.digdroid.alman.dig --turn-screen-off --stay-awake',
    'scrcpy --record=gameplay.mp4 --no-audio --turn-screen-off --video-codec=h265 --max-fps=60',
    'scrcpy --turn-screen-off --no-audio',
  ];

  CommandsData({
    this.lastCommand = '',
    List<String>? favorites,
    Map<String, int>? mostUsed,
  }) : favorites = favorites ?? [],
       mostUsed = mostUsed ?? {};

  Map<String, dynamic> toJson() {
    return {
      'last-command': lastCommand,
      'favorites': favorites,
      'most-used': mostUsed.entries
          .map((e) => {'command': e.key, 'count': e.value})
          .toList(),
    };
  }

  factory CommandsData.fromJson(Map<String, dynamic> json) {
    final mostUsedList = json['most-used'] as List<dynamic>?;
    final mostUsedMap = <String, int>{};

    if (mostUsedList != null) {
      for (var item in mostUsedList) {
        mostUsedMap[item['command'] as String] = item['count'] as int;
      }
    }

    return CommandsData(
      lastCommand: json['last-command'] ?? '',
      favorites: List<String>.from(json['favorites'] ?? []),
      mostUsed: mostUsedMap,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory CommandsData.fromJsonString(String jsonString) {
    return CommandsData.fromJson(jsonDecode(jsonString));
  }

  /// Get top N most used commands excluding favorites
  List<String> getTopMostUsed({int limit = 10}) {
    final entries = mostUsed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .where((entry) => !favorites.contains(entry.key))
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
}
