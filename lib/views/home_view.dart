import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../viewmodels/video_viewmodel.dart';
import '../core/constants/app_constants.dart';
import 'widgets/video_player_widget.dart';
import 'widgets/loading_dialog.dart';
import 'widgets/error_dialog.dart';
import 'widgets/info_dialog.dart';
import 'widgets/confirm_exit_dialog.dart';
import 'widgets/export_style_dialog.dart';
import 'export_progress_page.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _timelineController = ScrollController();
  final GlobalKey _videoKey = GlobalKey();
  final GlobalKey _languageKey = GlobalKey();
  final GlobalKey _generateKey = GlobalKey();

  Widget _buildShowcase({
    required GlobalKey key,
    required String title,
    required String description,
    required Widget child,
    BorderRadius? targetBorderRadius,
  }) {
    return Showcase.withWidget(
      key: key,
      height: 120,
      width: 250,
      targetBorderRadius: targetBorderRadius,
      container: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFAB7FFF), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => ShowCaseWidget.of(context).dismiss(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => ShowCaseWidget.of(context).next(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAB7FFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: const Size(50, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Next', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTime();
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (isFirstTime) {
      if (!mounted) return;
      // Show Info Dialog first
      await InfoDialog.show(context);
      
      // Then start Showcase
      if (!mounted) return;
      ShowCaseWidget.of(context).startShowCase([
        _videoKey,
        _languageKey,
        _generateKey,
      ]);
      
      // Mark as seen
      await prefs.setBool('is_first_time', false);
    }
  }

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await ConfirmExitDialog.show(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      },
      child: Scaffold(
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F0F),
      elevation: 0,
      title: const Text(
        'PP Captions',
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
        // Consumer<VideoViewModel>(
        //   builder: (context, viewModel, child) {
        //     return IconButton(
        //       icon: const Icon(LucideIcons.paintBucket),
        //       tooltip: 'Caption Style',
        //       onPressed: viewModel.hasCaptions
        //           ? () => TemplateSelectorDialog.show(context)
        //           : null,
        //     );
        //   },
        // ),
        // Language Selector
        _buildShowcase(
          key: _languageKey,
          title: 'Select Language',
          description: 'Choose the language for your captions',
          targetBorderRadius: BorderRadius.circular(8),
          child: Consumer<VideoViewModel>(
            builder: (context, vm, child) {
              return DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                isExpanded: true,
                customButton: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.languages,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        vm.selectedLanguage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              items: AppConstants.supportedLanguages
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                      ))
                  .toList(),
                value: vm.selectedLanguage,
              onChanged: vm.isProcessing
                  ? null
                  : (value) {
                      if (value != null) vm.setLanguage(value);
                    },
                dropdownStyleData: DropdownStyleData(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF2A2A2A),
                  ),
                  offset: const Offset(0, -4),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 36,
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 8),

        // Export Button
        Consumer<VideoViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: const Icon(LucideIcons.share),
              tooltip: 'Export Video',
              onPressed: (viewModel.hasCaptions && !viewModel.isProcessing)
                  ? () async {
                      // 1. Show Style Picker
                      final selectedStyle = await showDialog<String>(
                        context: context,
                        builder: (context) => const ExportStyleDialog(),
                      );

                      if (selectedStyle != null && context.mounted) {
                        // 2. Navigate to Progress Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExportProgressPage(style: selectedStyle),
                          ),
                        );
                      }
                    }
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Time Display
              Text(
                '${formatDuration(position)} / ${formatDuration(duration)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontFamily: 'Monospace',
                ),
        ),

        const Spacer(),

              // Controls
              Row(
                children: [
                  // Backward 5s
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (viewModel.videoController != null) {
                        viewModel.videoController!.seekTo(
                          position - const Duration(seconds: 5),
                        );
                      }
                    },
                    icon: const Icon(Icons.replay_5,
                        size: 20, color: Colors.white70),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Play/Pause
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (viewModel.videoController != null) {
                          isPlaying
                              ? viewModel.videoController!.pause()
                              : viewModel.videoController!.play();
                          setState(() {});
                        }
                      },
                      icon: Icon(
                        isPlaying ? LucideIcons.pause : LucideIcons.play,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),

                  // Forward 5s
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (viewModel.videoController != null) {
                        viewModel.videoController!.seekTo(
                          position + const Duration(seconds: 5),
                        );
                      }
                    },
                    icon: const Icon(Icons.forward_5,
                        size: 20, color: Colors.white70),
                  ),
                ],
              ),

              const Spacer(),

              // Right: Aspect Ratio Dropdown
              SizedBox(
                width: 80,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    items: [
                DropdownMenuItem(
                  value: AppConstants.aspectRatio9x16,
                        child: const Text('9:16',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: AppConstants.aspectRatio16x9,
                        child: const Text('16:9',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ],
                    value: viewModel.aspectRatioName,
                    onChanged: (value) {
                      if (value != null) viewModel.setAspectRatio(value);
                    },
                    buttonStyleData: ButtonStyleData(
                      height: 32,
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                        color: Colors.white10,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF2A2A2A),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 36,
                    ),
                    iconStyleData: const IconStyleData(
                      icon: Icon(
                        Icons.aspect_ratio,
                        size: 14,
                        color: Colors.white70,
                      ),
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

  Widget _buildTimeline(Color primaryColor) {
    return Consumer<VideoViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasCaptions) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.subtitles, size: 40, color: Colors.grey[800]),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pick Video Button
          _buildShowcase(
            key: _videoKey,
            title: 'Select Video',
            description: 'Pick a video from your gallery',
            targetBorderRadius: BorderRadius.circular(8),
            child: _buildToolbarButton(
              icon: LucideIcons.plusCircle,
              label: 'New Video',
              onTap: () async {
                final picker = ImagePicker();
                final video = await picker.pickVideo(source: ImageSource.gallery);
                if (video != null && mounted) {
                  context.read<VideoViewModel>().pickVideo(File(video.path));
                }
              },
            ),
          ),

          // Generate Button (Primary)
          Consumer<VideoViewModel>(
            builder: (context, viewModel, child) {
              final bool canGenerate =
                  viewModel.hasVideo && !viewModel.isProcessing;

              return Row(
                children: [
                  // Info Button
                  IconButton(
                    icon: const Icon(LucideIcons.info, color: Colors.grey),
                    tooltip: 'About Generation',
                    onPressed: () async {
                      await InfoDialog.show(context);
                      if (context.mounted) {
                        ShowCaseWidget.of(context).startShowCase([
                          _videoKey,
                          _languageKey,
                          _generateKey,
                        ]);
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  // Generate Button
                  _buildShowcase(
                    key: _generateKey,
                    title: 'Generate Captions',
                    description: 'Click here to generate captions using AI',
                    targetBorderRadius: BorderRadius.circular(10),
                    child: ElevatedButton(
                      onPressed: canGenerate
                          ? () async {
                              LoadingDialog.show(context);
                              try {
                                await viewModel.generateCaptions();
                                if (context.mounted) {
                                  LoadingDialog.hide(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  LoadingDialog.hide(context);
                                  ErrorDialog.show(context, error: e.toString());
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                    ),
                  ),
                ],
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
