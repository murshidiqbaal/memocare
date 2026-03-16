import 'package:memocare/data/models/reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CaregiverReminderCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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

    // 4. Resolve Creator Label (Part 3)
    final String? creatorLabel =
        reminder.createdRole == 'caregiver' ? "Added by caregiver" : null;

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
                      // Attribution Badge
                      if (creatorLabel != null && creatorLabel.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.indigo.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volunteer_activism,
                                  size: 12, color: Colors.indigo.shade700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  creatorLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.indigo.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
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

