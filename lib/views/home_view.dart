import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../viewmodels/video_viewmodel.dart';
import '../core/constants/app_constants.dart';
import 'widgets/video_player_widget.dart';
import 'widgets/template_selector_dialog.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _timelineController = ScrollController();

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use dark theme colors directly or from Theme
    const backgroundColor = Color(0xFF0F0F0F);
    const surfaceColor = Color(0xFF1A1A1A);
    const primaryColor = Color(0xFFAB7FFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // 1. Video Preview Area (Top Half)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Center(
                child: Consumer<VideoViewModel>(
                  builder: (context, viewModel, child) {
                    return AspectRatio(
                      aspectRatio: viewModel.aspectRatio,
                      child: const VideoPlayerWidget(),
                    );
                  },
                ),
              ),
            ),
          ),

          // 2. Timeline & Controls Area (Bottom Half)
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(color: Colors.white10, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transport Controls (Play, Pause, Time)
                  _buildTransportControls(primaryColor),

                  // Timeline Ruler / Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.subtitles,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Captions Timeline',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // The Caption Timeline
                  Expanded(
                    child: _buildTimeline(primaryColor),
                  ),

                  // Bottom Action Bar
                  _buildBottomToolbar(primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F0F),
      elevation: 0,
      title: const Text(
        'PP Auto Caption',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        // Status Indicator
        Consumer<VideoViewModel>(
          builder: (context, vm, child) {
            if (vm.isProcessing) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        // Template Selector
        Consumer<VideoViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: const Icon(Icons.style_outlined),
              tooltip: 'Caption Style',
              onPressed: viewModel.hasCaptions
                  ? () => TemplateSelectorDialog.show(context)
                  : null,
            );
          },
        ),
        // Export Button
        Consumer<VideoViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Export Video',
              onPressed: (viewModel.hasCaptions && !viewModel.isProcessing)
                  ? () => viewModel.exportVideo()
                  : null,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTransportControls(Color primaryColor) {
    return Consumer<VideoViewModel>(
      builder: (context, viewModel, child) {
        final isPlaying = viewModel.videoController?.value.isPlaying ?? false;
        final duration =
            viewModel.videoController?.value.duration ?? Duration.zero;
        final position =
            viewModel.videoController?.value.position ?? Duration.zero;

        String formatDuration(Duration d) {
          final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
          final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
          return '$minutes:$seconds';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time Display
              Text(
                '${formatDuration(position)} / ${formatDuration(duration)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'Monospace',
                ),
              ),

              // Play/Pause Center
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (viewModel.videoController != null) {
                        viewModel.videoController!.seekTo(
                          position - const Duration(seconds: 5),
                        );
                      }
                    },
                    icon: const Icon(Icons.replay_5,
                        size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (viewModel.videoController != null) {
                          isPlaying
                              ? viewModel.videoController!.pause()
                              : viewModel.videoController!.play();
                          // Force rebuild to update icon
                          setState(() {});
                        }
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      if (viewModel.videoController != null) {
                        viewModel.videoController!.seekTo(
                          position + const Duration(seconds: 5),
                        );
                      }
                    },
                    icon: const Icon(Icons.forward_5,
                        size: 20, color: Colors.white),
                  ),
                ],
              ),

              // Aspect Ratio (moved here for quick access)
              PopupMenuButton<String>(
                icon: const Icon(Icons.aspect_ratio,
                    size: 20, color: Colors.grey),
                tooltip: 'Aspect Ratio',
                onSelected: (value) => viewModel.setAspectRatio(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: AppConstants.aspectRatio9x16,
                    child: Text('9:16 (TikTok/Reels)'),
                  ),
                  const PopupMenuItem(
                    value: AppConstants.aspectRatio16x9,
                    child: Text('16:9 (YouTube)'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeline(Color primaryColor) {
    return Consumer<VideoViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasCaptions) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.subtitles_off, size: 40, color: Colors.grey[800]),
                const SizedBox(height: 8),
                Text(
                  'No captions generated yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Find current caption index for highlighting
        int currentIndex = -1;
        if (viewModel.currentCaptionText.isNotEmpty) {
          currentIndex = viewModel.captions
              .indexWhere((c) => c.text == viewModel.currentCaptionText);
        }

        return Container(
          color: const Color(0xFF121212),
          child: ListView.separated(
            controller: _timelineController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.captions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final caption = viewModel.captions[index];
              final isActive = index == currentIndex;

              return GestureDetector(
                onTap: () => viewModel.seekToCaption(caption.start),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 120),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? primaryColor.withOpacity(0.2)
                        : const Color(0xFF2A2A2A),
                    border: Border.all(
                      color: isActive ? primaryColor : Colors.transparent,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        caption.text,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey[400],
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${caption.start}s',
                        style: TextStyle(
                          color: isActive
                              ? primaryColor.withOpacity(0.8)
                              : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomToolbar(Color primaryColor) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        children: [
          // Pick Video Button
          _buildToolbarButton(
            icon: Icons.add_circle_outline,
            label: 'New Video',
            onTap: () async {
              final picker = ImagePicker();
              final video = await picker.pickVideo(source: ImageSource.gallery);
              if (video != null && mounted) {
                context.read<VideoViewModel>().pickVideo(File(video.path));
              }
            },
          ),

          const SizedBox(width: 16),

          // Language Selector (Expanded)
          Expanded(
            child: Consumer<VideoViewModel>(
              builder: (context, vm, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: vm.selectedLanguage,
                      dropdownColor: const Color(0xFF2A2A2A),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                      isExpanded: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      items: AppConstants.supportedLanguages
                          .map((lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(
                                  lang,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ))
                          .toList(),
                      onChanged: vm.isProcessing
                          ? null
                          : (value) {
                              if (value != null) vm.setLanguage(value);
                            },
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 16),

          // Generate Button (Primary)
          Consumer<VideoViewModel>(
            builder: (context, viewModel, child) {
              final bool canGenerate =
                  viewModel.hasVideo && !viewModel.isProcessing;

              return ElevatedButton(
                onPressed:
                    canGenerate ? () => viewModel.generateCaptions() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  minimumSize: const Size(0, 48),
                ),
                child: Row(
                  children: [
                    Icon(
                      viewModel.hasCaptions
                          ? Icons.refresh
                          : Icons.auto_awesome,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      viewModel.hasCaptions ? 'Redo' : 'Generate',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
