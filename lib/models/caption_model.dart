class WordModel {
  final String word;
  final String start;
  final String end;

  WordModel({
    required this.word,
    required this.start,
    required this.end,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      word: json['word'] as String,
      start: json['start'] as String,
      end: json['end'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'start': start,
      'end': end,
    };
  }
}

class CaptionModel {
  final String text;
  final String start;
  final String end;
  final List<WordModel> words;

  CaptionModel({
    required this.text,
    required this.start,
    required this.end,
    required this.words,
  });

  factory CaptionModel.fromJson(Map<String, dynamic> json) {
    return CaptionModel(
      text: json['text'] as String,
      start: json['start'] as String,
      end: json['end'] as String,
      words: (json['words'] as List<dynamic>)
          .map((word) => WordModel.fromJson(word as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'start': start,
      'end': end,
      'words': words.map((word) => word.toJson()).toList(),
    };
  }
}
