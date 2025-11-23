import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../viewmodels/video_viewmodel.dart';
import 'features_page.dart';
import 'tutorial_page.dart';
import 'examples_page.dart';
import 'export_success_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  
  @override
  void initState() {
    super.initState();
    // Reload projects when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoViewModel>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(

                  children: [
                    // Help Icon
           
                      Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  'Your Projects',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

                  ],
                ),
              ),



              // Projects Section
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
              //   child: const Text(
              //     'Your Projects',
              //     style: TextStyle(
              //       color: Colors.white,
              //       fontSize: 20,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 16),

              Consumer<VideoViewModel>(
                builder: (context, vm, child) {
                  if (vm.projects.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildProjectsList(vm.projects);
                },
              ),

              const SizedBox(height: 30),

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
                          'Create new project',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(List<Map<String, dynamic>> projects) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: projects.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final project = projects[index];
          return GestureDetector(
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExportSuccessPage(filePath: project['path']),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Placeholder (Since we don't generate one yet, use icon)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: const Center(
                            child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 48),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project ${projects.length - index}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              project['date'] ?? 'Unknown date',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Dropdown Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2(
                      customButton: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'share',
                          child: Row(
                            children: const [
                              Icon(LucideIcons.share2, size: 16, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Share', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'delete',
                          child: Row(
                            children: const [
                              Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'share') {
                          Share.shareXFiles([XFile(project['path'])], text: 'My captioned video');
                        } else if (value == 'delete') {
                          context.read<VideoViewModel>().deleteProject(index);
                        }
                      },
                      dropdownStyleData: DropdownStyleData(
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF2A2A2A),
                        ),
                        offset: const Offset(-80, 0),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 36,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
