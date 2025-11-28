import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/caption_model.dart';
import '../services/voiceover_service.dart';
import '../services/gemini_service.dart';
import '../services/video_export_service.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/time_utils.dart';

class VideoViewModel extends ChangeNotifier {
  // Services
  final GeminiService _geminiService = GeminiService();
  final VideoExportService _exportService = VideoExportService();

  // Video state
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  File? _videoFile;

  // Caption state
  List<CaptionModel> _captions = [];
  String _currentCaptionText = '';
  List<String> _currentCaptionWords = [];
  int _highlightedWordCount = 0;

  // UI state
  bool _isProcessing = false;
  String _statusMessage = '';
  String _selectedLanguage = AppConstants.supportedLanguages[0];
  String _aspectRatioName = AppConstants.aspectRatio9x16;
  double _aspectRatio = AppConstants.aspectRatioVertical;
  String _selectedTemplate = 'classic';

  // Projects
  List<Map<String, dynamic>> _projects = [];

  // Getters
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  List<CaptionModel> get captions => _captions;
  String get currentCaptionText => _currentCaptionText;
  List<String> get currentCaptionWords => _currentCaptionWords;
  int get highlightedWordCount => _highlightedWordCount;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  String get selectedLanguage => _selectedLanguage;
  String get aspectRatioName => _aspectRatioName;
  double get aspectRatio => _aspectRatio;
  String get selectedTemplate => _selectedTemplate;
  bool get hasVideo => _videoFile != null;
  bool get hasCaptions => _captions.isNotEmpty;
  List<Map<String, dynamic>> get projects => _projects;

  VideoViewModel() {
    loadProjects();
  }

  /// Load saved projects
  Future<void> loadProjects() async {
    print("Loading projects...");
    final prefs = await SharedPreferences.getInstance();
    final String? projectsString = prefs.getString('projects');
    if (projectsString != null) {
      _projects = List<Map<String, dynamic>>.from(jsonDecode(projectsString));
      print("Loaded ${_projects.length} projects");
      notifyListeners();
    } else {
      print("No projects found in prefs");
    }
  }

  /// Save project to history
  Future<void> _saveProjectToHistory(String filePath) async {
    print("Saving project to history: $filePath");
    final prefs = await SharedPreferences.getInstance();
    final project = {
      'path': filePath,
      'date': DateFormat('MMM d, yyyy').format(DateTime.now()),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _projects.insert(0, project);
    final success = await prefs.setString('projects', jsonEncode(_projects));
    print(
        "Project saved to prefs: $success. Total projects: ${_projects.length}");
    notifyListeners();
  }

  /// Delete project from history
  Future<void> deleteProject(int index) async {
    if (index >= 0 && index < _projects.length) {
      _projects.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('projects', jsonEncode(_projects));
      notifyListeners();
    }
  }

  /// Pick and load video
  Future<void> pickVideo(File videoFile) async {
    try {
      _videoFile = videoFile;
      await _initializePlayer(videoFile);
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error loading video: $e';
      notifyListeners();
    }
  }

  /// Initialize video player
  Future<void> _initializePlayer(File videoFile) async {
    _chewieController?.dispose();
    await _videoController?.dispose();

    _videoController = VideoPlayerController.file(videoFile);
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      aspectRatio: _aspectRatio,
      autoPlay: false,
      looping: false,
      showControls: true,
    );

    // Listen to playback for caption updates
    _videoController!.addListener(_updateCaptionOverlay);

    notifyListeners();
  }

