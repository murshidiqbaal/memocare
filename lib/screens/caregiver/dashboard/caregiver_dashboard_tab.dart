import 'package:dementia_care_app/screens/caregiver/dashboard/viewmodels/caregiver_dashboard_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/reminder.dart';
import '../../patient/reminders/add_edit_reminder_screen.dart';
import '../analytics/analytics_dashboard_screen.dart';
import '../reminders/caregiver_reminder_viewmodel.dart';
import '../reminders/caregiver_reminders_screen.dart';
import 'widgets/caregiver_analytics_chart.dart';
import 'widgets/caregiver_app_bar.dart';
import 'widgets/caregiver_reminder_list.dart';
import 'widgets/game_stats_widget.dart';
import 'widgets/memory_review_widget.dart';
import 'widgets/patient_status_card_widget.dart';
import 'widgets/safety_map_widget.dart';

class CaregiverDashboardTab extends ConsumerWidget {
  const CaregiverDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current caregiver ID from auth
    final caregiverId = Supabase.instance.client.auth.currentUser?.id;

    // Handle unauthenticated state
    if (caregiverId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Not authenticated. Please log in.'),
        ),
      );
    }

    final dashboardState = ref.watch(caregiverDashboardProvider(caregiverId));
    // final dashboardViewModel = ref.read(caregiverDashboardProvider(caregiverId).notifier);
    final reminderState = ref.watch(caregiverReminderProvider);
    final reminderViewModel = ref.read(caregiverReminderProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CaregiverAppBar(
        patientName: dashboardState.selectedPatientName,
        isOffline: dashboardState.isOffline,
        onNotificationTap: () {},
        onProfileTap: () {},
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddReminder(
          context,
          reminderViewModel,
          dashboardState.selectedPatientName,
        ),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add_alert, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            // 1. Patient Status Card
            PatientStatusCard(status: dashboardState.patientStatus),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const AnalyticsDashboardScreen()),
                    );
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('View Full Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal,
                    elevation: 1,
                  ),
                ),
              ),
            ),

            // 2. Safety Map
            SafetyMapWidget(
              statusText: dashboardState.patientStatus.locationName,
              isSafe: dashboardState.patientStatus.isSafe,
            ),

            const SizedBox(height: 16),

            // 3. Reminders Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's Reminders",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CaregiverRemindersScreen(),
                        ),
                      );
                    },
                    child: const Text('Manage All'),
                  ),
                ],
              ),
            ),
            CaregiverReminderList(
              reminders: reminderState.reminders
                  .where((r) =>
                      r.remindAt.day == DateTime.now().day &&
                      r.remindAt.month == DateTime.now().month &&
                      r.remindAt.year == DateTime.now().year)
                  .take(5)
                  .toList(),
              onDelete: reminderViewModel.deleteReminder,
              onEdit: (reminder) => _navigateToAddReminder(context,
                  reminderViewModel, dashboardState.selectedPatientName,
                  existingReminder: reminder),
              onAdd: () => _navigateToAddReminder(context, reminderViewModel,
                  dashboardState.selectedPatientName),
            ),

            const SizedBox(height: 16),

            // 4. Game Stats
            const GameStatsWidget(),

            // 5. Memory Review
            const MemoryReviewWidget(),

            const SizedBox(height: 24),

            // 6. Analytics Chart
            CaregiverAnalyticsChart(stats: dashboardState.weeklyStats),
          ],
        ),
      ),
    );
  }

  void _navigateToAddReminder(BuildContext context,
      CaregiverReminderViewModel viewModel, String patientName,
      {Reminder? existingReminder}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditReminderScreen(
          targetPatientId:
              'patient_1', // Should come from dashboardState.selectedPatientId if available
          existingReminder: existingReminder,
          onSave: (reminder) {
            if (existingReminder != null) {
              viewModel.updateReminder(reminder);
            } else {
              viewModel.addReminder(reminder);
            }
          },
        ),
      ),
    );
  }
}
