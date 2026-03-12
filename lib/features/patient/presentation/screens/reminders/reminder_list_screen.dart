import 'package:dementia_care_app/data/models/reminder.dart';
import 'package:dementia_care_app/features/auth/providers/auth_provider.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/home/viewmodels/home_viewmodel.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/home/widgets/reminder_card_widget.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/reminders/add_edit_reminder_screen.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/reminders/voice_reminder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../medicine_scanner/presentation/screens/medicine_scan_screen.dart';

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MedicineScanScreen()),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.document_scanner, color: Colors.teal),
              ),
              tooltip: 'Scan Medicine',
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
                  _buildList(context, homeState.todayReminders, viewModel, ref),
                  _buildList(
                      context, homeState.upcomingReminders, viewModel, ref),
                  _buildList(
                      context, homeState.completedReminders, viewModel, ref),
                ],
              ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Reminder> reminders,
      HomeViewModel viewModel, WidgetRef ref) {
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ReminderCard(
            reminder: reminder,
            onToggle: () => viewModel.toggleReminder(reminder.id),
            onDelete: () => viewModel.deleteReminder(reminder.id),
          ),
        );
      },
    );
  }
}
