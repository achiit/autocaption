import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/caption_model.dart';

class VideoExportService {
  final Dio _dio = Dio();

  /// Upload video to server for processing
  Future<String> uploadVideo({
    required File videoFile,
    required List<CaptionModel> captions,
    required String aspectRatio,
    required String template,
  }) async {
    FormData formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(
        videoFile.path,
        filename: 'video.mp4',
      ),
      'captions': jsonEncode(captions.map((c) => c.toJson()).toList()),
      'aspect_ratio': aspectRatio,
      'template': template,
    });

    final response = await _dio.post(
      '${ApiConstants.serverUrl}${ApiConstants.uploadEndpoint}',
      data: formData,
    );

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusMessage}');
    }

    return response.data['job_id'] as String;
  }

  /// Poll for processing status
  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    final response = await _dio.get(
      '${ApiConstants.serverUrl}${ApiConstants.statusEndpoint}/$jobId',
    );

    if (response.statusCode != 200) {
      throw Exception('Status check failed');
    }

    return response.data as Map<String, dynamic>;
  }

  /// Download processed video
  Future<File> downloadVideo({
    required String jobId,
    required String savePath,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.serverUrl}${ApiConstants.downloadEndpoint}/$jobId',
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.statusCode != 200) {
      throw Exception('Download failed');
    }

    final file = File(savePath);
    await file.writeAsBytes(response.data);
    return file;
  }

  /// Complete export flow with status polling
  Future<File> exportVideo({
    required File videoFile,
    required List<CaptionModel> captions,
    required String aspectRatio,
    required String template,
    required String outputPath,
    required Function(String) onStatusUpdate,
  }) async {
    // Upload
    onStatusUpdate('Uploading video...');
    final jobId = await uploadVideo(
      videoFile: videoFile,
      captions: captions,
      aspectRatio: aspectRatio,
      template: template,
    );

    // Poll for completion
    while (true) {
      final status = await getJobStatus(jobId);
      final statusStr = status['status'] as String;
      final progress = status['progress'] as int? ?? 0;

      onStatusUpdate('Processing: $progress%');

      if (statusStr == 'completed') {
        break;
      } else if (statusStr == 'failed') {
        final error = status['error'] as String? ?? 'Unknown error';
        throw Exception('Processing failed: $error');
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    // Download
    onStatusUpdate('Downloading...');
    final file = await downloadVideo(jobId: jobId, savePath: outputPath);
    onStatusUpdate('Complete!');

    return file;
  }
}
