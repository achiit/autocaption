import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VoiceoverService {
  late final RecorderController recorderController;
  bool _isRecorderInitialized = false;

  VoiceoverService() {
    recorderController = RecorderController();
  }

  Future<void> init() async {
    if (_isRecorderInitialized) return;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
    _isRecorderInitialized = true;
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) await init();

    final hasPermission = await recorderController.checkPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/voiceover_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await recorderController.record(path: path);
  }

  Future<String?> stopRecording() async {
    if (!_isRecorderInitialized) return null;
    final path = await recorderController.stop();
    return path;
  }

  Future<void> deleteRecording() async {
    if (!_isRecorderInitialized) return;
    try {
      await recorderController.stop();
    } catch (e) {
      // Ignore errors if already stopped
    }
  }

  void dispose() {
    recorderController.dispose();
  }
}
