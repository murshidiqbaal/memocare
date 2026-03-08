// lib/screens/caregiver/dashboard/caregiver_dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/patient.dart';
import '../../../../data/models/reminder.dart';
import '../../../../features/location/providers/safezone_providers.dart';
import '../../../../providers/active_patient_provider.dart';
import '../../../../providers/caregiver_patients_provider.dart';
import '../../../../providers/game_analytics_provider.dart';
import '../../patient/reminders/add_edit_reminder_screen.dart';
import '../analytics/analytics_dashboard_screen.dart';
import '../reminders/caregiver_reminder_viewmodel.dart';
import '../reminders/caregiver_reminders_screen.dart';
import 'viewmodels/caregiver_dashboard_viewmodel.dart';
import 'widgets/caregiver_analytics_chart.dart';
import 'widgets/caregiver_cognitive_analytics_widget.dart';
import 'widgets/caregiver_reminder_list.dart';
import 'widgets/live_patient_map.dart';
import 'widgets/memory_review_widget.dart';
import 'widgets/patient_safety_monitor_card.dart';
import 'widgets/patient_status_card_widget.dart';
import 'widgets/sos_alert_banner.dart';
import 'widgets/weekly_analytics_card.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _DS {
  static const teal900 = Color(0xFF003D36);
  static const teal700 = Color(0xFF00695C);
  static const teal500 = Color(0xFF00897B);
  static const teal200 = Color(0xFF80CBC4);
  static const teal100 = Color(0xFFB2DFDB);
  static const teal50 = Color(0xFFE0F2F1);

  static const coral = Color(0xFFFF5252);
  static const amber = Color(0xFFFFB300);
  static const violet = Color(0xFF7C3AED);
  static const surface = Color(0xFFF8FAFB);
  static const card = Color(0xFFFFFFFF);
  static const ink900 = Color(0xFF0D1B1E);
  static const ink600 = Color(0xFF455A64);
  static const ink400 = Color(0xFF8A9EA2);
  static const ink200 = Color(0xFFCFD8DC);

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ink900.withOpacity(0.055),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get subtleCard => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ink200.withOpacity(0.6)),
      );
}

class CaregiverDashboardTab extends ConsumerStatefulWidget {
  const CaregiverDashboardTab({super.key});

  @override
  ConsumerState<CaregiverDashboardTab> createState() =>
      _CaregiverDashboardTabState();
}

