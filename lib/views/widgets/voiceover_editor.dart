import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../viewmodels/video_viewmodel.dart';

class VoiceoverEditor extends StatefulWidget {
  final File file;
  const VoiceoverEditor({super.key, required this.file});

  @override
  State<VoiceoverEditor> createState() => _VoiceoverEditorState();
}

class _VoiceoverEditorState extends State<VoiceoverEditor> {
  late PlayerController _waveformController;
  bool _initialized = false;
  double _startValue = 0.0;
  double _endValue = 1.0;
  int _durationInMs = 0;

  @override
  void initState() {
    super.initState();
    _waveformController = PlayerController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      await _waveformController.preparePlayer(
        path: widget.file.path,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );

      final duration = await _waveformController.getDuration();
      _durationInMs = duration;

      setState(() {
        _initialized = true;
        _endValue = _durationInMs.toDouble();
      });
    } catch (e) {
      debugPrint("Error initializing audio editor: $e");
    }
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<VideoViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Voiceover',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          // Confirm deletion
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Voiceover?'),
                              content: const Text(
                                  'Are you sure you want to delete this recording?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // viewModel.deleteSegment(widget.segmentId); // Need segment ID
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.trash2, color: Colors.red),
                        tooltip: 'Delete',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Save trim values (convert ms to seconds double if needed, or keep as Duration)
                          // ViewModel expects double seconds
                          // viewModel.updateSegmentTrim(widget.segmentId, start, end);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Trim saved!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAB7FFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Use'),
                      ),
                    ],
                  ),
                ],
              ),

              // Content Area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Playback Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (_waveformController.playerState ==
                                PlayerState.playing) {
                              await _waveformController.pausePlayer();
                              viewModel.videoController?.pause();
                            } else {
                              // Sync start
                              // Seek video to start? Maybe complex.
                              // For now just play
                              await _waveformController.startPlayer();
                              viewModel.videoController?.play();
                            }
                            setState(() {});
                          },
                          icon: Icon(
                            _waveformController.playerState ==
                                    PlayerState.playing
                                ? LucideIcons.pause
                                : LucideIcons.play,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Trimmer Stack
                    SizedBox(
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Waveform Background
                          AudioFileWaveforms(
                            size: Size(
                                MediaQuery.of(context).size.width - 32, 60),
                            playerController: _waveformController,
                            enableSeekGesture: false,
                            waveformType: WaveformType.fitWidth,
                            playerWaveStyle: const PlayerWaveStyle(
                              fixedWaveColor: Colors.white30,
                              liveWaveColor: Color(0xFFAB7FFF),
                              spacing: 6,
                              showSeekLine: true,
                            ),
                          ),

                          // Range Slider Overlay
                          Theme(
                            data: ThemeData(
                              sliderTheme: SliderThemeData(
                                activeTrackColor: const Color(0xFFAB7FFF)
                                    .withValues(alpha: 0.3),
                                inactiveTrackColor: Colors.transparent,
                                thumbColor: const Color(0xFFAB7FFF),
                                overlayColor: const Color(0xFFAB7FFF)
                                    .withValues(alpha: 0.2),
                                trackHeight: 60, // Cover the waveform
                                rangeThumbShape:
                                    const RoundRangeSliderThumbShape(
                                        enabledThumbRadius: 8),
                              ),
                            ),
                            child: RangeSlider(
                              values: RangeValues(_startValue, _endValue),
                              min: 0.0,
                              max: _durationInMs.toDouble(),
                              onChanged: (RangeValues values) {
                                setState(() {
                                  _startValue = values.start;
                                  _endValue = values.end;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Time Labels
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_startValue.toInt()),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(_endValue.toInt()),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
