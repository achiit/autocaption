class VoiceoverSegment {
  final String id;
  final String filePath;
  final Duration videoStart; // Where it starts in the video timeline
  Duration sourceStart; // Start trim in audio file
  Duration sourceEnd; // End trim in audio file

  VoiceoverSegment({
    required this.id,
    required this.filePath,
    required this.videoStart,
    required this.sourceStart,
    required this.sourceEnd,
  });

  Duration get duration => sourceEnd - sourceStart;
  Duration get videoEnd => videoStart + duration;

  VoiceoverSegment copyWith({
    String? id,
    String? filePath,
    Duration? videoStart,
    Duration? sourceStart,
    Duration? sourceEnd,
  }) {
    return VoiceoverSegment(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      videoStart: videoStart ?? this.videoStart,
      sourceStart: sourceStart ?? this.sourceStart,
      sourceEnd: sourceEnd ?? this.sourceEnd,
    );
  }
}
