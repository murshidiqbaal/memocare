import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memocare/data/models/reminder.dart';

// import '../../../../data/models/reminder.dart';

class ReminderListItem extends ConsumerWidget {
  final Reminder reminder;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Styling based on state
    final isCompleted = reminder.status == ReminderStatus.completed;
    final isMissed = reminder.status == ReminderStatus.missed ||
        (reminder.status == ReminderStatus.pending &&
            reminder.reminderTime.isBefore(DateTime.now()));

    final hasVoice =
        reminder.voiceAudioUrl != null || reminder.localAudioPath != null;

    Color cardColor = Colors.white;
    Color borderColor = Colors.teal.shade100;

    if (isCompleted) {
      cardColor = Colors.grey.shade50;
      borderColor = Colors.grey.shade300;
    } else if (isMissed) {
      borderColor = Colors.red.shade200;
    } else {
      // Pending
      // Differentiate by type optionally
      if (reminder.type == ReminderType.medication) {
        borderColor = Colors.red.shade100;
        cardColor = Colors.red.shade50;
      }
    }

    // 4. Resolve Creator Label (Part 3)
    final String? creatorLabel =
        reminder.createdRole == 'caregiver' ? "Added by caregiver" : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCompleted ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 2),
      ),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 1. Status Checkbox Area
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? Colors.green
                          : (isMissed
                              ? Colors.red
                              : (reminder.localAudioPath != null
                                  ? Colors.teal
                                  : Colors.indigo.shade300)),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // 2. Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attribution Badge
                    if (creatorLabel != null && creatorLabel.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.indigo.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volunteer_activism,
                                size: 10, color: Colors.indigo.shade700),
                            const SizedBox(width: 4),
                            Text(
                              creatorLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.indigo.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.grey : Colors.black87,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          size: 16,
                          color:
                              isCompleted ? Colors.grey : Colors.teal.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('h:mm a').format(reminder.reminderTime),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? Colors.grey
                                : Colors.teal.shade700,
                          ),
                        ),
                        if (hasVoice) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.mic,
                              size: 16, color: Colors.orange.shade800),
                        ],
                        if (reminder.repeatRule != ReminderFrequency.once) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.repeat,
                              size: 16, color: Colors.blue.shade800),
                        ]
                      ],
                    ),
                    if (isMissed)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Overdue',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
