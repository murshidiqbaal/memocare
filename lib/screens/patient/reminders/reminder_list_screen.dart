import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/reminder.dart';
import 'add_edit_reminder_screen.dart';
import 'reminder_detail_screen.dart';
import 'viewmodels/reminder_viewmodel.dart';
import 'voice_reminder_screen.dart';
// import 'widgets/reminder_list_item.dart'; // We'll verify this widget or inline it if it needs strict updates

// Since ReminderListItem might be outdated, I'll inline the list item build logic or create a new widget here to ensure compliance.
// Actually, let's create a new widget file or update the existing one.
// I'll inline for now to guarantee correctness with the new model, as I haven't seen the widget file content yet (except list_dir).
// Wait, I saw it in list_dir: `widgets/reminder_list_item.dart`.
// I'll update the screen to build items directly for now to be safe.

class ReminderListScreen extends ConsumerWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderState = ref.watch(reminderViewModelProvider);
    final viewModel = ref.read(reminderViewModelProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'My Reminders',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VoiceReminderScreen()),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.teal),
              ),
              tooltip: 'Add by Voice',
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddEditReminderScreen()),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              tooltip: 'Add Manually',
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: reminderState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(context, reminderState.todayReminders, viewModel),
                  _buildList(
                      context, reminderState.upcomingReminders, viewModel),
                  _buildList(
                      context, reminderState.completedReminders, viewModel),
                ],
              ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Reminder> reminders,
      ReminderViewModel viewModel) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No reminders here.',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(context, reminder, viewModel);
      },
    );
  }

  Widget _buildReminderCard(
      BuildContext context, Reminder reminder, ReminderViewModel viewModel) {
    final isDone = reminder.status == ReminderStatus.completed;
    final isMissed = reminder.status == ReminderStatus.missed;

    Color statusColor = Colors.grey;
    if (isDone) statusColor = Colors.green;
    if (isMissed) statusColor = Colors.red;
    if (reminder.status == ReminderStatus.pending) statusColor = Colors.orange;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ReminderDetailScreen(reminderId: reminder.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type Icon Badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getTypeColor(reminder.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(reminder.type),
                      color: _getTypeColor(reminder.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? Colors.grey : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a').format(reminder.remindAt),
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500),
                            ),
                            if (reminder.repeatRule !=
                                ReminderFrequency.once) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.repeat, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                reminder.repeatRule.name,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Checkbox
                  if (!isDone)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline,
                          size: 32, color: Colors.grey),
                      onPressed: () {
                        viewModel.markAsDone(reminder.id);
                      },
                    )
                  else
                    const Icon(Icons.check_circle,
                        size: 32, color: Colors.green),
                ],
              ),
              // Optional: Voice Indicator if present
              if (reminder.voiceAudioUrl != null ||
                  reminder.localAudioPath != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.mic, size: 16, color: Colors.teal),
                    const SizedBox(width: 4),
                    Text(
                      'Voice note attached',
                      style:
                          TextStyle(color: Colors.teal.shade700, fontSize: 12),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.medication:
        return Colors.redAccent;
      case ReminderType.appointment:
        return Colors.blueAccent;
      case ReminderType.task:
        return Colors.orangeAccent;
    }
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.medication:
        return Icons.medication;
      case ReminderType.appointment:
        return Icons.calendar_month;
      case ReminderType.task:
        return Icons.task_alt;
    }
  }
}
