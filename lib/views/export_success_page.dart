import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ExportSuccessPage extends StatefulWidget {
  final String filePath;

  const ExportSuccessPage({super.key, required this.filePath});

  @override
  State<ExportSuccessPage> createState() => _ExportSuccessPageState();
}

class _ExportSuccessPageState extends State<ExportSuccessPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.file(File(widget.filePath));
    await _videoController!.initialize();
    
    _videoController!.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _videoController!.value.isPlaying;
          _isMuted = _videoController!.value.volume == 0;
        });
      }
    });

    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoController!.value.aspectRatio,
        showControls: false, // Minimal controls for preview
      );
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _shareVideo() {
    Share.shareXFiles([XFile(widget.filePath)], text: 'Created with PP Captions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Success Animation/Icon
            const Icon(
              LucideIcons.checkCircle,
              color: Color(0xFFAB7FFF),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video Saved to Gallery!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Video Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _chewieController != null
                    ? Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Chewie(controller: _chewieController!),
                          // Custom Controls Overlay
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isPlaying ? LucideIcons.pause : LucideIcons.play,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    if (_isPlaying) {
                                      _videoController!.pause();
                                    } else {
                                      _videoController!.play();
                                    }
                                  },
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(
                                    _isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _videoController!.setVolume(_isMuted ? 1.0 : 0.0);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),

            const SizedBox(height: 32),

            // Share Options
            const Text(
              'Share video to',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShareButton(LucideIcons.instagram, Colors.pinkAccent),
                const SizedBox(width: 20),
                _buildShareButton(LucideIcons.youtube, Colors.redAccent),
                const SizedBox(width: 20),
                _buildShareButton(LucideIcons.facebook, Colors.blue),
                const SizedBox(width: 20),
                _buildShareButton(LucideIcons.share2, Colors.white),
              ],
            ),

            const SizedBox(height: 40),
            
            // Home Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(IconData icon, Color color) {
    return InkWell(
      onTap: _shareVideo,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2A2A2A),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

