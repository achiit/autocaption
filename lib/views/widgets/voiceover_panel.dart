import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/video_viewmodel.dart';
import 'voiceover_timeline.dart';
import 'voiceover_editor.dart';

class VoiceoverPanel extends StatelessWidget {
  const VoiceoverPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300, // Fixed height for stability
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Consumer<VideoViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.recordedAudioPath != null) {
            return VoiceoverEditor(file: File(viewModel.recordedAudioPath!));
          } else {
            return const VoiceoverTimeline();
          }
        },
      ),
    );
  }
}