class _CaregiverDashboardTabState extends ConsumerState<CaregiverDashboardTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Please select a patient first'),
            ],
          ),
          backgroundColor: _DS.teal700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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

  @override
  Widget build(BuildContext context) {
    final caregiverId = Supabase.instance.client.auth.currentUser?.id;
    if (caregiverId == null) return const _UnauthenticatedView();

    final isLoading = ref.watch(
        caregiverDashboardProvider(caregiverId).select((s) => s.isLoading));
    final isOffline = ref.watch(
        caregiverDashboardProvider(caregiverId).select((s) => s.isOffline));
    final hasPatient = ref.watch(caregiverDashboardProvider(caregiverId)
        .select((s) => s.hasPatientSelected));
    final error = ref
        .watch(caregiverDashboardProvider(caregiverId).select((s) => s.error));
    final lastUpdated = ref.watch(
        caregiverDashboardProvider(caregiverId).select((s) => s.lastUpdated));
    final unreadAlerts = ref.watch(caregiverDashboardProvider(caregiverId)
        .select((s) => s.stats.unreadAlerts));

    final dashState = ref.read(caregiverDashboardProvider(caregiverId));
    final vm = ref.read(caregiverDashboardProvider(caregiverId).notifier);
    final reminderState = ref.watch(caregiverReminderProvider);
    final reminderVm = ref.read(caregiverReminderProvider.notifier);

    final gameAnalyticsAsync = hasPatient && dashState.selectedPatientId != null
        ? ref.watch(patientGameAnalyticsProvider(dashState.selectedPatientId!))
        : null;

    return Scaffold(
      backgroundColor: _DS.surface,
      appBar: _PremiumAppBar(
        patientName: dashState.selectedPatientName,
        isOffline: isOffline,
        unreadAlerts: unreadAlerts,
        onNotificationTap: () => context.push('/notification-test'),
        onProfileTap: () => context.push('/caregiver-profile'),
      ),
      // floatingActionButton:
      //     hasPatient ? _PremiumFab(onPressed: _navigateToAddReminder) : null,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: RefreshIndicator(
            onRefresh: vm.refresh,
            color: _DS.teal700,
            backgroundColor: _DS.card,
            strokeWidth: 2.5,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // SOS banner
                      const CaregiverSosAlertBanner(),

                      // Pending Location Requests Banner (Requested status only)
                      Consumer(builder: (context, ref, child) {
                        final activePatientId =
                            ref.watch(activePatientIdProvider);
                        if (activePatientId == null)
                          return const SizedBox.shrink();

                        final requestsAsync = ref.watch(
                            patientPendingRequestsProvider(activePatientId));
                        return requestsAsync.maybeWhen(
                          data: (requests) {
                            if (requests.isEmpty)
                              return const SizedBox.shrink();
                            return _StatusBanner(
                              icon: Icons.priority_high_rounded,
                              message: 'New change request for home safe zone',
                              color: const Color(0xFFE3F2FD),
                              borderColor: Colors.blue.withOpacity(0.4),
                              iconColor: Colors.blue,
                              textColor: Colors.blue.shade900,
                              trailing: TextButton(
                                onPressed: () => context
                                    .push('/caregiver-location-requests'),
                                child: const Text('VIEW',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        );
                      }),

                      // Offline
                      if (isOffline)
                        _StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          message: lastUpdated != null
                              ? 'Offline · Last updated ${_formatLastUpdated(lastUpdated)}'
                              : 'You are offline',
                          color: const Color(0xFFFFF8E1),
                          borderColor: _DS.amber.withOpacity(0.4),
                          iconColor: _DS.amber,
                          textColor: const Color(0xFF795548),
                        ),

                      // Error
                      if (error != null)
                        _StatusBanner(
                          icon: Icons.error_outline_rounded,
                          message: error,
                          color: const Color(0xFFFFEBEE),
                          borderColor: _DS.coral.withOpacity(0.4),
                          iconColor: _DS.coral,
                          textColor: const Color(0xFFB71C1C),
                          trailing: GestureDetector(
                            onTap: vm.clearError,
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFFB71C1C)),
                          ),
                        ),

                      // No patient
                      if (!hasPatient)
                        Consumer(builder: (context, ref, child) {
                          final patientsAsync =
                              ref.watch(caregiverPatientsProvider);
                          return patientsAsync.when(
                            data: (patients) {
                              if (patients.isEmpty) {
                                return const _NoPatientEmptyState();
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Patients',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _DS.ink900,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: patients.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final patient = patients[index];
                                        return _PatientCard(
                                          patient: patient,
                                          onTap: () {
                                            ref
                                                .read(activePatientIdProvider
                                                    .notifier)
                                                .setActivePatient(patient.id);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const _SkeletonLoader(),
                            error: (err, _) =>
                                Center(child: Text('Error: $err')),
                          );
                        })
                      else ...[
                        // ── Patient Status ────────────────────────────────
                        _Section(
                          topPad: 16,
                          child: PatientStatusCard(
                              status: dashState.patientStatus),
                        ),

                        // ── Safety Monitor ────────────────────────────────
                        if (hasPatient && dashState.selectedPatientId != null)
                          _Section(
                            child: PatientSafetyMonitorCard(
                              patientId: dashState.selectedPatientId!,
                              patientName: dashState.selectedPatientName,
                              caregiverId: caregiverId,
                            ),
                          ),

                        // ── Quick Actions ─────────────────────────────────
                        _Section(
                          child: _QuickActionsRow(
                            onAnalytics: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AnalyticsDashboardScreen()),
                            ),
                            onNotificationTest: () =>
                                context.push('/notification-test'),
                          ),
                        ),

                        // ── Live Location ─────────────────────────────────
                        _SectionHeader(
                          icon: Icons.location_on_rounded,
                          title: 'Live Location',
                          badge: const _LivePill(),
                          trailing: dashState.selectedPatientId != null
                              ? _PatientTag(name: dashState.selectedPatientName)
                              : null,
                        ),
                        _Section(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: dashState.selectedPatientId == null
                                ? const _NoPatientSelectedMap()
                                : LivePatientMap(
                                    patientId: dashState.selectedPatientId!,
                                    height: 280,
                                  ),
                          ),
                        ),

                        // ── Today's Reminders ─────────────────────────────
                        _SectionHeader(
                          icon: Icons.alarm_rounded,
                          title: "Today's Reminders",
                          trailing: _PillButton(
                            label: 'Manage All',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const CaregiverRemindersScreen()),
                            ),
                          ),
                        ),
                        _Section(
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

                        // ── Analytics Overview ────────────────────────────
                        if (hasPatient && gameAnalyticsAsync != null) ...[
                          const _SectionHeader(
                            icon: Icons.bar_chart_rounded,
                            title: 'Weekly Overview',
                          ),
                          _Section(
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
                                  onViewFullAnalytics: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AnalyticsDashboardScreen()),
                                  ),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: _DS.teal500, strokeWidth: 2.5)),
                              ),
                              error: (err, _) => _StatusBanner(
                                icon: Icons.error_outline_rounded,
                                message: 'Failed to load analytics',
                                color: const Color(0xFFFFEBEE),
                                borderColor: _DS.coral.withOpacity(0.4),
                                iconColor: _DS.coral,
                                textColor: const Color(0xFFB71C1C),
                              ),
                            ),
                          ),
                        ],

                        // ── Cognitive Performance ─────────────────────────
                        if (hasPatient &&
                            dashState.selectedPatientId != null) ...[
                          const _SectionHeader(
                            icon: Icons.psychology_rounded,
                            title: 'Cognitive Performance',
                          ),
                          _Section(
                            child: CaregiverCognitiveAnalyticsWidget(
                              patientId: dashState.selectedPatientId!,
                            ),
                          ),
                        ],

                        // ── Memory Review ─────────────────────────────────
                        const _SectionHeader(
                          icon: Icons.auto_stories_rounded,
                          title: 'Memory Review',
                        ),
                        const MemoryReviewWidget(),

                        // ── Analytics Chart ───────────────────────────────
                        const _SectionHeader(
                          icon: Icons.timeline_rounded,
                          title: 'Activity Trends',
                        ),
                        _Section(
                          child: CaregiverAnalyticsChart(
                              stats: dashState.weeklyStats),
                        ),

                        const SizedBox(height: 8),
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

