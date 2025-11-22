import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart'; // For mime type detection
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const String apiKey = 'AIzaSyBCEfSwzZLu8aFN3iq7xz4_gjGZ58XChEU';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Caption',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final ImagePicker _picker = ImagePicker();

  String _selectedLanguage = 'English';
  final List<String> _languages = [
    "English",
    "Hindi",
    "Spanish",
    "French",
    "Hinglish",
  ];

  List<Map<String, dynamic>> _captions = [];
  bool _isProcessing = false;
  String _statusMessage = '';

  // Aspect Ratio
  double _aspectRatio = 9 / 16; // Default to 9:16
  String _aspectRatioName = "9:16";

  // Current Caption for Overlay
  String _currentCaptionText = "";
  List<String> _currentCaptionWords = [];
  int _highlightedWordCount = 0;

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    File file = File(video.path);

    // Initialize player
    await _initializePlayer(file);

    // Start processing
    await _processVideo(file);
  }

  Future<void> _initializePlayer(File file) async {
    _videoController?.dispose();
    _chewieController?.dispose();

    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      aspectRatio: _aspectRatio,
      autoPlay: false,
      looping: false,
    );

    _videoController!.addListener(_updateCaptionOverlay);

    setState(() {});
  }

  Future<void> _processVideo(File file) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Uploading video...';
      _captions = [];
    });

    try {
      // 1. Upload
      String? fileUri = await _uploadToGemini(file);
      if (fileUri == null) throw Exception("Upload failed");

      // 2. Poll for ACTIVE state
      setState(() => _statusMessage = 'Processing video...');
      await _pollFileState(fileUri);

      // 3. Generate Captions
      setState(
        () => _statusMessage = 'Generating captions in $_selectedLanguage...',
      );
      await _generateCaptions(fileUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
    }
  }

  // --- Gemini File API (REST) ---

  Future<String?> _uploadToGemini(File file) async {
    int fileSize = await file.length();
    String? mimeType = lookupMimeType(file.path) ?? 'video/mp4';
    String displayName = file.path.split('/').last;

    // 1. Start Resumable Upload
    final startUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/upload/v1beta/files?key=$apiKey',
    );
    final startResponse = await http.post(
      startUrl,
      headers: {
        'X-Goog-Upload-Protocol': 'resumable',
        'X-Goog-Upload-Command': 'start',
        'X-Goog-Upload-Header-Content-Length': fileSize.toString(),
        'X-Goog-Upload-Header-Content-Type': mimeType,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'file': {'display_name': displayName},
      }),
    );

    if (startResponse.statusCode != 200) {
      print('Start upload failed: ${startResponse.body}');
      return null;
    }

    final uploadUrl = startResponse.headers['x-goog-upload-url'];
    if (uploadUrl == null) return null;

    // 2. Upload Bytes
    // Note: For very large files, we should stream. For this demo, we'll read bytes.
    // If file is huge, this might crash on mobile. But for demo purposes:
    final bytes = await file.readAsBytes();

    final uploadResponse = await http.post(
      Uri.parse(uploadUrl),
      headers: {
        'X-Goog-Upload-Protocol': 'resumable',
        'X-Goog-Upload-Command': 'upload, finalize',
        'X-Goog-Upload-Offset': '0',
        'Content-Length': fileSize.toString(),
      },
      body: bytes,
    );

    if (uploadResponse.statusCode != 200) {
      print('Upload failed: ${uploadResponse.body}');
      return null;
    }

    final json = jsonDecode(uploadResponse.body);
    return json['file']['uri'];
  }

  Future<void> _pollFileState(String fileUri) async {
    // fileUri is like https://generativelanguage.googleapis.com/v1beta/files/NAME
    // We need to extract the name or just use the URI if the SDK/API expects that.
    // The REST API to get file is GET https://generativelanguage.googleapis.com/v1beta/files/NAME?key=KEY

    // The uri returned from upload is usually the full resource URI.
    // Let's parse the name from it if needed, or just append key.
    // Example URI: https://generativelanguage.googleapis.com/v1beta/files/c44...

    final uriWithKey = Uri.parse('$fileUri?key=$apiKey');

    while (true) {
      final response = await http.get(uriWithKey);
      if (response.statusCode != 200)
        throw Exception("Failed to check file state");

      final json = jsonDecode(response.body);
      final state = json['state']; // e.g., PROCESSING, ACTIVE, FAILED

      if (state == 'ACTIVE') {
        break;
      } else if (state == 'FAILED') {
        throw Exception("Video processing failed");
      }

      await Future.delayed(const Duration(seconds: 2));
    }
  }

  // --- Gemini Generation ---

  Future<void> _generateCaptions(String fileUri) async {
    final model = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);

    String languagePrompt = _selectedLanguage;
    if (_selectedLanguage == 'Hinglish') {
      languagePrompt =
          "Hindi speech transcribed using English characters (Hinglish)";
    }

    final prompt =
        "Analyze the audio in this video and generate a transcript in $languagePrompt. "
        "You MUST return the output as a raw JSON list with no markdown formatting. "
        "The JSON objects must represent caption segments and have the following structure: "
        "{'text': 'Full segment text', 'start': 'MM:SS:mmm', 'end': 'MM:SS:mmm', "
        "'words': [{'word': 'Word', 'start': 'MM:SS:mmm', 'end': 'MM:SS:mmm'}, ...]}. "
        "Ensure 'start' and 'end' are in 'MM:SS:mmm' format (e.g., 00:01:500). "
        "Keep segments short (3-5 words). "
        "Example: [{'text': 'Hello world', 'start': '00:00:000', 'end': '00:01:000', 'words': [{'word': 'Hello', 'start': '00:00:000', 'end': '00:00:500'}, {'word': 'world', 'start': '00:00:500', 'end': '00:01:000'}]}]";

    // We can pass the file URI directly to the SDK if we construct the Content correctly.
    // The SDK supports FilePart with a URI.
    final content = [
      Content.multi([
        TextPart(prompt),
        FilePart(Uri.parse(fileUri)), // Using FilePart with the URI
      ]),
    ];

    final response = await model.generateContent(content);
    final text = response.text;

    if (text == null) throw Exception("No response from Gemini");

    // Clean up potential markdown code blocks if Gemini ignores "no markdown"
    String cleanText =
        text.replaceAll('```json', '').replaceAll('```', '').trim();

    try {
      final List<dynamic> jsonList = jsonDecode(cleanText);
      setState(() {
        _captions = jsonList.map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      print("JSON Parse Error: $text");
      throw Exception("Failed to parse captions");
    }
  }

  void _seekTo(String timestamp) {
    if (_videoController == null) return;

    final parts = timestamp.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      _videoController!.seekTo(Duration(minutes: minutes, seconds: seconds));
      _videoController!.play();
    }
  }

  void _updateCaptionOverlay() {
    if (_videoController == null || !_videoController!.value.isPlaying) return;

    final currentPos = _videoController!.value.position;
    String text = "";
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
        // Fallback or silent fail
      }
      return Duration.zero;
    }

    for (var caption in _captions) {
      final startStr = caption['start'] as String;
      final endStr = caption['end'] as String;

      final start = parseTime(startStr);
      final end = parseTime(endStr);

      if (currentPos >= start && currentPos < end) {
        text = caption['text'];

        // Process words for highlighting
        if (caption.containsKey('words')) {
          final wordList = caption['words'] as List<dynamic>;
          words = wordList.map((w) => w['word'] as String).toList();

          for (int i = 0; i < wordList.length; i++) {
            final w = wordList[i];
            final wStart = parseTime(w['start']);

            if (currentPos >= wStart) {
              highlightedCount = i + 1;
            }
          }
        } else {
          // Fallback if 'words' missing
          words = text.split(' ');
        }
        break;
      }
    }

    if (_currentCaptionText != text ||
        _highlightedWordCount != highlightedCount) {
      setState(() {
        _currentCaptionText = text;
        _currentCaptionWords = words;
        _highlightedWordCount = highlightedCount;
      });
    }
  }

  Future<void> _exportVideo() async {
    if (_captions.isEmpty || _videoController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No captions to export or video not loaded")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = "Preparing export...";
    });

    try {
      // 1. Create SRT file
      final directory = await getTemporaryDirectory();
      final srtFile = File('${directory.path}/captions.srt');
      String srtContent = "";

      for (int i = 0; i < _captions.length; i++) {
        final caption = _captions[i];
        final startStr = caption['start'] as String;
        final endStr = caption['end'] as String;

        // Helper to parse MM:SS
        Duration parseTime(String t) {
          final parts = t.split(':');
          final minutes = int.parse(parts[0]);
          final seconds = int.parse(parts[1]);
          return Duration(minutes: minutes, seconds: seconds);
        }

        final startDuration = parseTime(startStr);
        final endDuration = parseTime(endStr);

        String formatDuration(Duration d) {
          String twoDigits(int n) => n.toString().padLeft(2, "0");
          String threeDigits(int n) => n.toString().padLeft(3, "0");
          return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))},${threeDigits(d.inMilliseconds.remainder(1000))}";
        }

        srtContent += "${i + 1}\n";
        srtContent +=
            "${formatDuration(startDuration)} --> ${formatDuration(endDuration)}\n";
        srtContent += "${caption['text']}\n\n";
      }

      await srtFile.writeAsString(srtContent);

      // 2. FFmpeg Command
      // Scale video to aspect ratio (adding black bars if needed) and burn subtitles
      // This is complex. For simplicity, we will just burn subtitles on original video
      // and maybe scale if strictly required. The user asked for specific canvas size.

      final videoPath = _videoController!.dataSource;
      final outputPath = '${directory.path}/output.mp4';
      final outputVideo = File(outputPath);
      if (await outputVideo.exists()) await outputVideo.delete();

      // Escape path for FFmpeg
      // Note: FFmpegKit handles paths better, but complex filters need care.
      // Using simple subtitle burn for now.
      // To force aspect ratio, we use pad filter.

      String filter = "subtitles='${srtFile.path}'";
      if (_aspectRatioName == "9:16") {
        // Force 9:16 (e.g., 720x1280)
        // scale=-1:1280,pad=720:1280:(ow-iw)/2:(oh-ih)/2
        // This might be too heavy for mobile if resolution is high.
        // Let's just burn subtitles for MVP or user might complain about slow export.
        // User specifically asked: "put it on the screen on the bottom center"
        // The subtitle filter does that by default.
        // Let's try to respect the aspect ratio request by padding.
        filter =
            "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2,subtitles='${srtFile.path}':force_style='Alignment=2,FontSize=24'";
      } else {
        // 16:9 (e.g., 1280x720)
        filter =
            "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,subtitles='${srtFile.path}':force_style='Alignment=2,FontSize=24'";
      }

      setState(
          () => _statusMessage = "Exporting video (this may take a while)...");

      // -y overwrite
      final command =
          "-i '$videoPath' -vf \"$filter\" -c:v libx264 -preset ultrafast -c:a copy -y '$outputPath'";

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          await Share.shareXFiles([XFile(outputPath)],
              text: "Here is your captioned video!");
        } else {
          final logs = await session.getAllLogsAsString();
          throw Exception("FFmpeg failed: $logs");
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Export Error: $e")));
      }
    } finally {
      setState(() {
        _isProcessing = false;
        _statusMessage = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Caption AI')),
      body: Column(
        children: [
          // Top: Video Player with Overlay
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: Container(
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : const Center(
                            child: Icon(
                              Icons.video_library,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                    // Caption Overlay
                    if (_currentCaptionText.isNotEmpty)
                      Positioned(
                        bottom: 40,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _currentCaptionWords.isNotEmpty
                              ? RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                    children: [
                                      for (int i = 0;
                                          i < _currentCaptionWords.length;
                                          i++)
                                        TextSpan(
                                          text: "${_currentCaptionWords[i]} ",
                                          style: TextStyle(
                                            color: i < _highlightedWordCount
                                                ? Colors.yellow
                                                : Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              : Text(
                                  _currentCaptionText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Aspect Ratio Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Canvas: "),
                DropdownButton<String>(
                  value: _aspectRatioName,
                  items: ["9:16", "16:9"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: _isProcessing
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _aspectRatioName = val;
                              _aspectRatio = val == "9:16" ? 9 / 16 : 16 / 9;
                              // Re-initialize player to update aspect ratio
                              if (_videoController != null) {
                                _initializePlayer(
                                    File(_videoController!.dataSource));
                              }
                            });
                          }
                        },
                ),
                const Spacer(),
                if (_captions.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _exportVideo,
                    icon: const Icon(Icons.share),
                    label: const Text("Export"),
                  ),
              ],
            ),
          ),

          // Middle: Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    items: _languages.map((String lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: _isProcessing
                        ? null
                        : (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedLanguage = newValue;
                              });
                            }
                          },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickVideo,
                  icon: const Icon(Icons.video_file),
                  label: const Text('Pick Video'),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(_statusMessage),
                ],
              ),
            ),

          // Bottom: Captions List
          Expanded(
            child: _captions.isEmpty
                ? const Center(child: Text('No captions generated yet.'))
                : ListView.builder(
                    itemCount: _captions.length,
                    itemBuilder: (context, index) {
                      final item = _captions[index];
                      return ListTile(
                        leading: Text(
                          item['timestamp'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(item['text'] ?? ''),
                        onTap: () => _seekTo(item['timestamp']),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
