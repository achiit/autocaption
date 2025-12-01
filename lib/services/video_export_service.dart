import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/caption_model.dart';
import '../models/voiceover_segment.dart';
import 'ass_generator_service.dart';

class VideoExportService {
  final AssSubtitleGeneratorService _assGenerator =
      AssSubtitleGeneratorService();

  /// Export video with captions using on-device FFmpeg
  Future<File> exportVideo({
    required File videoFile,
    required List<CaptionModel> captions,
    required String aspectRatio,
    required String template,
    required String outputPath,
    required Function(String) onStatusUpdate,
    List<VoiceoverSegment> segments = const [],
  }) async {
    try {
      // 1. Prepare Environment
      onStatusUpdate('Preparing resources...');
      final tempDir = await getTemporaryDirectory();
      final fontsDir = Directory('${tempDir.path}/fonts');
      if (!await fontsDir.exists()) {
        await fontsDir.create(recursive: true);
      }

      // 2. Copy Font (Inter)
      final fontFile = File('${fontsDir.path}/Inter.ttf');
      if (!await fontFile.exists()) {
        final fontData = await rootBundle.load('assets/fonts/inter.ttf');
        await fontFile.writeAsBytes(
          fontData.buffer.asUint8List(
            fontData.offsetInBytes,
            fontData.lengthInBytes,
          ),
        );
      }

      // 3. Generate ASS Subtitles
      onStatusUpdate('Generating subtitles...');
      final assContent = _assGenerator.generateAssContent(
        captions: captions,
        fontName: 'Inter',
        template: template,
      );

      final assFile = File('${tempDir.path}/captions.ass');
      await assFile.writeAsString(assContent);

      // 4. Run FFmpeg
      onStatusUpdate('Rendering video...');

      // Construct command
      final inputPath = videoFile.path;
      final assPath = assFile.path;
      final fontsPath = fontsDir.path;

      String command;
      if (segments.isNotEmpty) {
        // Mix original audio and voiceover segments
        // Inputs:
        // 0: Video
        // 1..N: Audio segments

        String inputs = '-i "$inputPath"';
        String filterComplex = '';
        String mixInputs = '[0:a]'; // Start with video audio

        for (int i = 0; i < segments.length; i++) {
          final segment = segments[i];
          inputs += ' -i "${segment.filePath}"';

          // Trim and Delay
          final startSec = segment.sourceStart.inMilliseconds / 1000.0;
          final endSec = segment.sourceEnd.inMilliseconds / 1000.0;
          final delayMs = segment.videoStart.inMilliseconds;

          filterComplex +=
              '[${i + 1}:a]atrim=start=$startSec:end=$endSec,adelay=$delayMs|$delayMs[a$i];';
          mixInputs += '[a$i]';
        }

        // Mix all audio
        filterComplex +=
            '${mixInputs}amix=inputs=${segments.length + 1}:duration=first[a];';

        // Add subtitles
        filterComplex += '[0:v]ass=\'$assPath\':fontsdir=\'$fontsPath\'[v]';

        command =
            '$inputs -filter_complex "$filterComplex" -map "[v]" -map "[a]" -c:v libx264 -preset ultrafast -c:a aac "$outputPath"';
      } else {
        // Standard export
        command =
            '-i "$inputPath" -vf "ass=\'$assPath\':fontsdir=\'$fontsPath\'" -c:v libx264 -preset ultrafast -c:a copy "$outputPath"';
      }

      print('FFmpeg Command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        onStatusUpdate('Export complete!');
        return File(outputPath);
      } else {
        final logs = await session.getAllLogsAsString();
        print('FFmpeg Error Logs: $logs');
        throw Exception('FFmpeg failed with return code $returnCode');
      }
    } catch (e) {
      print('Export Error: $e');
      throw Exception('Failed to export video: $e');
    }
  }

  Future<File> mergeAudioVideo({
    required File videoFile,
    required List<VoiceoverSegment> segments,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.mp4';

      if (segments.isEmpty) {
        return videoFile;
      }

      // Build FFmpeg command
      // Inputs:
      // 0: Video
      // 1..N: Audio segments

      String inputs = '-i "${videoFile.path}"';
      String filterComplex = '';
      String mixInputs = '[0:a]'; // Start with video audio

      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];
        inputs += ' -i "${segment.filePath}"';

        // Trim and Delay
        // [i+1:a]atrim=start=S:end=E,adelay=D|D[a_i]

        final startSec = segment.sourceStart.inMilliseconds / 1000.0;
        final endSec = segment.sourceEnd.inMilliseconds / 1000.0;
        final delayMs = segment.videoStart.inMilliseconds;

        // Note: adelay uses milliseconds
        filterComplex +=
            '[${i + 1}:a]atrim=start=$startSec:end=$endSec,adelay=$delayMs|$delayMs[a$i];';
        mixInputs += '[a$i]';
      }

      // Mix all
      // amix=inputs=N+1:duration=first[a]
      filterComplex +=
          '${mixInputs}amix=inputs=${segments.length + 1}:duration=first[a]';

      final command =
          '$inputs -filter_complex "$filterComplex" -map 0:v -map "[a]" -c:v copy -c:a aac "$outputPath"';

      print('FFmpeg Merge Command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return File(outputPath);
      } else {
        final logs = await session.getAllLogsAsString();
        print('FFmpeg Merge Error Logs: $logs');
        throw Exception('FFmpeg merge failed with return code $returnCode');
      }
    } catch (e) {
      print('Merge Error: $e');
      throw Exception('Failed to merge audio/video: $e');
    }
  }
}
