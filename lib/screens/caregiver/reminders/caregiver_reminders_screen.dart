import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../patient/reminders/add_edit_reminder_screen.dart';
import 'caregiver_reminder_viewmodel.dart';
import 'reminder_history_screen.dart';
import 'widgets/caregiver_reminder_card.dart';

class CaregiverRemindersScreen extends ConsumerWidget {
  const CaregiverRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(caregiverReminderProvider);
    final viewModel = ref.read(caregiverReminderProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Patient Reminders'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              // Trigger sync
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Syncing with patient device...')));
              await viewModel.refresh();
            },
          )
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildOverviewHeader(context, viewModel),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = state.reminders[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReminderHistoryScreen(reminder: reminder),
                            ),
                          );
                        },
                        child: CaregiverReminderCard(
                          reminder: reminder,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditReminderScreen(
                                  existingReminder: reminder,
                                  targetPatientId: state.selectedPatientId,
                                  onSave: (updatedReminder) {
                                    viewModel.updateReminder(updatedReminder);
                                  },
                                ),
                              ),
                            );
                          },
                          onDelete: () => viewModel.deleteReminder(reminder.id),
                          onPlayAudio: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Playing voice note...')));
                            // In real app, play audio here using VM or helper
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditReminderScreen(
                targetPatientId: state.selectedPatientId,
                onSave: (newReminder) {
                  viewModel.addReminder(newReminder);
                },
              ),
            ),
          );
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('New Reminder', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildOverviewHeader(
      BuildContext context, CaregiverReminderViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.teal.shade700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundImage:
                    AssetImage('assets/images/placeholders/elderly_man.jpg'),
                // Fallback if asset missing is handled by image provider usually, or use icon
                child: Icon(Icons.person, size: 30),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Managing For',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    'Grandpa Joe',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Online',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickStat(
                  context,
                  'Completed',
                  '${viewModel.completedTodayCount}',
                  Icons.check_circle,
                  Colors.greenAccent),
              _buildStatDivider(),
              _buildQuickStat(context, 'Pending', '${viewModel.pendingCount}',
                  Icons.hourglass_top, Colors.orangeAccent),
              _buildStatDivider(),
              _buildQuickStat(context, 'Missed', '${viewModel.missedCount}',
                  Icons.error_outline, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(icon, color: color, size: 16),
            ),
          ],
        ),
        Text(label,
            style: TextStyle(color: Colors.teal.shade100, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.teal.shade500);
  }
}
