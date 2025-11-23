import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/video_viewmodel.dart';
import '../../models/template_model.dart';

class TemplateSelectorDialog extends StatelessWidget {
  const TemplateSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<VideoViewModel>();

    return AlertDialog(
      title: const Text('Choose Caption Style'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: TemplateModel.all.map((template) {
            return RadioListTile<String>(
              title: Text(template.name),
              subtitle: Text(template.description),
              value: template.id,
              groupValue: viewModel.selectedTemplate,
              onChanged: (value) {
                if (value != null) {
                  viewModel.setTemplate(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TemplateSelectorDialog(),
    );
  }
}
