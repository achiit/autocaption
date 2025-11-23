import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ExamplesPage extends StatefulWidget {
  const ExamplesPage({super.key});

  @override
  State<ExamplesPage> createState() => _ExamplesPageState();
}

class _ExamplesPageState extends State<ExamplesPage> {
  final List<Map<String, String>> examples = [
    {
      'title': 'Classic Style',
      'description': 'Yellow highlights, dark background',
      'video': 'assets/videos/output_classic.mp4',
      'color': '0xFFFFD700',
    },
    {
      'title': 'Neon Glow',
      'description': 'Cyan glow effect, futuristic',
      'video': 'assets/videos/output_neon.mp4',
      'color': '0xFF00FFFF',
    },
    {
      'title': 'Bold Pop',
      'description': 'Red highlights, bold stroke',
      'video': 'assets/videos/output_bold.mp4',
      'color': '0xFFFF4444',
    },
    {
      'title': 'Minimal Clean',
      'description': 'Clean white background',
      'video': 'assets/videos/output_minimal.mp4',
      'color': '0xFFFFFFFF',
    },
    {
      'title': 'Gradient Style',
      'description': 'Purple gradient, gold accents',
      'video': 'assets/videos/output_gradient.mp4',
      'color': '0xFFAB7FFF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Caption Examples',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Title
            const Text(
              'See It in Action',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Watch how different caption styles transform your videos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 32),

            // Example Cards
            ...examples
                .map((example) => Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: _buildExampleCard(
                        title: example['title']!,
                        description: example['description']!,
                        videoPath: example['video']!,
                        accentColor: Color(int.parse(example['color']!)),
                      ),
                    ))
                .toList(),

            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFAB7FFF), Color(0xFF8B5FDF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap any video to play and see the captions in action!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard({
    required String title,
    required String description,
    required String videoPath,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to video player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoPath: videoPath,
              title: title,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail placeholder with play icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: accentColor,
                    size: 48,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to watch',
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Simple video player screen
class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  File? _tempFile;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Check if it's a network URL
      if (widget.videoPath.startsWith('http://') ||
          widget.videoPath.startsWith('https://')) {
        _controller = VideoPlayerController.network(widget.videoPath);
      }
      // Check if it's an asset
      else if (widget.videoPath.startsWith('assets/')) {
        // Copy asset to temp file (Android video_player doesn't work well with assets)
        final assetPath = widget.videoPath.replaceFirst('assets/', '');
        final byteData = await rootBundle.load(assetPath);
        final tempDir = await getTemporaryDirectory();
        final fileName = widget.videoPath.split('/').last;
        _tempFile = File('${tempDir.path}/$fileName');
        await _tempFile!.writeAsBytes(byteData.buffer.asUint8List());
        _controller = VideoPlayerController.file(_tempFile!);
      }
      // Otherwise it's a file path
      else {
        _controller = VideoPlayerController.file(File(widget.videoPath));
      }

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    // Clean up temp file if it exists
    if (_tempFile != null) {
      try {
        _tempFile!.deleteSync();
      } catch (_) {
        // Ignore deletion errors
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: _isInitialized && _controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : const CircularProgressIndicator(
                color: Color(0xFFAB7FFF),
              ),
      ),
      floatingActionButton: _isInitialized && _controller != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              backgroundColor: const Color(0xFFAB7FFF),
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
