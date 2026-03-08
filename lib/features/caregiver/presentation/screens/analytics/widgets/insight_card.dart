import 'package:flutter/material.dart';

import '../models/analytics_stats.dart';

class InsightCard extends StatelessWidget {
  final String text;
  final InsightType type;

  const InsightCard(
      {super.key,
      required this.text,
      this.type = InsightType.neutral // Default for backward compat if needed
      });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;
    Color iconColor;
    Color textColor;

    switch (type) {
      case InsightType.positive:
        bg = Colors.green.shade50;
        border = Colors.green.shade200;
        icon = Icons.check_circle;
        iconColor = Colors.green;
        textColor = Colors.green.shade900;
        break;
      case InsightType.warning:
        bg = Colors.orange.shade50;
        border = Colors.orange.shade200;
        icon = Icons.warning_amber;
        iconColor = Colors.orange;
        textColor = Colors.orange.shade900;
        break;
      case InsightType.neutral:
        bg = Colors.blue.shade50;
        border = Colors.blue.shade200;
        icon = Icons.info_outline;
        iconColor = Colors.blue;
        textColor = Colors.blue.shade900;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
