import 'package:flutter/material.dart';

/// Offline Status Indicator - Enhanced with supportive messaging
///
/// Healthcare-grade improvements:
/// - Supportive subtext explaining offline functionality
/// - Improved visual contrast
/// - Gentle fade-in animation
/// - Calm warning background
class OfflineStatusIndicator extends StatelessWidget {
  final bool isOffline;

  const OfflineStatusIndicator({
    super.key,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: isOffline ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        color: Colors.amber.shade100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 20, color: Colors.amber.shade900),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'You are offline',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Supportive subtext
            Text(
              'Reminders still work. Changes will sync later.',
              style: TextStyle(
                color: Colors.amber.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
