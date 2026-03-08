import 'package:flutter/material.dart';

class AnalyticsStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final String? trend; // "up", "down", "flat"

  const AnalyticsStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = Colors.teal,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    IconData trendIcon = Icons.remove;
    Color trendColor = Colors.grey;
    if (trend == 'up') {
      trendIcon = Icons.arrow_upward;
      trendColor = Colors.green;
    } else if (trend == 'down') {
      trendIcon = Icons.arrow_downward;
      trendColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              if (icon != null)
                Icon(icon, color: color.withOpacity(0.8), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: 4),
                Text(
                  'vs last week',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }
}
