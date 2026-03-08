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

    final scale = MediaQuery.of(context).size.width / 375.0;

    return AnimatedOpacity(
      opacity: isOffline ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        color: Colors.amber.shade100, // Background color doesn't need scaling
        padding:
            EdgeInsets.symmetric(vertical: 12 * scale, horizontal: 20 * scale),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off,
                    size: 20 * scale, color: Colors.amber.shade900),
                SizedBox(width: 10 * scale),
                Flexible(
                  child: Text(
                    'You are offline',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 16 * scale,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4 * scale),
            // Supportive subtext
            Text(
              'Reminders still work. Changes will sync later.',
              style: TextStyle(
                color: Colors.amber.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 14 * scale,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
