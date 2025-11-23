import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../viewmodels/video_viewmodel.dart';
import 'export_success_page.dart';
import 'widgets/error_dialog.dart';

class ExportProgressPage extends StatefulWidget {
  final String? style;

  const ExportProgressPage({super.key, this.style});

  @override
  State<ExportProgressPage> createState() => _ExportProgressPageState();
}

class _ExportProgressPageState extends State<ExportProgressPage> {
  final List<String> _loadingMessages = [
    'Uploading video to cloud...',
    'Crunching pixels...',
    'Applying caption styles...',
    'Rendering magic...',
    'Almost ready...',
  ];

  final List<String> _loadingImages = [
    'assets/loading1.png',
    'assets/loading2.png',
    'assets/loading3.png',
  ];

  int _messageIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    
    // Cycle messages
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
        });
      }
    });

    // Start Export
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startExport();
    });
  }

  Future<void> _startExport() async {
    final viewModel = context.read<VideoViewModel>();
    try {
      final filePath = await viewModel.exportVideo(style: widget.style);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExportSuccessPage(filePath: filePath),
          ),
        ); 
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress page
        ErrorDialog.show(context, error: e.toString());
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // 3D Character Image Placeholder
            Container(
              height: 300,
              width: 300,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Image.asset(
                    _loadingImages[_messageIndex % _loadingImages.length],
                    key: ValueKey<int>(_messageIndex),
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Status Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Real status from ViewModel
                  Consumer<VideoViewModel>(
                    builder: (context, vm, child) {
                      return Text(
                        vm.statusMessage.isEmpty ? 'Preparing...' : vm.statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Fun cycling message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _loadingMessages[_messageIndex],
                      key: ValueKey<int>(_messageIndex),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFAB7FFF),
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            const Spacer(),
            
            // Cancel Button (Optional)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.4)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

