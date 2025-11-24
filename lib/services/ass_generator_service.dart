import '../models/caption_model.dart';

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
    buffer.writeln('PlayResX: 1080');
    buffer.writeln('PlayResY: 1920'); // Working in 1080x1920 space
    buffer.writeln('WrapStyle: 0');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln('');

    // 2. Styles
    buffer.writeln('[V4+ Styles]');
    buffer.writeln(
        'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');

    // Scaling factor: Python sizes are likely for 720p/1280p (based on ffmpeg scale filter in python code)
    // We are using PlayResY=1920. 1920 / 1280 = 1.5.
    const double scale = 1.5;

    // Default values
    double fontSize = 52 * scale;
    String primaryColor = _toAssColor(255, 255, 255, 255);
    String outlineColor =
        _toAssColor(0, 0, 0, 255); // Used for Border or Box Background
    String backColor = _toAssColor(0, 0, 0, 128); // Shadow
    String highlightColor = _toAssColor(255, 255, 0, 255);

    int borderStyle = 1; // 1=Outline, 3=Opaque Box
    double outlineWidth = 2.0;
    double shadowDepth = 0.0;
    int bold = -1; // -1 = True

    // Apply Template Logic
    switch (template.toLowerCase()) {
      case 'neon':
        // "Neon Glow"
        // Font: 56 -> 84
        // Bg: (20, 20, 40, 180) -> Dark Blue-ish Box?
        // Python code draws a rounded rect with this color. So it IS a box.
        // But it also says "has_glow".
        // ASS can't easily do Box AND Glow on text.
        // Let's prioritize the Box background as that's the main container.
        // Or, if "Glow" is the main feature, maybe the box is subtle?
        // Python: bg_color=(20, 20, 40, 180). It's a semi-transparent dark box.
        // Highlight: Cyan.

        fontSize = 56 * scale;
        primaryColor = _toAssColor(255, 255, 255, 255);

        // Box Background
        borderStyle = 3;
        outlineColor = _toAssColor(20, 20, 40, 180); // Box Color

        highlightColor = _toAssColor(0, 255, 255, 255); // Cyan

        // ASS doesn't support glow on text *inside* a box easily in one style.
        // We will stick to the Box style to match the "container" look.
        break;

      case 'bold':
        // "Bold Pop"
        // Font: 60 -> 90
        // Bg: Transparent -> No Box.
        // Stroke: 4px Black.
        // Highlight: Red.

        fontSize = 60 * scale;
        primaryColor = _toAssColor(255, 255, 255, 255);

        borderStyle = 1; // Outline
        outlineColor = _toAssColor(0, 0, 0, 255); // Black Stroke
        outlineWidth = 4.0 * scale; // Scale stroke too? Maybe.

        highlightColor = _toAssColor(255, 50, 50, 255); // Red
        shadowDepth = 0;
        break;

      case 'minimal':
        // "Minimal Clean"
        // Font: 48 -> 72
        // Bg: White (255, 255, 255, 200).
        // Text: Black.
        // Highlight: Orange.

        fontSize = 48 * scale;
        primaryColor = _toAssColor(0, 0, 0, 255); // Black Text

        borderStyle = 3; // Box
        outlineColor = _toAssColor(255, 255, 255, 200); // White Box

        highlightColor = _toAssColor(255, 100, 0, 255); // Orange
        break;

      case 'gradient':
        // "Gradient Style"
        // Font: 54 -> 81
        // Bg: (80, 0, 120, 160) -> Purple.
        // Text: White.
        // Highlight: Gold.

        fontSize = 54 * scale;
        primaryColor = _toAssColor(255, 255, 255, 255);

        borderStyle = 3; // Box
        outlineColor = _toAssColor(80, 0, 120, 160); // Purple Box

        highlightColor = _toAssColor(255, 200, 0, 255); // Gold
        break;

      case 'classic':
      default:
        // "Classic"
        // Font: 52 -> 78
        // Bg: (0, 0, 0, 140).
        // Text: White.
        // Highlight: Yellow.

        fontSize = 52 * scale;
        primaryColor = _toAssColor(255, 255, 255, 255);

        borderStyle = 3; // Box
        outlineColor = _toAssColor(0, 0, 0, 140); // Black Box

        highlightColor = _toAssColor(255, 255, 0, 255); // Yellow
        break;
    }

    // Write the Style Line
    // Note: In BorderStyle=3, Outline param controls nothing? Or box padding?
    // Usually standard padding.
    buffer.writeln(
        'Style: Default,$fontName,$fontSize,$primaryColor,&H0000FFFF,$outlineColor,$backColor,$bold,0,0,0,100,100,0,0,$borderStyle,$outlineWidth,$shadowDepth,2,20,20,150,1');

    buffer.writeln('');

    // 3. Events
    buffer.writeln('[Events]');
    buffer.writeln(
        'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    for (final caption in captions) {
      if (caption.words.isEmpty) {
        final start = _formatAssTime(caption.start);
        final end = _formatAssTime(caption.end);
        buffer
            .writeln('Dialogue: 0,$start,$end,Default,,0,0,0,,${caption.text}');
        continue;
      }

      for (int i = 0; i < caption.words.length; i++) {
        final currentWord = caption.words[i];

        String startTime = currentWord.start;
        String endTime = currentWord.end;

        if (i == 0) startTime = caption.start;

        if (i == caption.words.length - 1)
          endTime = caption.end;
        else {
          endTime = caption.words[i + 1].start;
        }

        final assStart = _formatAssTime(startTime);
        final assEnd = _formatAssTime(endTime);

        final textBuffer = StringBuffer();
        for (int j = 0; j < caption.words.length; j++) {
          final word = caption.words[j];

          if (j == i) {
            // Active word - Highlight Color
            // Strip &H from our helper output for the tag
            // Helper returns &HBBGGRR
            final colorCode = highlightColor.replaceAll('&H', '');
            final primaryCode = primaryColor.replaceAll('&H', '');

            textBuffer
                .write('{\\c&H$colorCode&}${word.word}{\\c&H$primaryCode&} ');
          } else {
            // Other words - Primary Color
            textBuffer.write('${word.word} ');
          }
        }

        buffer.writeln(
            'Dialogue: 0,$assStart,$assEnd,Default,,0,0,0,,${textBuffer.toString().trim()}');
      }
    }

    return buffer.toString();
  }

  /// Convert RGBA (0-255) to ASS Color &HBBGGRR
  String _toAssColor(int r, int g, int b, int a) {
    // ASS Alpha: 00 (Opaque) - FF (Transparent)
    // Input Alpha: 255 (Opaque) - 0 (Transparent)
    final assAlpha = (255 - a).clamp(0, 255);

    final aa = assAlpha.toRadixString(16).padLeft(2, '0').toUpperCase();
    final bb = b.toRadixString(16).padLeft(2, '0').toUpperCase();
    final gg = g.toRadixString(16).padLeft(2, '0').toUpperCase();
    final rr = r.toRadixString(16).padLeft(2, '0').toUpperCase();

    // Format: &HAABBGGRR
    return '&H$aa$bb$gg$rr';
  }

  /// Convert MM:SS:mmm to H:MM:SS.cc (ASS format)
  String _formatAssTime(String timestamp) {
    try {
      final parts = timestamp.split(':');
      if (parts.length != 3) return '0:00:00.00';

      int minutes = int.parse(parts[0]);
      int seconds = int.parse(parts[1]);
      int milliseconds = int.parse(parts[2]);

      int hours = minutes ~/ 60;
      minutes = minutes % 60;

      int centiseconds = milliseconds ~/ 10;

      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '0:00:00.00';
    }
  }
}
