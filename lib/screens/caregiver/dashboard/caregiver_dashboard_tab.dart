// lib/screens/caregiver/dashboard/caregiver_dashboard_tab.dart
//
// ─── LAYER 2: Smart Dashboard Tab ────────────────────────────────────────────
//
// Single unified dashboard tab that:
//   • Reads ONLY from caregiverDashboardProvider (no local state)
//   • Reacts to patientSelectionProvider automatically via the ViewModel
//   • Supports pull-to-refresh
//   • Shows proper empty states (no patient / loading / offline / error)
//   • Has entrance animation on first load
//   • Is navigation-safe (mounted checks, no context after await)
//   • Uses const where possible
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/reminder.dart';
import '../../../../features/live_location/presentation/widgets/live_location_map_widget.dart';
import '../../../../features/patient_selection/presentation/widgets/patient_bottom_sheet_picker.dart';
import '../../../../providers/game_analytics_provider.dart';
import '../../patient/reminders/add_edit_reminder_screen.dart';
import '../analytics/analytics_dashboard_screen.dart';
import '../reminders/caregiver_reminder_viewmodel.dart';
import '../reminders/caregiver_reminders_screen.dart';
import 'viewmodels/caregiver_dashboard_viewmodel.dart';
import 'widgets/caregiver_analytics_chart.dart';
import 'widgets/caregiver_reminder_list.dart';
import 'widgets/memory_review_widget.dart';
import 'widgets/patient_safety_monitor_card.dart'; // Added
import 'widgets/caregiver_cognitive_analytics_widget.dart'; // Added
import 'widgets/patient_status_card_widget.dart';
import 'widgets/weekly_analytics_card.dart';

class CaregiverDashboardTab extends ConsumerStatefulWidget {
  const CaregiverDashboardTab({super.key});

  @override
  ConsumerState<CaregiverDashboardTab> createState() =>
      _CaregiverDashboardTabState();
}

