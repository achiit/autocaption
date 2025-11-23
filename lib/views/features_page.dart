import 'package:flutter/material.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

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
          'Features',
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
              'Powerful Video\nCaptioning',
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
              'Create professional captions in seconds',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Roboto',
              ),
            ),

            const SizedBox(height: 40),

            // Feature Cards
            _buildFeatureCard(
              icon: Icons.language,
              title: 'Multi-Language Support',
              description:
                  'Generate captions in English, Hindi, Spanish, French, and Hinglish with perfect accuracy',
              gradient: const LinearGradient(
                colors: [Color(0xFFAB7FFF), Color(0xFF8B5FDF)],
              ),
            ),

            const SizedBox(height: 20),

            _buildFeatureCard(
              icon: Icons.auto_awesome,
              title: 'Smart Word Highlighting',
              description:
                  'Karaoke-style word-by-word highlighting that follows your speech perfectly',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFDF4B7D)],
              ),
            ),

            const SizedBox(height: 20),

            _buildFeatureCard(
              icon: Icons.palette,
              title: '5 Professional Templates',
              description:
                  'Choose from Classic, Neon Glow, Bold Pop, Minimal Clean, and Gradient styles',
              gradient: const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF2EAD9C)],
              ),
            ),

            const SizedBox(height: 20),

            _buildFeatureCard(
              icon: Icons.speed,
              title: 'Lightning Fast Processing',
              description:
                  'Advanced AI technology generates accurate captions in under 30 seconds',
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA500), Color(0xFFDF8500)],
              ),
            ),

            const SizedBox(height: 20),

            _buildFeatureCard(
              icon: Icons.aspect_ratio,
              title: 'Perfect Aspect Ratios',
              description:
                  'Optimized for both 9:16 (TikTok, Reels) and 16:9 (YouTube) formats',
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF465BCA)],
              ),
            ),

            const SizedBox(height: 20),

            _buildFeatureCard(
              icon: Icons.share,
              title: 'Easy Sharing',
              description:
                  'Export and share your captioned videos directly to any platform',
              gradient: const LinearGradient(
                colors: [Color(0xFFE74C3C), Color(0xFFC72C1C)],
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
                  'Get Started',
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with gradient
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Roboto',
                  ),
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
}
