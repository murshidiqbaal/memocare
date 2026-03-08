import 'package:flutter/material.dart';

import 'quick_action_button.dart';

/// Quick Action Grid - Simplified to 3 safe actions only
///
/// Healthcare-grade improvements:
/// - Only safe, non-emergency actions
/// - Responsive layout (2x2 → 2x1 on small screens)
/// - Minimum button size 88-96px
/// - Clear visual hierarchy
/// - SOS moved to separate emergency card
class QuickActionGrid extends StatelessWidget {
  final VoidCallback onMemoriesTap;
  final VoidCallback onGamesTap;
  final VoidCallback onLocationTap;

  const QuickActionGrid({
    super.key,
    required this.onMemoriesTap,
    required this.onGamesTap,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive column count based on screen width
        final crossAxisCount = constraints.maxWidth < 360 ? 1 : 2;
        final childAspectRatio = constraints.maxWidth < 360 ? 3.0 : 1.15;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            QuickActionButton(
              label: 'My Memories',
              icon: Icons.photo_album,
              color: Colors.pinkAccent,
              onTap: onMemoriesTap,
            ),
            QuickActionButton(
              label: 'Games',
              icon: Icons.games,
              color: Colors.orange,
              onTap: onGamesTap,
            ),
            QuickActionButton(
              label: 'Safe Zone',
              icon: Icons.map,
              color: Colors.green,
              onTap: onLocationTap,
            ),
          ],
        );
      },
    );
  }
}
