import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/reminder.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggle;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Scale Factor based on reference width (e.g. 475 mobile width)
    final double scale = MediaQuery.of(context).size.width / 475.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: 16 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: reminder.isCompleted ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: reminder.isCompleted
              ? Colors.grey.shade300
              : Colors.teal.shade100,
          width: 2, // Border width usually doesn't need aggressive scaling
        ),
        boxShadow: [
          if (!reminder.isCompleted)
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 10 * scale,
              offset: Offset(0, 4 * scale),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon / Status Indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: reminder.isCompleted
                  ? Colors.grey.shade200
                  : Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              reminder.isCompleted ? Icons.check : Icons.access_time_filled,
              color: reminder.isCompleted ? Colors.grey : Colors.teal,
              size: 28 * scale,
            ),
          ),
          SizedBox(width: 16 * scale),

          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  reminder.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18 * scale,
                        color:
                            reminder.isCompleted ? Colors.grey : Colors.black87,
                        fontWeight: FontWeight.bold,
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        height: 1.2,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6 * scale),

                // Time & Voice Indicator (Wrapped to prevent overflow)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8 * scale,
                  runSpacing: 4 * scale,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(reminder.time.toLocal()),
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: reminder.isCompleted
                            ? Colors.grey
                            : Colors.teal.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (reminder.hasVoiceNote)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8 * scale, vertical: 4 * scale),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8 * scale),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic,
                                size: 14 * scale, color: Colors.deepOrange),
                            SizedBox(width: 4 * scale),
                            Text(
                              'Voice Note',
                              style: TextStyle(
                                fontSize: 12 * scale,
                                color: Colors.deepOrange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 12 * scale),

          // Action Button
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16 * scale),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale, vertical: 10 * scale),
              decoration: BoxDecoration(
                color: reminder.isCompleted ? Colors.transparent : Colors.teal,
                borderRadius: BorderRadius.circular(16 * scale),
                border: Border.all(
                  color: reminder.isCompleted ? Colors.grey : Colors.teal,
                  width: 1.5,
                ),
              ),
              child: Text(
                reminder.isCompleted ? 'Undo' : 'Done',
                style: TextStyle(
                  color: reminder.isCompleted ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15 * scale,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
