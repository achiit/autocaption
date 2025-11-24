import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.video, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No video selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final video =
                            await picker.pickVideo(source: ImageSource.gallery);
                        if (video != null && context.mounted) {
                          context
                              .read<VideoViewModel>()
                              .pickVideo(File(video.path));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error picking video: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Select Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAB7FFF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            // Video Player
            Chewie(controller: viewModel.chewieController!),

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
