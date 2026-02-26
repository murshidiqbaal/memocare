import 'package:flutter/material.dart';
import '../../../../data/models/reminder.dart';
import 'package:intl/intl.dart';

class CaregiverReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPlayAudio;

  const CaregiverReminderCard({
    super.key,
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.access_time;
    String statusText = 'Pending';

    if (reminder.status == ReminderStatus.completed) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else if (reminder.status == ReminderStatus.missed ||
        (reminder.status == ReminderStatus.pending &&
            reminder.reminderTime.isBefore(DateTime.now()))) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'Missed';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            DateFormat('h:mm a').format(reminder.reminderTime),
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          if (reminder.repeatRule != ReminderFrequency.once)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                reminder.repeatRule.name.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10, color: Colors.teal.shade800),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (reminder.voiceAudioUrl != null ||
                    reminder.localAudioPath != null)
                  IconButton(
                    onPressed: onPlayAudio,
                    icon: const Icon(Icons.play_circle_fill,
                        color: Colors.orange, size: 32),
                    tooltip: 'Play Voice Note',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (reminder.isSnoozed) // Assuming isSnoozed boolean exists
                      const Text(
                        ' • Snoozed',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit,
                          size: 16, color: Colors.blueGrey),
                      label: const Text('Edit',
                          style: TextStyle(color: Colors.blueGrey)),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
