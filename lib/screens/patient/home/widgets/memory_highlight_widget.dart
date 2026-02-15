import 'package:flutter/material.dart';

/// Memory Highlight Card - Emotional design for memory recall
///
/// Healthcare-grade improvements:
/// - Large rounded photo preview
/// - Warm gradient overlay
/// - Elevated shadow for warmth
/// - Supportive emotional text
/// - Triggers emotional recall, not just functional viewing
class MemoryHighlightCard extends StatelessWidget {
  final VoidCallback onViewDay;

  const MemoryHighlightCard({
    super.key,
    required this.onViewDay,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        // Warm elevated shadow
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.15),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 30 * scale,
            offset: Offset(0, 12 * scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Large rounded photo preview
          ClipRRect(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(12 * scale)),
            child: Container(
              height: 220 * scale,
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                image: const DecorationImage(
                  image: AssetImage(
                      'assets/images/placeholders/memory_placeholder.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Warm gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  // Memory title
                  Positioned(
                    bottom: 20 * scale,
                    left: 20 * scale,
                    right: 20 * scale,
                    child: Text(
                      'A beautiful day at the park with family.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2 * scale),
                            blurRadius: 4 * scale,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Supportive action section
          Padding(
            padding: EdgeInsets.all(20 * scale),
            child: Column(
              children: [
                // Supportive emotional text
                Text(
                  '💝 Tap to relive this memory',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16 * scale),

                // View button
                SizedBox(
                  width: double.infinity,
                  height: 56 * scale,
                  child: ElevatedButton(
                    onPressed: onViewDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_edu, size: 24 * scale),
                        SizedBox(width: 10 * scale),
                        Text(
                          'View My Day',
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
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
