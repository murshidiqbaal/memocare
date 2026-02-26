import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/reminder.dart';
import '../../../../providers/auth_provider.dart'; // Needed for profile
import '../home/viewmodels/home_viewmodel.dart';
import 'add_edit_reminder_screen.dart';
import 'reminder_detail_screen.dart';
import 'voice_reminder_screen.dart';

class ReminderListScreen extends ConsumerWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Single Source of Truth: HomeViewModel
    final homeState = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    // Get user profile for reloading
    final user = ref.watch(currentUserProvider);

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
                if (user != null) {
                  viewModel.loadReminders(user.id);
                }
              },
              icon: const Icon(Icons.refresh, color: Colors.teal),
              tooltip: 'Refresh',
            ),
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
                // Navigate to Add Screen
                // Note: AddEditReminderScreen uses the provider internally to save,
                // so we don't need to pass a callback here unless we want to override default behavior.
                // The screen now uses HomeViewModel too.
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
        body: homeState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildList(context, homeState.todayReminders, viewModel),
                  _buildList(context, homeState.upcomingReminders, viewModel),
                  _buildList(context, homeState.completedReminders, viewModel),
                ],
              ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<Reminder> reminders, HomeViewModel viewModel) {
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
      BuildContext context, Reminder reminder, HomeViewModel viewModel) {
    final isDone = reminder.status == ReminderStatus.completed;

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
                            const Icon(Icons.access_time,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a')
                                  .format(reminder.reminderTime),
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500),
                            ),
                            if (reminder.repeatRule !=
                                ReminderFrequency.once) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.repeat,
                                  size: 14, color: Colors.grey),
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
                        // Calls HomeViewModel toggle
                        viewModel.toggleReminder(reminder.id);
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          size: 32, color: Colors.green),
                      onPressed: () {
                        // Allow untoggling? Yes, toggleReminder supports it.
                        viewModel.toggleReminder(reminder.id);
                      },
                    ),
                ],
              ),
              // Optional: Voice Indicator if present
              if (reminder.voiceAudioUrl != null ||
                  reminder.localAudioPath != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.mic, size: 16, color: Colors.teal),
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
