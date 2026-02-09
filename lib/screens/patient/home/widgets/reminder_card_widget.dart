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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: reminder.isCompleted ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: reminder.isCompleted
              ? Colors.grey.shade300
              : Colors.teal.shade100,
          width: 2,
        ),
        boxShadow: [
          if (!reminder.isCompleted)
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Icon / Time
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: reminder.isCompleted
                  ? Colors.grey.shade200
                  : Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              reminder.isCompleted ? Icons.check : Icons.access_time_filled,
              color: reminder.isCompleted ? Colors.grey : Colors.teal,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color:
                            reminder.isCompleted ? Colors.grey : Colors.black87,
                        fontWeight: FontWeight.bold,
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      DateFormat('h:mm a').format(reminder.time),
                      style: TextStyle(
                        fontSize: 18,
                        color: reminder.isCompleted
                            ? Colors.grey
                            : Colors.teal.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (reminder.hasVoiceNote) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mic,
                                size: 16, color: Colors.deepOrange),
                            const SizedBox(width: 4),
                            Text(
                              'Play',
                              style: TextStyle(
                                color: Colors.deepOrange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action Button
          const SizedBox(width: 12),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: reminder.isCompleted ? Colors.transparent : Colors.teal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: reminder.isCompleted ? Colors.grey : Colors.teal,
                ),
              ),
              child: Text(
                reminder.isCompleted ? 'Undo' : 'Done',
                style: TextStyle(
                  color: reminder.isCompleted ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
