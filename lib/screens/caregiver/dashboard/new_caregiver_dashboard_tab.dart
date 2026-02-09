import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/dashboard_repository.dart';
import '../people/caregiver_people_screen.dart';
import '../reminders/caregiver_reminders_screen.dart';
import 'viewmodels/caregiver_dashboard_viewmodel.dart';
import 'widgets/activity_summary_card.dart';
import 'widgets/patient_overview_card.dart';
import 'widgets/patient_selector.dart';
import 'widgets/reminder_adherence_card.dart';
import 'widgets/safety_status_card.dart';
import 'widgets/voice_interaction_card.dart';
import 'widgets/weekly_analytics_card.dart';

/// Provider for caregiver dashboard
final caregiverDashboardViewModelProvider = StateNotifierProvider.family<
    CaregiverDashboardViewModel,
    CaregiverDashboardState,
    String>((ref, caregiverId) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return CaregiverDashboardViewModel(repository, caregiverId);
});

/// Caregiver Dashboard Tab - Main Screen
///
/// Central control interface for caregivers to monitor and manage patients
///
/// Features:
/// - Patient selector dropdown
/// - Patient overview with status and quick actions
/// - Reminder adherence monitoring
/// - Memory & people activity summary
/// - Voice interaction history
/// - Geo-fencing safety status
/// - Weekly analytics and insights
/// - Offline-first with sync status
class NewCaregiverDashboardTab extends ConsumerStatefulWidget {
  const NewCaregiverDashboardTab({super.key});

  @override
  ConsumerState<NewCaregiverDashboardTab> createState() =>
      _NewCaregiverDashboardTabState();
}

class _NewCaregiverDashboardTabState
    extends ConsumerState<NewCaregiverDashboardTab> {
  @override
  Widget build(BuildContext context) {
    // Get current caregiver ID from auth
    final caregiverId = Supabase.instance.client.auth.currentUser?.id;

    if (caregiverId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Not authenticated'),
        ),
      );
    }

    final state = ref.watch(caregiverDashboardViewModelProvider(caregiverId));
    final viewModel =
        ref.read(caregiverDashboardViewModelProvider(caregiverId).notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Caregiver Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: state.isLoading ? Colors.grey : Colors.teal.shade700,
            ),
            onPressed: state.isLoading ? null : viewModel.refresh,
            tooltip: 'Refresh',
          ),
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (state.stats.unreadAlerts > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        state.stats.unreadAlerts.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              // TODO: Navigate to alerts screen
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: state.isLoading && state.linkedPatients.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offline status banner
                    if (state.isOffline)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Offline Mode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (state.lastUpdated != null)
                                    Text(
                                      'Last updated: ${_formatLastUpdated(state.lastUpdated!)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Error message
                    if (state.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: viewModel.clearError,
                              color: Colors.red.shade700,
                            ),
                          ],
                        ),
                      ),

                    // 1. Patient Selector
                    PatientSelector(
                      patients: state.linkedPatients,
                      selectedPatient: state.selectedPatient,
                      onPatientSelected: viewModel.selectPatient,
                    ),

                    const SizedBox(height: 20),

                    // 2. Patient Overview Card
                    if (state.selectedPatient != null)
                      PatientOverviewCard(
                        patient: state.selectedPatient!,
                        isInSafeZone: state.stats.isInSafeZone,
                        nextReminder: state.nextReminder,
                        lastActivity: state.stats.lastVoiceInteraction,
                        onCallPressed: () => _handleCallPatient(context),
                        onLocationPressed: () => _handleViewLocation(context),
                      ),

                    const SizedBox(height: 20),

                    // 3. Reminder Adherence Card
                    ReminderAdherenceCard(
                      completed: state.stats.remindersCompleted,
                      pending: state.stats.remindersPending,
                      missed: state.stats.remindersMissed,
                      adherencePercentage: state.stats.adherencePercentage,
                      onViewAllPressed: () => _navigateToReminders(context),
                    ),

                    const SizedBox(height: 20),

                    // 4. Safety Status Card
                    SafetyStatusCard(
                      isInSafeZone: state.stats.isInSafeZone,
                      breachesThisWeek: state.stats.safeZoneBreachesThisWeek,
                      lastLocationUpdate: state.stats.lastLocationUpdate,
                      onViewLocationPressed: () => _handleViewLocation(context),
                    ),

                    const SizedBox(height: 20),

                    // 5. Activity Summary Card
                    ActivitySummaryCard(
                      memoryCardsCount: state.stats.memoryCardsCount,
                      peopleCardsCount: state.stats.peopleCardsCount,
                      lastJournalEntry: state.stats.lastJournalEntry,
                      onManageCardsPressed: () =>
                          _navigateToMemoryPeople(context),
                    ),

                    const SizedBox(height: 20),

                    // 6. Voice Interaction Card
                    VoiceInteractionCard(
                      recentInteractions: state.recentVoiceInteractions,
                      onViewAllPressed: () => _navigateToVoiceHistory(context),
                    ),

                    const SizedBox(height: 20),

                    // 7. Weekly Analytics Card
                    WeeklyAnalyticsCard(
                      adherencePercentage: state.stats.adherencePercentage,
                      gamesPlayed: state.stats.gamesPlayedThisWeek,
                      journalConsistency: state.stats.memoryJournalConsistency,
                      safeZoneBreaches: state.stats.safeZoneBreachesThisWeek,
                      insightMessage: state.stats.insightMessage,
                      onViewFullAnalytics: () => _navigateToAnalytics(context),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatLastUpdated(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _handleCallPatient(BuildContext context) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call functionality coming soon')),
    );
  }

  void _handleViewLocation(BuildContext context) {
    // TODO: Navigate to live map screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location tracking coming soon')),
    );
  }

  void _navigateToReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CaregiverRemindersScreen(),
      ),
    );
  }

  void _navigateToMemoryPeople(BuildContext context) {
    final state = ref.read(caregiverDashboardViewModelProvider(
        Supabase.instance.client.auth.currentUser!.id));

    if (state.selectedPatient == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverPeopleScreen(
          patientId: state.selectedPatient!.patientId,
        ),
      ),
    );
  }

  void _navigateToVoiceHistory(BuildContext context) {
    // TODO: Create voice history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice history screen coming soon')),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    // TODO: Navigate to full analytics screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full analytics coming soon')),
    );
  }
}

// Provider for dashboard repository (to be added to service_providers.dart)
final dashboardRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DashboardRepository(supabase);
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
