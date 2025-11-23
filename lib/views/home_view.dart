import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../viewmodels/video_viewmodel.dart';
import '../core/constants/app_constants.dart';
import 'widgets/video_player_widget.dart';
import 'widgets/caption_list_widget.dart';
import 'widgets/template_selector_dialog.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Video Player Section
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Consumer<VideoViewModel>(
              builder: (context, viewModel, child) {
                return AspectRatio(
                  aspectRatio: viewModel.aspectRatio,
                  child: const VideoPlayerWidget(),
                );
              },
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildControls(context),
          ),

          // Status Message
          Consumer<VideoViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.statusMessage.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    viewModel.statusMessage,
                    style: TextStyle(
                      color:
                          viewModel.isProcessing ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 16),

          // Caption List
          const Expanded(
            child: CaptionListWidget(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        AppConstants.appName,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        // Template Selector
        Consumer<VideoViewModel>(
          builder: (context, viewModel, child) {
            if (!viewModel.hasCaptions) return const SizedBox.shrink();

            return IconButton(
              icon: const Icon(Icons.style),
              tooltip: 'Choose Style',
              onPressed: () => TemplateSelectorDialog.show(context),
            );
          },
        ),

        // Export Button
        Consumer<VideoViewModel>(
          builder: (context, viewModel, child) {
            if (!viewModel.hasCaptions) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: viewModel.isProcessing
                    ? null
                    : () {
                        viewModel.exportVideo();
                      },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    final viewModel = context.read<VideoViewModel>();

    return Row(
      children: [
        // Pick Video Button
        ElevatedButton.icon(
          onPressed: () async {
            final picker = ImagePicker();
            final video = await picker.pickVideo(source: ImageSource.gallery);
            if (video != null) {
              await viewModel.pickVideo(File(video.path));
            }
          },
          icon: const Icon(Icons.video_library),
          label: const Text('Pick Video'),
        ),

        const SizedBox(width: 16),

        // Language Selector
        Consumer<VideoViewModel>(
          builder: (context, vm, child) {
            return DropdownButton<String>(
              value: vm.selectedLanguage,
              items: AppConstants.supportedLanguages
                  .map((lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      ))
                  .toList(),
              onChanged: vm.isProcessing
                  ? null
                  : (value) {
                      if (value != null) vm.setLanguage(value);
                    },
            );
          },
        ),

        const SizedBox(width: 16),

        // Generate Captions Button
        Consumer<VideoViewModel>(
          builder: (context, viewModel, child) {
            return ElevatedButton.icon(
              onPressed: (!viewModel.hasVideo || viewModel.isProcessing)
                  ? null
                  : () => viewModel.generateCaptions(),
              icon: const Icon(Icons.subtitles),
              label: const Text('Generate'),
            );
          },
        ),

        const Spacer(),

        // Aspect Ratio Selector
        Consumer<VideoViewModel>(
          builder: (context, vm, child) {
            return DropdownButton<String>(
              value: vm.aspectRatioName,
              items: const [
                DropdownMenuItem(
                  value: AppConstants.aspectRatio9x16,
                  child: Text('9:16'),
                ),
                DropdownMenuItem(
                  value: AppConstants.aspectRatio16x9,
                  child: Text('16:9'),
                ),
              ],
              onChanged: vm.isProcessing
                  ? null
                  : (value) {
                      if (value != null) vm.setAspectRatio(value);
                    },
            );
          },
        ),
      ],
    );
  }
}
