import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/caption_model.dart';
import '../models/voiceover_segment.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  VoiceoverSegment? _currentPlayingSegment;
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
    _configureAudioSession();
  }

  Future<void> _configureAudioSession() async {
    final session = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.movie,
        usageType: AndroidUsageType.media,
        // CRITICAL CHANGE: Set to 'none'.
        // We do not want the Voiceover to demand focus and kill the VideoPlayer.
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers, // Keeps iOS happy
          AVAudioSessionOptions.defaultToSpeaker
        },
      ),
    );
    // Apply this ONCE globally, not inside the loop
    await _audioPlayer.setAudioContext(session);
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

    _videoController = VideoPlayerController.file(
      videoFile,
      videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true), // CRITICAL: Don't pause on focus loss
    );
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      aspectRatio: _aspectRatio,
      autoPlay: false,
      looping: false,
      showControls: false, // Disable controls to prevent conflict with timeline
    );

    // Listen to playback for caption updates
    _videoController!.addListener(_onVideoTick);

    notifyListeners();
  }

  // ... (keeping generateCaptions and others) ...

  // ... (skipping to togglePlayback) ...

  /// Toggle video playback
  Future<void> togglePlayback() async {
    if (_videoController == null) return;

    print("TogglePlayback: Current Master=$_isPlaying");

    if (_isPlaying) {
      // PAUSE
      _isPlaying = false;
      await _pauseAll();
    } else {
      // PLAY
      _isPlaying = true;

      // Seek to start if at end
      if (_videoController!.value.position >=
          _videoController!.value.duration) {
        print("TogglePlayback: At end, seeking to start.");
        await _videoController!.seekTo(Duration.zero);
      }
      print("TogglePlayback: Starting video.");
      await _videoController!.play();
    }
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
      if (_voiceoverSegments.isNotEmpty) {
        _statusMessage = 'Merging voiceover...';
        notifyListeners();
        try {
          videoToUpload = await _exportService.mergeAudioVideo(
            videoFile: _videoFile!,
            segments: _voiceoverSegments,
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
        segments: _voiceoverSegments,
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

  // Audio Sync Guard
  bool _isAudioSyncing = false;

  // Master Playback Switch (Target State)
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Main Loop: Runs on every video frame
  void _onVideoTick() {
    if (_videoController == null) return;

    final videoPos = _videoController!.value.position;
    final duration = _videoController!.value.duration;
    final videoIsPlaying = _videoController!.value.isPlaying;

    // Debug Log (Throttle this if too spammy, but for now we need it)
    // print("Tick: Pos=$videoPos, Master=$_isPlaying, VideoPlaying=$videoIsPlaying");

    // 1. Handle Recording Auto-Stop
    if (_isRecording && videoPos >= duration) {
      print("Tick: Auto-stop recording at end");
      stopRecording();
      return;
    }

    // 2. Handle Playback End
    if (_isPlaying && videoPos >= duration) {
      print("Tick: Playback ended. Resetting.");
      _isPlaying = false;
      _pauseAll();
      notifyListeners();
      return;
    }

    // 3. Strict Sync: Audio follows Video
    if (_isPlaying) {
      if (videoIsPlaying) {
        _syncAudio(videoPos);
      } else {
        print("Tick: Master is ON but Video is PAUSED. Pausing Audio.");
        _pauseAudio();
      }
    } else {
      // Master is OFF
      if (videoIsPlaying) {
        print("Tick: Master is OFF but Video is PLAYING. Pausing Video.");
        _videoController!.pause();
      }
      _pauseAudio();
    }

    // 4. Update Captions
    _updateCaptions(videoPos);
  }

  /// Sync audio player to video position
  Future<void> _syncAudio(Duration videoPos) async {
    if (_isAudioSyncing) return;

    try {
      _isAudioSyncing = true;

      VoiceoverSegment? activeSegment;
      for (final segment in _voiceoverSegments) {
        if (videoPos >= segment.videoStart && videoPos < segment.videoEnd) {
          activeSegment = segment;
          break;
        }
      }

      if (activeSegment != null) {
        final offset =
            videoPos - activeSegment.videoStart + activeSegment.sourceStart;

        bool isNewSegment = _currentPlayingSegment?.id != activeSegment.id;
        bool isNotPlaying = _audioPlayer.state != PlayerState.playing;

        if (isNewSegment || isNotPlaying) {
          if (offset >= Duration.zero) {
            print("Sync: Playing segment ${activeSegment.id} at $offset");

            // REMOVED: await _audioPlayer.setAudioContext(...)
            // Do not re-configure context here. Rely on the global config.

            await _audioPlayer.setVolume(1.0); // Ensure full volume

            await _audioPlayer.play(DeviceFileSource(activeSegment.filePath),
                position: offset);
            _currentPlayingSegment = activeSegment;
          }
        }
      } else {
        if (_audioPlayer.state == PlayerState.playing) {
          print("Sync: No active segment. Pausing audio.");
          await _audioPlayer.pause();
          _currentPlayingSegment = null;
        }
      }
    } catch (e) {
      print("Sync error: $e");
    } finally {
      _isAudioSyncing = false;
    }
  }

  /// Helper to pause audio safely
  Future<void> _pauseAudio() async {
    if (_audioPlayer.state == PlayerState.playing) {
      print("PauseAudio: Stopping audio player.");
      await _audioPlayer.pause();
      _currentPlayingSegment = null;
    }
  }

  /// Helper to pause everything
  Future<void> _pauseAll() async {
    print("PauseAll: Stopping everything.");
    if (_videoController!.value.isPlaying) await _videoController!.pause();
    await _pauseAudio();
  }

  /// Update caption overlay logic
  void _updateCaptions(Duration currentPos) {
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
      } catch (e) {}
      return Duration.zero;
    }

    for (var caption in _captions) {
      final start = parseTime(caption.start);
      final end = parseTime(caption.end);

      if (currentPos >= start && currentPos < end) {
        text = caption.text;
        words = caption.words.map((w) => w.word).toList();
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

    // Auto-play when seeking via caption? Maybe.
    // For now, let's respect the current state or force play.
    _isPlaying = true;
    await _videoController!.play();
    notifyListeners();
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
  List<VoiceoverSegment> _voiceoverSegments = [];
  Duration? _recordingStartVideoPos;

  bool get isVoiceoverMode => _isVoiceoverMode;
  bool get isRecording => _isRecording;
  List<VoiceoverSegment> get voiceoverSegments => _voiceoverSegments;

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

  Future<void> startRecording() async {
    if (_videoController == null) return;

    try {
      // 1. Ensure clean state
      _isPlaying = false;
      await _pauseAll();

      // 2. Start Recorder
      await _voiceoverService.startRecording();
      _isRecording = true;
      _recordingStartVideoPos = _videoController!.value.position;

      // 3. Start Video Playback (Auto-play for context)
      _isPlaying = true;
      await _videoController!.play();

      notifyListeners();
    } catch (e) {
      print('Error starting recording: $e');
      _statusMessage = 'Error starting recording';
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      print("Stopping recording...");

      // 1. Stop Recorder
      final path = await _voiceoverService.stopRecording();

      // 2. Stop Playback
      _isPlaying = false;
      await _pauseAll();
      _isRecording = false;

      print("Recording stopped. Path: $path");

      if (path != null && _recordingStartVideoPos != null) {
        // Calculate duration based on video progress
        final endVideoPos = _videoController!.value.position;
        final duration = endVideoPos - _recordingStartVideoPos!;

        // Guard against zero duration
        if (duration > Duration.zero) {
          final segment = VoiceoverSegment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            filePath: path,
            videoStart: _recordingStartVideoPos!,
            sourceStart: Duration.zero,
            sourceEnd: duration,
          );

          _voiceoverSegments.add(segment);
          _voiceoverSegments
              .sort((a, b) => a.videoStart.compareTo(b.videoStart));
        }
      }

      _recordingStartVideoPos = null;
      notifyListeners();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void deleteSegment(String id) {
    _voiceoverSegments.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void splitSegment(String id, Duration splitPoint) {
    final index = _voiceoverSegments.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final original = _voiceoverSegments[index];

    // splitPoint is relative to the segment start in the video timeline?
    // Or absolute video time? Let's assume absolute video time for easier UI integration.

    if (splitPoint <= original.videoStart || splitPoint >= original.videoEnd) {
      return; // Invalid split point
    }

    final relativeSplit = splitPoint - original.videoStart;
    final sourceSplit = original.sourceStart + relativeSplit;

    final segmentA = VoiceoverSegment(
      id: '${original.id}_a',
      filePath: original.filePath,
      videoStart: original.videoStart,
      sourceStart: original.sourceStart,
      sourceEnd: sourceSplit,
    );

    final segmentB = VoiceoverSegment(
      id: '${original.id}_b',
      filePath: original.filePath,
      videoStart: splitPoint,
      sourceStart: sourceSplit,
      sourceEnd: original.sourceEnd,
    );

    _voiceoverSegments.removeAt(index);
    _voiceoverSegments.insert(index, segmentA);
    _voiceoverSegments.insert(index + 1, segmentB);
    notifyListeners();
  }

  void updateSegment(VoiceoverSegment updatedSegment) {
    final index =
        _voiceoverSegments.indexWhere((s) => s.id == updatedSegment.id);
    if (index != -1) {
      _voiceoverSegments[index] = updatedSegment;
      // Sort segments by start time to keep timeline ordered
      _voiceoverSegments.sort((a, b) => a.videoStart.compareTo(b.videoStart));
      notifyListeners();
    }
  }

  void clearAllVoiceovers() {
    _voiceoverSegments.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    _voiceoverService.dispose(); // Add new dispose for voiceover service
    super.dispose();
  }
}
