import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import '../../viewmodels/video_viewmodel.dart';
import '../../core/constants/app_constants.dart';

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.chewieController == null) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'No video selected',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Stack(
          children: [
            // Video Player
            Chewie(controller: viewModel.chewieController!),

            // Play/Pause Overlay
            if (viewModel.videoController != null &&
                !viewModel.videoController!.value.isPlaying)
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 50,
                ),
              ),

            // Caption Overlay
            if (viewModel.currentCaptionText.isNotEmpty)
              Positioned(
                bottom: AppConstants.captionBottomPadding,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: viewModel.currentCaptionWords.isNotEmpty
                        ? RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: AppConstants.captionFontSize,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                              children: [
                                for (int i = 0;
                                    i < viewModel.currentCaptionWords.length;
                                    i++)
                                  TextSpan(
                                    text:
                                        '${viewModel.currentCaptionWords[i]} ',
                                    style: TextStyle(
                                      color: i < viewModel.highlightedWordCount
                                          ? Colors.yellow
                                          : Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Text(
                            viewModel.currentCaptionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppConstants.captionFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
