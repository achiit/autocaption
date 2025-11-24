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

      // FFmpeg command to burn subtitles
      // Using libx264 for compatibility
      // -preset ultrafast for speed on mobile
      final command =
          '-i "$inputPath" -vf "ass=\'$assPath\':fontsdir=\'$fontsPath\'" -c:v libx264 -preset ultrafast -c:a copy "$outputPath"';

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
}
