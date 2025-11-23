import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InfoDialog extends StatefulWidget {
  const InfoDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const InfoDialog(),
    );
  }

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Choose Language & Video',
      'description':
          'Select your video and preferred language. We support multiple languages including Hinglish.',
      'image': 'assets/slider1.png', // Placeholder
    },
    {
      'title': 'AI Generation Process',
      'description':
          'Our advanced AI analyzes audio and generates accurate timestamps for every word.',
      'image': 'assets/slider3.png', // Placeholder
    },
      {
        'title': 'Preview & Export',
        'description':
            'Tap to seek through the timeline. Choose a style and export your masterpiece.',
        'image': 'assets/slider2.png', // Placeholder
      },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 450, // Fixed height for slider
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'How it Works',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // GIF Placeholder Container
                      Container(
                        height:
                            180, // You likely need a fixed height or aspect ratio here
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                          // Add the image here inside the decoration
                          image: DecorationImage(
                            image: AssetImage(slide['image']!),
                            fit: BoxFit
                                .cover, // Use 'cover' to fill without distorting. Use 'fill' to stretch.
                          ),
                        ),
                        // No child needed unless you want to put text ON TOP of the image
                      ),
                      Text(
                        slide['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        slide['description']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFFAB7FFF)
                        : Colors.white24,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
