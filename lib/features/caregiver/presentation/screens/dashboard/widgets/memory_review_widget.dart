import 'package:memocare/core/theme/emotional_theme_extension.dart';
import 'package:flutter/material.dart';
// import '../../../../core/theme/emotional_theme_extension.dart';

class MemoryReviewWidget extends StatelessWidget {
  const MemoryReviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final emotionalTheme =
        Theme.of(context).extension<EmotionalThemeExtension>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emotionalTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: emotionalTheme.primary!.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: emotionalTheme.primary?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage(
                    'assets/images/placeholders/memory_thumb.png'), // Mock
                fit: BoxFit.cover,
              ),
            ),
            child: Icon(Icons.photo, color: emotionalTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Memory",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: emotionalTheme.textPrimary),
                ),
                Text(
                  'Recall session active. Last viewed: 2 hours ago.',
                  style: TextStyle(
                      color: emotionalTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {},
                  child: Text(
                    'Review Timeline >',
                    style: TextStyle(
                      color: emotionalTheme.primary,
                      fontWeight: FontWeight.bold,
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