//no patient selected map
class _NoPatientSelectedMap extends StatelessWidget {
  const _NoPatientSelectedMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Select a patient to view live location',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient Card
// ─────────────────────────────────────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _DS.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _DS.teal50,
                image: (patient.profilePhotoUrl != null &&
                        patient.profilePhotoUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(patient.profilePhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (patient.profilePhotoUrl == null ||
                      patient.profilePhotoUrl!.isEmpty)
                  ? const Icon(Icons.person_rounded,
                      color: _DS.teal500, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _DS.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (patient.age != null || patient.condition != null)
                    Text(
                      '${patient.age != null ? "${patient.age} years old" : ""} ${patient.condition != null ? "· ${patient.condition}" : ""}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _DS.ink600,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _DS.ink400),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium AppBar
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String patientName;
  final bool isOffline;
  final int unreadAlerts;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const _PremiumAppBar({
    required this.patientName,
    required this.isOffline,
    required this.unreadAlerts,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.card,
        boxShadow: [
          BoxShadow(
            color: _DS.ink900.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
          child: Row(
            children: [
              // Logo mark
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_DS.teal700, _DS.teal500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),

              // Title + patient selector
              Expanded(
                child: Consumer(builder: (context, ref, child) {
                  final linkedPatientsAsync = ref.watch(linkedPatientsProvider);
                  if (linkedPatientsAsync.isLoading) {
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('MemoCare',
                            style: TextStyle(
                                color: _DS.ink900,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3)),
                        SizedBox(height: 1),
                        Text('Loading Patients...',
                            style: TextStyle(
                                color: _DS.teal700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    );
                  }
                  if (linkedPatientsAsync.hasError ||
                      linkedPatientsAsync.value == null ||
                      linkedPatientsAsync.value!.isEmpty) {
                    return const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('MemoCare',
                            style: TextStyle(
                                color: _DS.ink900,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3)),
                        SizedBox(height: 1),
                        Text('No Linked Patients',
                            style: TextStyle(
                                color: _DS.teal700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    );
                  }

                  final patients = linkedPatientsAsync.value!;

                  return MenuAnchor(
                    builder: (BuildContext context, MenuController controller,
                        Widget? child) {
                      return GestureDetector(
                        onTap: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'MemoCare',
                              style: TextStyle(
                                color: _DS.ink900,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _DS.teal50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _DS.teal200.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: _DS.teal500,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    patientName,
                                    style: const TextStyle(
                                      color: _DS.teal900,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: _DS.teal700, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    menuChildren: patients.map((patient) {
                      return MenuItemButton(
                        onPressed: () {
                          ref
                              .read(activePatientIdProvider.notifier)
                              .setActivePatient(patient.id);
                        },
                        leadingIcon: CircleAvatar(
                          radius: 12,
                          backgroundColor: _DS.teal100,
                          backgroundImage: patient.profileImageUrl != null &&
                                  patient.profileImageUrl!.isNotEmpty
                              ? NetworkImage(patient.profileImageUrl!)
                              : null,
                          child: patient.profileImageUrl == null ||
                                  patient.profileImageUrl!.isEmpty
                              ? Text(
                                  patient.fullName.isNotEmpty == true
                                      ? patient.fullName[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                      fontSize: 10, color: _DS.teal900))
                              : null,
                        ),
                        child: Text(patient.fullName ?? 'Linked Patient',
                            style: TextStyle(
                                fontWeight: patientName == patient.fullName
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _DS.teal900)),
                      );
                    }).toList(),
                  );
                }),
              ),

              // Actions
              if (isOffline)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            color: _DS.amber, size: 13),
                        SizedBox(width: 3),
                        Text('Offline',
                            style: TextStyle(
                                color: Color(0xFF795548),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

              // Notification bell
              _AppBarIconButton(
                icon: Icons.notifications_outlined,
                onTap: onNotificationTap,
                badge: unreadAlerts > 0 ? unreadAlerts : null,
              ),

              // Profile avatar
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  margin: const EdgeInsets.only(left: 4, right: 8),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _DS.teal100,
                        _DS.teal200,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'CG',
                      style: TextStyle(
                        color: _DS.teal900,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: _DS.ink600, size: 20),
            if (badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _DS.coral,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium FAB
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _PremiumFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_DS.teal900, _DS.teal700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _DS.teal700.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_alarm_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Add Reminder',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final Widget child;
  final double topPad;

  const _Section({required this.child, this.topPad = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad, 16, 0),
      child: child,
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _DS.teal50,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _DS.teal700, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _DS.ink900,
              letterSpacing: -0.2,
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 8), badge!],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: Color(0xFF43A047), shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E7D32),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTag extends StatelessWidget {
  final String name;
  const _PatientTag({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _DS.teal50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: const TextStyle(
            fontSize: 11, color: _DS.teal700, fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _DS.teal50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: _DS.teal700, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Banner (offline / error)
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Widget? trailing;

  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Row
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAnalytics;
  final VoidCallback onNotificationTest;

  const _QuickActionsRow({
    required this.onAnalytics,
    required this.onNotificationTest,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionTile(
      icon: Icons.analytics_rounded,
      label: 'Analytics',
      color: _DS.teal700,
      bgColor: _DS.teal50,
      onTap: onAnalytics,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: _DS.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _DS.ink900.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty & Loading States
// ─────────────────────────────────────────────────────────────────────────────

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _DS.surface,
      body: Center(
        child: Text('Not authenticated. Please log in.',
            style: TextStyle(fontSize: 15, color: _DS.ink600)),
      ),
    );
  }
}

class _NoPatientEmptyState extends StatelessWidget {
  const _NoPatientEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_DS.teal50, _DS.teal100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.person_search_rounded,
                size: 44, color: _DS.teal700),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Patients Linked',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _DS.ink900,
                letterSpacing: -0.4),
          ),
          const SizedBox(height: 10),
          const Text(
            'Connect with a patient using their invite code\nto start managing their care.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _DS.ink400, height: 1.5),
          ),
          const SizedBox(height: 32),
          // Optional: Add button here to open invite dialog or navigate to linking screen
          // Elevated/Action button if a specific linking UI exists on dashboard
        ],
      ),
    );
  }
}

class _SkeletonLoader extends StatefulWidget {
  const _SkeletonLoader();

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.4 + (_anim.value * 0.4);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: i == 0 ? 100 : 70,
                decoration: BoxDecoration(
                  color: _DS.ink200.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _EmptyAnalyticsState extends StatelessWidget {
  const _EmptyAnalyticsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.analytics_outlined,
                size: 28, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Activity Yet',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF4C1D95),
                letterSpacing: -0.2),
          ),
          const SizedBox(height: 8),
          const Text(
            'Once the patient starts playing games and following reminders, analytics will appear here.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Color(0xFF6D28D9), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