  /// Generate captions using Gemini
  Future<void> generateCaptions() async {
    if (_videoFile == null) return;

    try {
      _isProcessing = true;
      _statusMessage = 'Initializing...';
      notifyListeners();

      File videoToUpload = _videoFile!;

      // Check for voiceover and merge if present
      if (_recordedAudioPath != null) {
        _statusMessage = 'Merging voiceover...';
        notifyListeners();
        try {
          videoToUpload = await _exportService.mergeAudioVideo(
            videoFile: _videoFile!,
            audioPath: _recordedAudioPath!,
            audioStart: _voiceoverStart,
            audioEnd: _voiceoverEnd,
          );
        } catch (e) {
          print("Error merging audio for captions: $e");
          _statusMessage = 'Error merging audio: $e';
          rethrow;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final customKey = prefs.getString('custom_gemini_key');

      // Try with custom key if exists
      if (customKey != null && customKey.isNotEmpty) {
        try {
          await _performCaptionGeneration(customKey, videoToUpload);
          return; // Success
        } catch (e) {
          print('Custom API key failed: $e. Retrying with default key.');
          _statusMessage = 'Retrying with default key...';
          notifyListeners();
        }
      }

      // Fallback or default
      await _performCaptionGeneration(ApiConstants.geminiApiKey, videoToUpload);
    } catch (e) {
      _statusMessage = 'Error: $e';
      rethrow; // Rethrow to let UI handle error dialog
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _performCaptionGeneration(String apiKey, File videoFile) async {
    _statusMessage = 'Uploading video...';
    notifyListeners();

    final fileUri = await _geminiService.uploadVideo(videoFile, apiKey: apiKey);
    if (fileUri == null) throw Exception("Upload failed");

    _statusMessage = 'Processing video...';
    notifyListeners();

    await _geminiService.pollFileState(fileUri, apiKey: apiKey);

    _statusMessage = 'Generating captions in $_selectedLanguage...';
    notifyListeners();

    _captions = await _geminiService.generateCaptions(
      fileUri: fileUri,
      language: _selectedLanguage,
      apiKey: apiKey,
    );

    _statusMessage = 'Captions generated!';
  }

  /// Export video with captions using Server API
  Future<String> exportVideo({String? style}) async {
    if (_videoFile == null || _captions.isEmpty) {
      _statusMessage = 'No video or captions to export';
      notifyListeners();
      throw Exception('No video to export');
    }

    if (style != null) {
      _selectedTemplate = style;
    }

    try {
      _isProcessing = true;
      notifyListeners();

      final directory = await getTemporaryDirectory();
      final outputPath =
          '${directory.path}/captioned_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final file = await _exportService.exportVideo(
        videoFile: _videoFile!,
        captions: _captions,
        aspectRatio: _aspectRatioName,
        template: _selectedTemplate,
        outputPath: outputPath,
        voiceoverAudioPath: _recordedAudioPath,
        voiceoverStart: _voiceoverStart,
        voiceoverEnd: _voiceoverEnd,
        onStatusUpdate: (status) {
          _statusMessage = status;
          notifyListeners();
        },
      );

      // Save to Gallery
      _statusMessage = 'Saving to gallery...';
      notifyListeners();

      try {
        // Check permissions and save
        if (await Gal.hasAccess() || await Gal.requestAccess()) {
          await Gal.putVideo(file.path);
          print("Video saved to gallery successfully");
        } else {
          print("Gallery access denied");
        }
      } catch (e) {
        print("Error saving to gallery: $e");
        // Don't rethrow, continue to save project history
      }

      // Save to history
      await _saveProjectToHistory(file.path);

      _statusMessage = 'Export complete!';
      return file.path;
    } catch (e) {
      print("Export failed with error: $e");
      _statusMessage = 'Export failed: $e';
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Update caption overlay based on video position
  void _updateCaptionOverlay() {
    if (_videoController == null || !_videoController!.value.isPlaying) return;

    final currentPos = _videoController!.value.position;
    String text = '';
    List<String> words = [];
    int highlightedCount = 0;

    // Helper to parse MM:SS:mmm
    Duration parseTime(String t) {
      try {
        final parts = t.split(':');
        if (parts.length == 3) {
          final minutes = int.parse(parts[0]);
          final seconds = int.parse(parts[1]);
          final milliseconds = int.parse(parts[2]);
          return Duration(
              minutes: minutes, seconds: seconds, milliseconds: milliseconds);
        }
      } catch (e) {
        // Fallback
      }
      return Duration.zero;
    }

    for (var caption in _captions) {
      final start = parseTime(caption.start);
      final end = parseTime(caption.end);

      if (currentPos >= start && currentPos < end) {
        text = caption.text;
        words = caption.words.map((w) => w.word).toList();

        // Calculate highlighted count based on word timings
        for (int i = 0; i < caption.words.length; i++) {
          final wStart = parseTime(caption.words[i].start);
          if (currentPos >= wStart) {
            highlightedCount = i + 1;
          }
        }
        break;
      }
    }

    if (text != _currentCaptionText ||
        highlightedCount != _highlightedWordCount) {
      _currentCaptionText = text;
      _currentCaptionWords = words;
      _highlightedWordCount = highlightedCount;
      notifyListeners();
    }
  }

  /// Seek to caption timestamp
  Future<void> seekToCaption(String timestamp) async {
    if (_videoController == null) return;

    final duration = TimeUtils.parseTimestamp(timestamp);
    await _videoController!.seekTo(duration);
    await _videoController!.play();
  }

  /// Change language selection
  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  /// Change aspect ratio
  void setAspectRatio(String ratioName) {
    _aspectRatioName = ratioName;
    _aspectRatio = ratioName == AppConstants.aspectRatio9x16
        ? AppConstants.aspectRatioVertical
        : AppConstants.aspectRatioHorizontal;

    // Re-initialize player
    if (_videoFile != null) {
      _initializePlayer(_videoFile!);
    }

    notifyListeners();
  }

  /// Change template selection
  void setTemplate(String template) {
    _selectedTemplate = template;
    notifyListeners();
  }

  /// Reset state to initial values
  Future<void> resetState() async {
    _chewieController?.dispose();
    _chewieController = null;
    await _videoController?.dispose();
    _videoController = null;
    _videoFile = null;
    _captions = [];
    _currentCaptionText = '';
    _currentCaptionWords = [];
    _highlightedWordCount = 0;
    _statusMessage = '';
    notifyListeners();
  }

  // Voiceover State
  final VoiceoverService _voiceoverService = VoiceoverService();
  bool _isVoiceoverMode = false;
  bool _isRecording = false;
  String? _recordedAudioPath;

  bool get isVoiceoverMode => _isVoiceoverMode;
  bool get isRecording => _isRecording;
  String? get recordedAudioPath => _recordedAudioPath;

  // Trimming State
  Duration? _voiceoverStart;
  Duration? _voiceoverEnd;
  Duration? get voiceoverStart => _voiceoverStart;
  Duration? get voiceoverEnd => _voiceoverEnd;

  void setVoiceoverTrim(Duration start, Duration end) {
    _voiceoverStart = start;
    _voiceoverEnd = end;
    notifyListeners();
  }

  // Expose controller for UI
  get recorderController => _voiceoverService.recorderController;

  Future<void> toggleVoiceoverMode() async {
    if (!_isVoiceoverMode) {
      try {
        await _voiceoverService.init();
        _isVoiceoverMode = true;
      } catch (e) {
        _statusMessage = 'Microphone permission required';
        notifyListeners();
        return;
      }
    } else {
      _isVoiceoverMode = false;
    }
    notifyListeners();
  }

  Future<void> deleteVoiceover() async {
    await _voiceoverService.deleteRecording();
    _recordedAudioPath = null;
    _voiceoverStart = null;
    _voiceoverEnd = null;
    notifyListeners();
  }

  Future<void> startRecording() async {
    try {
      await _voiceoverService.startRecording();
      _isRecording = true;
      // Start video playback to sync
      await _videoController?.play(); // Corrected from _videoPlayerController
      notifyListeners();
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      print("Stopping recording...");
      final path = await _voiceoverService.stopRecording();
      print("Recording stopped. Path: $path");
      _isRecording = false;
      _recordedAudioPath = path;
      // Stop video playback
      await _videoController?.pause(); // Corrected from _videoPlayerController
      notifyListeners();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void deleteRecording() {
    _recordedAudioPath = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.removeListener(
        _updateCaptionOverlay); // Keep existing listener removal
    _videoController?.dispose();
    _voiceoverService.dispose(); // Add new dispose for voiceover service
    super.dispose();
  }
}
