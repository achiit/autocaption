import 'package:flutter/material.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'How to Use',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Title
            const Text(
              'Add Captions in\n4 Easy Steps',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto',
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Follow these simple steps to create amazing captioned videos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Roboto',
              ),
            ),

            const SizedBox(height: 40),

            // Step Cards
            _buildStepCard(
              stepNumber: '1',
              title: 'Pick Your Video',
              description:
                  'Tap the "Pick Video" button and select a video from your gallery. Works with any video format!',
              icon: Icons.video_library,
              color: const Color(0xFFAB7FFF),
            ),

            const SizedBox(height: 24),

            _buildStepCard(
              stepNumber: '2',
              title: 'Choose Language',
              description:
                  'Select the language of your video from the dropdown. We support English, Hindi, Spanish, French, and Hinglish.',
              icon: Icons.language,
              color: const Color(0xFFFF6B9D),
            ),

            const SizedBox(height: 24),

            _buildStepCard(
              stepNumber: '3',
              title: 'Generate Captions',
              description:
                  'Tap "Generate" and watch as our AI creates perfectly timed captions with word-level accuracy in seconds.',
              icon: Icons.auto_awesome,
              color: const Color(0xFF4ECDC4),
            ),

            const SizedBox(height: 24),

            _buildStepCard(
              stepNumber: '4',
              title: 'Choose Style & Export',
              description:
                  'Pick your favorite caption style from 5 professional templates, then hit "Export" to save and share!',
              icon: Icons.share,
              color: const Color(0xFFFFA500),
            ),

            const SizedBox(height: 40),

            // Pro Tips Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF465BCA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Pro Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTip('• Use clear audio for best results'),
                  _buildTip('• Tap any caption to jump to that moment'),
                  _buildTip('• Try different templates to match your style'),
                  _buildTip('• Change aspect ratio for different platforms'),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB7FFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got It!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Roboto',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        tip,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}
