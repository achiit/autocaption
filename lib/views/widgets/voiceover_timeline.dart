import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../viewmodels/video_viewmodel.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class VoiceoverTimeline extends StatefulWidget {
  const VoiceoverTimeline({super.key});

  @override
  State<VoiceoverTimeline> createState() => _VoiceoverTimelineState();
}

class _VoiceoverTimelineState extends State<VoiceoverTimeline> {
  late PlayerController _playerController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _preparePlayer(String path) async {
    if (_playerController.playerState == PlayerState.stopped) {
      await _playerController.preparePlayer(
        path: path,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoViewModel>(
      builder: (context, viewModel, child) {
        // If we have a recording, prepare the player
        if (viewModel.recordedAudioPath != null &&
            !_isPlaying &&
            _playerController.playerState == PlayerState.stopped) {
          _preparePlayer(viewModel.recordedAudioPath!);
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Column(
            children: [
              Text(
                viewModel.isRecording
                    ? 'Recording...'
                    : (viewModel.recordedAudioPath != null
                        ? 'Voiceover Recorded'
                        : 'Voiceover Timeline'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Waveform Area
              Expanded(
                child: Center(
                  child: viewModel.isRecording
                      ? AudioWaveforms(
                          enableGesture: false,
                          size:
                              Size(MediaQuery.of(context).size.width - 40, 60),
                          recorderController: viewModel.recorderController,
                          waveStyle: const WaveStyle(
                            waveColor: Colors.redAccent,
                            extendWaveform: true,
                            showMiddleLine: false,
                          ),
                        )
                      : (viewModel.recordedAudioPath != null
                          ? AudioFileWaveforms(
                              size: Size(
                                  MediaQuery.of(context).size.width - 40, 60),
                              playerController: _playerController,
                              enableSeekGesture: true,
                              waveformType: WaveformType.fitWidth,
                              playerWaveStyle: const PlayerWaveStyle(
                                fixedWaveColor: Colors.white30,
                                liveWaveColor: Color(0xFFAB7FFF),
                                spacing: 6,
                              ),
                            )
                          : const Text(
                              'Tap record to start',
                              style: TextStyle(color: Colors.white30),
                            )),
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              if (viewModel.recordedAudioPath == null)
                // Record Button
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (viewModel.isRecording) {
                        viewModel.stopRecording();
                      } else {
                        viewModel.startRecording();
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            viewModel.isRecording ? Colors.white : Colors.red,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Icon(
                          viewModel.isRecording
                              ? LucideIcons.square
                              : LucideIcons.mic,
                          color:
                              viewModel.isRecording ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                          _isPlaying ? LucideIcons.pause : LucideIcons.play),
                      color: Colors.white,
                      onPressed: () async {
                        if (_isPlaying) {
                          await _playerController.pausePlayer();
                          setState(() => _isPlaying = false);
                        } else {
                          await _playerController.startPlayer();
                          setState(() => _isPlaying = true);
                          _playerController.onCompletion.listen((_) {
                            if (mounted) setState(() => _isPlaying = false);
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2),
                      color: Colors.red,
                      onPressed: () {
                        viewModel.deleteRecording();
                        _playerController.stopPlayer();
                        setState(() => _isPlaying = false);
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
