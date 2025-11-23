import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExportStyleDialog extends StatefulWidget {
  const ExportStyleDialog({super.key});

  @override
  State<ExportStyleDialog> createState() => _ExportStyleDialogState();
}

class _ExportStyleDialogState extends State<ExportStyleDialog> {
  String _selectedStyle = 'default';

  final List<Map<String, dynamic>> _styles = [
    {
      'id': 'default',
      'name': 'Classic',
      'icon': LucideIcons.type,
      'color': Color(0xFFAB7FFF),
    },
    {
      'id': 'minimal',
      'name': 'Minimal',
      'icon': LucideIcons.minus,
      'color': Colors.blueAccent,
    },
    {
      'id': 'bold',
      'name': 'Bold',
      'icon': LucideIcons.bold,
      'color': Colors.orangeAccent,
    },
    {
      'id': 'neon',
      'name': 'Neon',
      'icon': LucideIcons.zap,
      'color': Colors.greenAccent,
    },
    {
      'id': 'gradient',
      'name': 'Gradient',
      'icon': LucideIcons.palette,
      'color': Colors.pinkAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB7FFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.clapperboard,
                    color: Color(0xFFAB7FFF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Export Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Caption Style',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 220, // Fixed height for grid
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: _styles.length,
                itemBuilder: (context, index) {
                  final style = _styles[index];
                  final isSelected = _selectedStyle == style['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStyle = style['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? style['color'].withOpacity(0.2)
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? style['color']
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            style['icon'],
                            color: isSelected ? style['color'] : Colors.white54,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            style['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedStyle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAB7FFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Export Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

