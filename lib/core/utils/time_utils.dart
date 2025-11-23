class TimeUtils {
  /// Parse timestamp string (MM:SS:mmm) to Duration
  static Duration parseTimestamp(String timestamp) {
    final parts = timestamp.split(':');
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    int milliseconds = 0;

    if (parts.length == 3) {
      // MM:SS:mmm
      minutes = int.tryParse(parts[0]) ?? 0;
      seconds = int.tryParse(parts[1]) ?? 0;
      milliseconds = int.tryParse(parts[2]) ?? 0;
    } else if (parts.length == 2) {
      // MM:SS
      minutes = int.tryParse(parts[0]) ?? 0;
      seconds = int.tryParse(parts[1]) ?? 0;
    } else if (parts.length == 4) {
      // HH:MM:SS:mmm
      hours = int.tryParse(parts[0]) ?? 0;
      minutes = int.tryParse(parts[1]) ?? 0;
      seconds = int.tryParse(parts[2]) ?? 0;
      milliseconds = int.tryParse(parts[3]) ?? 0;
    }

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  /// Check if timestamp is between start and end
  static bool isBetween(Duration current, String start, String end) {
    final startDuration = parseTimestamp(start);
    final endDuration = parseTimestamp(end);
    return current >= startDuration && current <= endDuration;
  }
}
