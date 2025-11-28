import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/caption_model.dart';
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
    String? voiceoverAudioPath,
    Duration? voiceoverStart,
    Duration? voiceoverEnd,
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
      // -vf "ass=captions.ass:fontsdir=fonts"
      // Note: We need to escape paths properly for FFmpeg
      final inputPath = videoFile.path;
      final assPath = assFile.path;
      final fontsPath = fontsDir.path;

      // FFmpeg command to burn subtitles and mix audio
      // Using libx264 for compatibility
      // -preset ultrafast for speed on mobile

      String command;
      if (voiceoverAudioPath != null) {
        // Mix original audio and voiceover
        // Input 0: Video
        // Input 1: Voiceover Audio (Trimmed if needed)

        String audioInput = '-i "$voiceoverAudioPath"';
        if (voiceoverStart != null && voiceoverEnd != null) {
          // Calculate duration
          // -ss start -to end
          final start = voiceoverStart.inMilliseconds / 1000.0;
          final end = voiceoverEnd.inMilliseconds / 1000.0;
          audioInput = '-ss $start -to $end -i "$voiceoverAudioPath"';
        }

        command =
            '-i "$inputPath" $audioInput -filter_complex "[0:a][1:a]amix=inputs=2:duration=first[a];[0:v]ass=\'$assPath\':fontsdir=\'$fontsPath\'[v]" -map "[v]" -map "[a]" -c:v libx264 -preset ultrafast -c:a aac "$outputPath"';
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
    required String audioPath,
    Duration? audioStart,
    Duration? audioEnd,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.mp4';

      String audioInput = '-i "$audioPath"';
      if (audioStart != null && audioEnd != null) {
        final start = audioStart.inMilliseconds / 1000.0;
        final end = audioEnd.inMilliseconds / 1000.0;
        audioInput = '-ss $start -to $end -i "$audioPath"';
      }

      // Mix audio: [0:a] (video audio) + [1:a] (voiceover)
      // We use -c:v copy to avoid re-encoding video (fast)
      // We use -c:a aac for audio
      final command =
          '-i "${videoFile.path}" $audioInput -filter_complex "[0:a][1:a]amix=inputs=2:duration=first[a]" -map 0:v -map "[a]" -c:v copy -c:a aac "$outputPath"';

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
