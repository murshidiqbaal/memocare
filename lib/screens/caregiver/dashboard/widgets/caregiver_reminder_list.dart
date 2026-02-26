import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/reminder.dart';

class CaregiverReminderList extends StatelessWidget {
  final List<Reminder> reminders;
  final Function(String) onDelete;
  final Function(Reminder) onEdit;
  final Function() onAdd;

  const CaregiverReminderList({
    super.key,
    required this.reminders,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Managed Reminders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            final isCompleted = reminder.status == ReminderStatus.completed;
            final isMissed = reminder.status == ReminderStatus.missed;
            final hasVoice = reminder.voiceAudioUrl != null ||
                reminder.localAudioPath != null;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.shade50
                        : (isMissed
                            ? Colors.red.shade50
                            : Colors.orange.shade50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check
                        : (isMissed ? Icons.priority_high : Icons.access_time),
                    color: isCompleted
                        ? Colors.green
                        : (isMissed ? Colors.red : Colors.orange),
                  ),
                ),
                title: Text(
                  reminder.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(DateFormat('h:mm a').format(reminder.reminderTime)),
                    if (hasVoice)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.mic,
                                size: 14, color: Colors.indigo.shade300),
                            const SizedBox(width: 4),
                            Text(
                              'Voice Note',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.indigo.shade300),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') onDelete(reminder.id);
                    if (value == 'edit') onEdit(reminder);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
