import 'package:flutter/material.dart';
import 'features_page.dart';
import 'tutorial_page.dart';
import 'examples_page.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Help Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    // PRO Badge (commented out for now)
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Main Content - No Projects
              Column(
                children: [
                  // Illustration
                  Image.asset(
                    'assets/empty.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'You have no projects',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 18,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Create Project Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAB7FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Create project',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Feature Cards - Custom Layout
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Top Row - 2 cards
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FeaturesPage(),
                                ),
                              );
                            },
                            child: _buildFeatureCard(
                              icon: 'assets/image-1.png',
                              title: 'Quick edit\nmanual',
                              subtitle: 'take 5 minutes to understand',
                              borderColor: const Color(0xFFAB7FFF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TutorialPage(),
                                ),
                              );
                            },
                            child: _buildFeatureCard(
                              icon: 'assets/image.png',
                              title: 'Add text to\nyour videos',
                              subtitle: 'auto captioning',
                              borderColor: const Color(0xFFAB7FFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Middle - Full width card
                    _buildFeatureCard(
                      icon: 'assets/bomb.png',
                      title: 'What is an editor capable of?',
                      subtitle: 'you have not seen this',
                      borderColor: const Color(0xFFAB7FFF),
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 12),

                    // Bottom Row - 2 cards
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ExamplesPage(),
                                ),
                              );
                            },
                            child: _buildFeatureCard(
                              icon: 'assets/Point_right.png',
                              title: 'Best examples\nof work',
                              subtitle: '',
                              borderColor: const Color(0xFFAB7FFF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: 'assets/Mask Group.png',
                            title: 'More solutions',
                            subtitle: 'Coming soon',
                            borderColor: const Color(0xFFAB7FFF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String icon,
    required String title,
    required String subtitle,
    required Color borderColor,
    bool isFullWidth = false,
  }) {
    return Container(
      height: isFullWidth ? 140 : 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: isFullWidth
          ? Row(
              children: [
                // Icon Container
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(icon, fit: BoxFit.contain),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(icon, fit: BoxFit.contain),
                ),
                const Spacer(),
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
    );
  }
}
