import '../models/caption_model.dart';
import '../core/utils/time_utils.dart';

class AssSubtitleGeneratorService {
  /// Generate ASS content from captions
  String generateAssContent({
    required List<CaptionModel> captions,
    required String fontName,
    required String template,
  }) {
    final buffer = StringBuffer();

    // 1. Header
    buffer.writeln('[Script Info]');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('PlayResX: 1080'); // Reference resolution width
    buffer.writeln('PlayResY: 1920'); // Reference resolution height
    buffer.writeln('WrapStyle: 0');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln('');

    // 2. Styles
    buffer.writeln('[V4+ Styles]');
    buffer.writeln(
        'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');

    // Define styles based on template
    // Colors are in &HBBGGRR format (BGR)
    // Alignment 2 is Bottom Center

    // Default/Classic Style (Yellow Highlight)
    // Primary: White (&H00FFFFFF), Outline: Black (&H00000000)
    buffer.writeln(
        'Style: Default,$fontName,70,&H00FFFFFF,&H0000FFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,0,2,20,20,150,1');

    // Highlight Style (Yellow)
    buffer.writeln(
        'Style: Highlight,$fontName,70,&H0000D7FF,&H0000FFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,0,2,20,20,150,1');

    buffer.writeln('');

    // 3. Events
    buffer.writeln('[Events]');
    buffer.writeln(
        'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    for (final caption in captions) {
      // We need to generate a dialogue line for EACH word state to simulate karaoke highlighting
      // Or use actual karaoke tags {\k} if we want smooth transitions, but block highlighting is easier to match the Flutter UI.

      // Approach: For each word in the caption, generate a dialogue line where that word is highlighted.
      // Actually, a better approach for "karaoke" style in ASS without complex tags is to have the full line,
      // but use inline color tags for the active word.

      // Let's iterate through the words and create time-segmented lines

      // If no words, just show full text
      if (caption.words.isEmpty) {
        final start = _formatAssTime(caption.start);
        final end = _formatAssTime(caption.end);
        buffer
            .writeln('Dialogue: 0,$start,$end,Default,,0,0,0,,${caption.text}');
        continue;
      }

      // If we have words, we need to be careful. The caption has a total start/end.
      // The words have their own start/end.
      // We want to show the FULL text, but highlight the CURRENT word.

      // We can create a sequence of Dialogue events, one for each word's duration.
      for (int i = 0; i < caption.words.length; i++) {
        final currentWord = caption.words[i];

        // Determine start and end for this "frame" of the caption
        // Start is the start of the current word
        // End is the start of the next word, OR the end of the caption if it's the last word

        String startTime = currentWord.start;
        String endTime = currentWord.end;

        // Adjust start time for the first word to match caption start if needed
        if (i == 0) startTime = caption.start;

        // Adjust end time for last word
        if (i == caption.words.length - 1)
          endTime = caption.end;
        else {
          // Gap filling: make sure this frame lasts until the next word starts
          endTime = caption.words[i + 1].start;
        }

        final assStart = _formatAssTime(startTime);
        final assEnd = _formatAssTime(endTime);

        // Build the text with highlighting
        final textBuffer = StringBuffer();
        for (int j = 0; j < caption.words.length; j++) {
          final word = caption.words[j];

          if (j == i) {
            // Active word - Yellow
            textBuffer.write('{\\c&H00D7FF&}${word.word}{\\c&HFFFFFF&} ');
          } else if (j < i) {
            // Already spoken - White (or keep yellow if we want trailing highlight)
            // User UI shows only current word yellow? Or accumulated?
            // Looking at the code: i < highlightedWordCount ? Colors.yellow : Colors.white
            // So previous words stay yellow!
            textBuffer.write('{\\c&H00D7FF&}${word.word}{\\c&HFFFFFF&} ');
          } else {
            // Future words - White
            textBuffer.write('${word.word} ');
          }
        }

        buffer.writeln(
            'Dialogue: 0,$assStart,$assEnd,Default,,0,0,0,,${textBuffer.toString().trim()}');
      }
    }

    return buffer.toString();
  }

  /// Convert MM:SS:mmm to H:MM:SS.cc (ASS format)
  String _formatAssTime(String timestamp) {
    // Input: 00:00:000 (MM:SS:mmm)
    // Output: 0:00:00.00 (H:MM:SS.cc)

    try {
      final parts = timestamp.split(':');
      if (parts.length != 3) return '0:00:00.00';

      int minutes = int.parse(parts[0]);
      int seconds = int.parse(parts[1]);
      int milliseconds = int.parse(parts[2]);

      int hours = minutes ~/ 60;
      minutes = minutes % 60;

      // ASS uses centiseconds (1/100th of a second)
      int centiseconds = milliseconds ~/ 10;

      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '0:00:00.00';
    }
  }
}
