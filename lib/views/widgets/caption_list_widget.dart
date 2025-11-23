import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/video_viewmodel.dart';

class CaptionListWidget extends StatelessWidget {
  const CaptionListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.captions.isEmpty) {
          return const Center(
            child: Text('No captions yet'),
          );
        }

        return ListView.builder(
          itemCount: viewModel.captions.length,
          itemBuilder: (context, index) {
            final caption = viewModel.captions[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  caption.text,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${caption.start} - ${caption.end}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: () => viewModel.seekToCaption(caption.start),
              ),
            );
          },
        );
      },
    );
  }
}