class _CaregiverDashboardTabState extends ConsumerState<CaregiverDashboardTab>
    with SingleTickerProviderStateMixin {
  // ── Entrance animation controller ─────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    // Trigger entrance animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatLastUpdated(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _navigateToAddReminder({Reminder? existing}) {
    final state = ref.read(
      caregiverDashboardProvider(Supabase.instance.client.auth.currentUser!.id),
    );
    final patientId = state.selectedPatientId;
    if (patientId == null || patientId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final vm = ref.read(caregiverReminderProvider.notifier);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditReminderScreen(
          targetPatientId: patientId,
          existingReminder: existing,
          onSave: (reminder) {
            if (existing != null) {
              vm.updateReminder(reminder);
            } else {
              vm.addReminder(reminder);
            }
          },
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final caregiverId = Supabase.instance.client.auth.currentUser?.id;
    if (caregiverId == null) return const _UnauthenticatedView();

    // ── Selector-scoped watches ─────────────────────────────────────────────
    // Each .select() call rebuilds this widget ONLY when its slice changes.
    final isLoading = ref.watch(
      caregiverDashboardProvider(caregiverId).select((s) => s.isLoading),
    );
    final isOffline = ref.watch(
      caregiverDashboardProvider(caregiverId).select((s) => s.isOffline),
    );
    final hasPatient = ref.watch(
      caregiverDashboardProvider(caregiverId)
          .select((s) => s.hasPatientSelected),
    );
    final error = ref.watch(
      caregiverDashboardProvider(caregiverId).select((s) => s.error),
    );
    final lastUpdated = ref.watch(
      caregiverDashboardProvider(caregiverId).select((s) => s.lastUpdated),
    );
    final unreadAlerts = ref.watch(
      caregiverDashboardProvider(caregiverId)
          .select((s) => s.stats.unreadAlerts),
    );

    // Full state — read only where needed to avoid broad rebuilds
    final dashState = ref.read(caregiverDashboardProvider(caregiverId));
    final vm = ref.read(caregiverDashboardProvider(caregiverId).notifier);
    final reminderState = ref.watch(caregiverReminderProvider);
    final reminderVm = ref.read(caregiverReminderProvider.notifier);

    // Watch game analytics for current patient
    final gameAnalyticsAsync = hasPatient && dashState.selectedPatientId != null
        ? ref.watch(patientGameAnalyticsProvider(dashState.selectedPatientId!))
        : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _DashboardAppBar(
        patientName: dashState.selectedPatientName,
        isOffline: isOffline,
        unreadAlerts: unreadAlerts,
        onNotificationTap: () => context.push('/notification-test'),
        onProfileTap: () => context.push('/caregiver-profile'),
        onPatientPickerTap: () => PatientBottomSheetPicker.show(context, ref),
      ),
      floatingActionButton: hasPatient
          ? FloatingActionButton(
              onPressed: _navigateToAddReminder,
              backgroundColor: Colors.teal,
              tooltip: 'Add reminder',
              child: const Icon(Icons.add_alert, color: Colors.white),
            )
          : null,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: RefreshIndicator(
            onRefresh: vm.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 80),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Offline banner ──────────────────────────────────
                      if (isOffline)
                        _OfflineBanner(
                          lastUpdated: lastUpdated,
                          formatTime: _formatLastUpdated,
                        ),

                      // ── Error banner ────────────────────────────────────
                      if (error != null)
                        _ErrorBanner(
                          message: error,
                          onDismiss: vm.clearError,
                        ),

                      // ── No-patient empty state ──────────────────────────
                      if (!hasPatient && !isLoading)
                        _NoPatientEmptyState(
                          onSelectPatient: () =>
                              PatientBottomSheetPicker.show(context, ref),
                        )
                      else if (isLoading && !hasPatient)
                        const _SkeletonLoader()
                      else ...[
                        // ── 1. Patient Status ─────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: PatientStatusCard(
                              status: dashState.patientStatus),
                        ),

                        // ── 1.5 Patient Safety Monitor ─────────────────────
                        if (hasPatient && dashState.selectedPatientId != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: PatientSafetyMonitorCard(
                              patientId: dashState.selectedPatientId!,
                              patientName: dashState.selectedPatientName,
                              caregiverId: caregiverId,
                            ),
                          ),

                        // ── 2. Quick Actions ──────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: _QuickActionsRow(
                            onAnalytics: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AnalyticsDashboardScreen(),
                              ),
                            ),
                            onNotificationTest: () =>
                                context.push('/notification-test'),
                          ),
                        ),

                        // ── 3. Live Location ──────────────────────────────
                        _SectionHeader(
                          icon: Icons.location_on,
                          title: 'Live Location',
                          badge: _LiveBadge(),
                          trailing: dashState.selectedPatientName !=
                                  'No Patient Selected'
                              ? _PatientChip(
                                  name: dashState.selectedPatientName)
                              : null,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: LiveLocationMapWidget(height: 280),
                        ),

                        const SizedBox(height: 16),

                        // ── 4. Today's Reminders ──────────────────────────
                        _SectionHeader(
                          icon: Icons.alarm,
                          title: "Today's Reminders",
                          trailing: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CaregiverRemindersScreen(),
                              ),
                            ),
                            child: const Text('Manage All'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CaregiverReminderList(
                            reminders: reminderState.reminders
                                .where((r) {
                                  final now = DateTime.now();
                                  return r.reminderTime.day == now.day &&
                                      r.reminderTime.month == now.month &&
                                      r.reminderTime.year == now.year;
                                })
                                .take(5)
                                .toList(),
                            onDelete: reminderVm.deleteReminder,
                            onEdit: (r) => _navigateToAddReminder(existing: r),
                            onAdd: _navigateToAddReminder,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── 5. Analytics Overview ────────────────────────────────
                        if (hasPatient && gameAnalyticsAsync != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: gameAnalyticsAsync.when(
                              data: (stats) {
                                if (stats.gamesPlayedThisWeek == 0 &&
                                    dashState.stats.adherencePercentage == 0) {
                                  return const _EmptyAnalyticsState();
                                }
                                return WeeklyAnalyticsCard(
                                  adherencePercentage:
                                      dashState.stats.adherencePercentage,
                                  gameStats: stats,
                                  journalConsistency:
                                      dashState.stats.memoryJournalConsistency,
                                  safeZoneBreaches:
                                      dashState.stats.safeZoneBreachesThisWeek,
                                  insightMessage:
                                      dashState.stats.insightMessage,
                                  onViewFullAnalytics: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const AnalyticsDashboardScreen()));
                                  },
                                );
                              },
                              loading: () => const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.teal)),
                              error: (err, stack) => _ErrorBanner(
                                message: 'Failed to load game analytics: $err',
                                onDismiss: () {},
                              ),
                            ),
                          ),

                        // ── 5.5 Cognitive Performance (NEW) ────────────────
                        if (hasPatient && dashState.selectedPatientId != null)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 16),
                            child: CaregiverCognitiveAnalyticsWidget(
                              patientId: dashState.selectedPatientId!,
                            ),
                          ),

                        // ── 6. Memory Review ──────────────────────────────
                        const MemoryReviewWidget(),

                        const SizedBox(height: 16),

                        // ── 7. Analytics Chart ────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CaregiverAnalyticsChart(
                              stats: dashState.weeklyStats),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar — PreferredSizeWidget extracted to avoid rebuilding entire scaffold
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String patientName;
  final bool isOffline;
  final int unreadAlerts;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final VoidCallback onPatientPickerTap;

  const _DashboardAppBar({
    required this.patientName,
    required this.isOffline,
    required this.unreadAlerts,
    required this.onNotificationTap,
    required this.onProfileTap,
    required this.onPatientPickerTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: GestureDetector(
        onTap: onPatientPickerTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MemoCare',
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Monitoring: $patientName',
                  style: TextStyle(
                      color: Colors.teal.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                Icon(Icons.arrow_drop_down,
                    color: Colors.teal.shade700, size: 18),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (isOffline)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.wifi_off, color: Colors.orange),
          ),
        // Notifications with badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: onNotificationTap,
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.black54),
              tooltip: 'Notifications',
            ),
            if (unreadAlerts > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$unreadAlerts',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.teal.shade100,
              child: const Text('CG',
                  style: TextStyle(
                      color: Colors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty States
// ─────────────────────────────────────────────────────────────────────────────

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Not authenticated. Please log in.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _NoPatientEmptyState extends StatelessWidget {
  final VoidCallback onSelectPatient;

  const _NoPatientEmptyState({required this.onSelectPatient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 72, color: Colors.teal.shade200),
          const SizedBox(height: 20),
          const Text(
            'No Patient Selected',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            'Select a patient to view insights and manage their care.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onSelectPatient,
            icon: const Icon(Icons.people_alt_outlined),
            label: const Text('Choose Patient'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator(color: Colors.teal)),
    );
  }
}

class _EmptyAnalyticsState extends StatelessWidget {
  const _EmptyAnalyticsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined,
              size: 48, color: Colors.purple.shade300),
          const SizedBox(height: 16),
          const Text('No Activity Yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Once the patient starts playing games and adhering to reminders, analytics will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.purple.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banners
// ─────────────────────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final DateTime? lastUpdated;
  final String Function(DateTime) formatTime;

  const _OfflineBanner({required this.lastUpdated, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Offline Mode',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (lastUpdated != null)
                  Text('Last updated: ${formatTime(lastUpdated!)}',
                      style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
            color: Colors.red.shade700,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? badge;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.badge,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 6),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (badge != null) ...[const SizedBox(width: 8), badge!],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text('LIVE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _PatientChip extends StatelessWidget {
  final String name;
  const _PatientChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: TextStyle(
            fontSize: 12,
            color: Colors.teal.shade700,
            fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAnalytics;
  final VoidCallback onNotificationTest;

  const _QuickActionsRow({
    required this.onAnalytics,
    required this.onNotificationTest,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAnalytics,
            icon: const Icon(Icons.analytics, size: 18),
            label: const Text('Analytics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              elevation: 1,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // DEV only — remove in production
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNotificationTest,
            icon: const Icon(Icons.science_outlined, size: 16),
            label: const Text('Test Notifs'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              side: const BorderSide(color: Colors.deepPurple),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
