import 'package:memocare/features/auth/providers/auth_provider.dart';
import 'package:memocare/features/patient/presentation/screens/games/games_screen.dart';
import 'package:memocare/features/patient/presentation/screens/home/viewmodels/home_viewmodel.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/caregiver_dash_card.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/memory_highlight_widget.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/offline_status_widget.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/patient_app_bar_widget.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/reminder_section_card.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/safety_status_card.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/section_title.dart';
import 'package:memocare/features/patient/presentation/screens/home_location/patient_set_home_location_screen.dart';
import 'package:memocare/features/patient/presentation/screens/memories/memories_screen.dart';
import 'package:memocare/features/patient/presentation/screens/reminders/add_edit_reminder_screen.dart';
import 'package:memocare/features/patient/presentation/screens/reminders/reminder_list_screen.dart';
import 'package:memocare/features/patient/presentation/screens/sos/patient_sos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Patient Dashboard Tab - Healthcare-grade dementia-friendly UI
///
/// Production-level improvements:
/// ✅ Today's Reminders as primary visual focus
/// ✅ Floating Action Button (for reminders)
/// ✅ Separated emergency SOS card
/// ✅ Simplified quick actions (3 safe actions only)
/// ✅ Emotional memory highlight design
/// ✅ Time & orientation context header
/// ✅ Enhanced offline indicator with supportive messaging
/// ✅ Large-text accessibility support
/// ✅ Minimum 48-56px touch targets
/// ✅ Calm, clear, emotionally supportive design
///
/// Widget Architecture:
/// - PatientAppBar (greeting & notifications)
/// - TimeContextHeader (daily orientation)
/// - OfflineStatusIndicator (supportive offline messaging)
/// - ReminderSectionCard (primary focus with teal tint)
/// - QuickActionGrid (3 safe actions only)
/// - EmergencySOSCard (separated red emergency card)
/// - MemoryHighlightCard (emotional recall design)
/// - FloatingActionButton (elder-friendly action)
class PatientDashboardTab extends ConsumerWidget {
  const PatientDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // Minimal AppBar as requested
      appBar: const PatientAppBar(),
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Section Padding (if TimeHeader is inside padding)
                  // User requested: "Body Structure: ... padding: 16.0"
                  // But TimeHeader "at the very top".
                  // I will apply padding to the Column itself as requested.
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Offline Indicator
                        if (homeState.isOffline) ...[
                          OfflineStatusIndicator(
                              isOffline: homeState.isOffline),
                          SizedBox(height: 12 * scale),
                        ],

                        // Caregiver Card (Top of Dashboard)
                        const CaregiverDashCard(), // Added widget

                        // Safety Status Card
                        if (profileAsync.value != null) ...[
                          SizedBox(height: 12 * scale),
                          SafetyStatusCard(patientId: profileAsync.value!.id),
                        ],

                        SizedBox(height: 24 * scale),

                        // Reminder Section
                        ReminderSectionCard(
                          onAddPressed: () => _navigateToAddReminder(context),
                          onViewAllPressed: () => _navigateToReminders(context),
                        ),

                        SizedBox(height: 24 * scale),

                        // Quick Actions Section
                        // const SectionTitle(title: 'Quick Actions'),
                        // SizedBox(height: 12 * scale),
                        // QuickActionGrid(
                        //   onMemoriesTap: () => _navigateToMemories(context),
                        //   onGamesTap: () => _navigateToGames(context),
                        //   onLocationTap: () =>
                        //       _navigateToLocation(context, ref),
                        // ),

                        SizedBox(height: 24 * scale),

                        // Memory Section
                        const SectionTitle(title: 'Memory of the Day'),
                        SizedBox(height: 12 * scale),
                        MemoryHighlightCard(
                          onViewDay: () => _navigateToMemories(context),
                        ),
                        SizedBox(
                            height: 24 * scale), // Spacing before Quick Actions

                        const SizedBox(height: 16),
                        // Quick Test Button for Local Notifications
                        // ElevatedButton.icon(
                        //   onPressed: () async {
                        //     final notifService =
                        //         ref.read(reminderNotificationServiceProvider);
                        //     await notifService.showEmergencyNotification(
                        //       title: 'Test Local Popup',
                        //       body:
                        //           'This notification uses your new launcher icon!',
                        //     );
                        //   },
                        //   icon: const Icon(Icons.notifications_active),
                        //   label: const Text('Test Local Notification'),
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: Colors.deepPurple,
                        //     foregroundColor: Colors.white,
                        //     padding: const EdgeInsets.symmetric(vertical: 16),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(16),
                        //     ),
                        //   ),
                        // ),
                        // SizedBox(height: 24 * scale),

                        // // Emergency SOS
                        // EmergencySOSCard(
                        //   onTap: () => _showSOSCountdown(context, ref),
                        // ),

                        // Extra spacing for Sticky Bar safe area
                        // SizedBox(height: 100 * scale),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddReminder(context),
        // label: const Text('Add Reminder',
        //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        child: const Icon(Icons.add_alert),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Navigation Methods
  void _navigateToReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReminderListScreen()),
    );
  }

  void _navigateToAddReminder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditReminderScreen()),
    );
  }

  void _navigateToMemories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemoriesScreen()),
    );
  }

  void _navigateToGames(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GamesScreen()),
    );
  }

  void _navigateToLocation(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              PatientSetHomeLocationScreen(patientId: profile.id)),
    );
  }

  /// Show emergency SOS countdown dialog
  void _showSOSCountdown(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatientSOSScreen()),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (context) => const PatientSOSScreen(),
    );
  }
}
