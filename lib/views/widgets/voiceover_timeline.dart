import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import '../../viewmodels/video_viewmodel.dart';
import '../../models/voiceover_segment.dart';
import 'voiceover_segment_widget.dart';

class VoiceoverTimeline extends StatefulWidget {
  const VoiceoverTimeline({super.key});

  @override
  State<VoiceoverTimeline> createState() => _VoiceoverTimelineState();
}

class _VoiceoverTimelineState extends State<VoiceoverTimeline> {
  final ScrollController _scrollController = ScrollController();
  double _pixelsPerSecond = 50.0; // Zoom level
  String? _selectedSegmentId;
  VideoPlayerController? _listeningController;
  bool _isAutoScrolling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = Provider.of<VideoViewModel>(context);
    if (_listeningController != viewModel.videoController) {
      _listeningController?.removeListener(_onScrollTick);
      _listeningController = viewModel.videoController;
      _listeningController?.addListener(_onScrollTick);
    }
  }

  @override
  void dispose() {
    _listeningController?.removeListener(_onScrollTick);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollTick() async {
    if (_listeningController == null || !_listeningController!.value.isPlaying)
      return;
    if (!_scrollController.hasClients) return;
    if (_isAutoScrolling) return; // Don't interrupt existing scroll

    final currentPos = _listeningController!.value.position.inMilliseconds /
        1000 *
        _pixelsPerSecond;
    final viewportWidth = _scrollController.position.viewportDimension;
    final currentScroll = _scrollController.offset;

    // Debug log (remove later)
    // print("ScrollTick: Pos=$currentPos, Scroll=$currentScroll, Viewport=$viewportWidth");

    // If playhead moves past 80% of the screen, scroll forward
    if (currentPos > currentScroll + viewportWidth * 0.8) {
      print("AutoScroll: Scrolling forward...");
      _isAutoScrolling = true;
      final target =
          currentPos - viewportWidth * 0.2; // Move it back to 20% mark

      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _isAutoScrolling = false;
    }
    // If playhead is behind scroll (e.g. seek back), jump to it
    else if (currentPos < currentScroll) {
      _scrollController.jumpTo(currentPos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoViewModel>(
      builder: (context, viewModel, child) {
        final duration =
            viewModel.videoController?.value.duration ?? Duration.zero;
        final totalWidth = duration.inSeconds * _pixelsPerSecond;

        // Auto-scroll logic could go here

        return Container(
          height: 300,
          color: const Color(0xFF1A1A1A),
          child: Column(
            children: [
              // Toolbar
              _buildToolbar(viewModel),

              // Timeline Area
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth +
                        MediaQuery.of(context).size.width /
                            2, // Extra space at end
                    child: Stack(
                      children: [
                        // 1. Ruler
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 30,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (details) {
                              final seekTime = Duration(
                                  milliseconds: ((details.localPosition.dx /
                                              _pixelsPerSecond) *
                                          1000)
                                      .toInt());
                              viewModel.videoController?.seekTo(seekTime);
                            },
                            child: _buildRuler(duration),
                          ),
                        ),

                        // 2. Video Track (Placeholder for thumbnails)
                        Positioned(
                          top: 30,
                          left: 0,
                          right: 0,
                          height: 60,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (details) {
                              final seekTime = Duration(
                                  milliseconds: ((details.localPosition.dx /
                                              _pixelsPerSecond) *
                                          1000)
                                      .toInt());
                              viewModel.videoController?.seekTo(seekTime);
                            },
                            child: Container(
                              color: Colors.white10,
                              alignment: Alignment.center,
                              child: const Text('Video Track',
                                  style: TextStyle(color: Colors.white30)),
                            ),
                          ),
                        ),

                        // 3. Audio Track
                        Positioned(
                          top: 100,
                          left: 0,
                          right: 0,
                          height: 80,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (details) {
                              final seekTime = Duration(
                                  milliseconds: ((details.localPosition.dx /
                                              _pixelsPerSecond) *
                                          1000)
                                      .toInt());
                              viewModel.videoController?.seekTo(seekTime);
                            },
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.05),
                              child: Stack(
                                children:
                                    viewModel.voiceoverSegments.map((segment) {
                                  final left =
                                      (segment.videoStart.inMilliseconds /
                                              1000) *
                                          _pixelsPerSecond;
                                  final width =
                                      (segment.duration.inMilliseconds / 1000) *
                                          _pixelsPerSecond;

                                  return Positioned(
                                    left: left,
                                    top: 15,
                                    child: VoiceoverSegmentWidget(
                                      segment: segment,
                                      width: width,
                                      isSelected:
                                          _selectedSegmentId == segment.id,
                                      onTap: () {
                                        setState(() {
                                          _selectedSegmentId = segment.id;
                                        });
                                      },
                                      onDragStart: (_) {},
                                      onDragUpdate: (dx) {
                                        // Move segment
                                        final dt = Duration(
                                            milliseconds:
                                                ((dx / _pixelsPerSecond) * 1000)
                                                    .toInt());
                                        final newStart =
                                            segment.videoStart + dt;
                                        if (newStart >= Duration.zero) {
                                          final updated = segment.copyWith(
                                              videoStart: newStart);
                                          viewModel.updateSegment(updated);
                                        }
                                      },
                                      onDragEnd: (_) {},
                                      onTrimStart: (dx) {
                                        // Trim start (adjust videoStart and sourceStart)
                                        final dt = Duration(
                                            milliseconds:
                                                ((dx / _pixelsPerSecond) * 1000)
                                                    .toInt());
                                        final newVideoStart =
                                            segment.videoStart + dt;
                                        final newSourceStart =
                                            segment.sourceStart + dt;

                                        if (newVideoStart < segment.videoEnd &&
                                            newSourceStart >= Duration.zero) {
                                          final updated = segment.copyWith(
                                            videoStart: newVideoStart,
                                            sourceStart: newSourceStart,
                                          );
                                          viewModel.updateSegment(updated);
                                        }
                                      },
                                      onTrimEnd: (dx) {
                                        // Trim end (adjust sourceEnd)
                                        final dt = Duration(
                                            milliseconds:
                                                ((dx / _pixelsPerSecond) * 1000)
                                                    .toInt());
                                        final newSourceEnd =
                                            segment.sourceEnd + dt;

                                        if (newSourceEnd >
                                            segment.sourceStart) {
                                          final updated = segment.copyWith(
                                              sourceEnd: newSourceEnd);
                                          viewModel.updateSegment(updated);
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),

                        // 4. Playhead
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: ValueListenableBuilder(
                            valueListenable: viewModel.videoController!,
                            builder: (context, value, child) {
                              final position = value.position.inMilliseconds /
                                  1000 *
                                  _pixelsPerSecond;
                              return Transform.translate(
                                offset: Offset(position, 0),
                                child: Container(
                                  width: 2,
                                  color: Colors.white,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(VideoViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
                viewModel.isRecording ? LucideIcons.square : LucideIcons.mic),
            color: viewModel.isRecording ? Colors.red : Colors.white,
            onPressed: () {
              if (viewModel.isRecording) {
                viewModel.stopRecording();
              } else {
                viewModel.startRecording();
              }
            },
          ),
          const SizedBox(width: 16),
          // Play/Pause Button
          IconButton(
            icon: Icon(
              viewModel.isPlaying ? LucideIcons.pause : LucideIcons.play,
            ),
            color: Colors.white,
            onPressed: () {
              viewModel.togglePlayback();
            },
          ),
          const SizedBox(width: 16),
          // Split Button
          IconButton(
            icon: const Icon(LucideIcons.scissors),
            color: Colors.white,
            onPressed: () {
              final position = viewModel.videoController?.value.position;
              if (position != null) {
                // Find segment under playhead
                final segment = viewModel.voiceoverSegments.firstWhere(
                  (s) => s.videoStart <= position && s.videoEnd >= position,
                  orElse: () => VoiceoverSegment(
                      id: 'dummy',
                      filePath: '',
                      videoStart: Duration.zero,
                      sourceStart: Duration.zero,
                      sourceEnd: Duration.zero),
                );

                if (segment.id != 'dummy') {
                  viewModel.splitSegment(segment.id, position);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No segment at playhead to split')),
                  );
                }
              }
            },
          ),
          const Spacer(),
          if (_selectedSegmentId != null)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red),
              onPressed: () {
                viewModel.deleteSegment(_selectedSegmentId!);
                setState(() => _selectedSegmentId = null);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRuler(Duration duration) {
    return CustomPaint(
      painter: RulerPainter(
        duration: duration,
        pixelsPerSecond: _pixelsPerSecond,
      ),
      size: Size.infinite,
    );
  }
}

class RulerPainter extends CustomPainter {
  final Duration duration;
  final double pixelsPerSecond;

  RulerPainter({required this.duration, required this.pixelsPerSecond});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i <= duration.inSeconds; i++) {
      final x = i * pixelsPerSecond;

      // Major tick
      canvas.drawLine(Offset(x, 0), Offset(x, 15), paint);

      // Time label
      final time = Duration(seconds: i);
      final minutes = time.inMinutes.remainder(60).toString().padLeft(1, '0');
      final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');

      textPainter.text = TextSpan(
        text: '$minutes:$seconds',
        style: const TextStyle(color: Colors.white54, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, 18));

      // Minor ticks
      for (int j = 1; j < 5; j++) {
        final minorX = x + (j * (pixelsPerSecond / 5));
        canvas.drawLine(Offset(minorX, 0), Offset(minorX, 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
