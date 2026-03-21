import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memocare/data/models/patient.dart';
import 'package:memocare/data/models/reminder.dart';
import 'package:memocare/features/caregiver/presentation/screens/analytics/analytics_dashboard_screen.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/viewmodels/caregiver_dashboard_viewmodel.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/widgets/caregiver_analytics_chart.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/widgets/caregiver_cognitive_analytics_widget.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/widgets/caregiver_reminder_list.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/widgets/live_patient_map.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/widgets/memory_review_widget.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/widgets/weekly_analytics_card.dart';
import 'package:memocare/features/caregiver/presentation/screens/profile/caregiver_profile_screen.dart';
import 'package:memocare/features/caregiver/presentation/screens/reminders/caregiver_reminder_viewmodel.dart';
import 'package:memocare/features/caregiver/presentation/screens/reminders/caregiver_reminders_screen.dart';
// import 'package:memocare/features/caregiver/presentation/screens/sos/sos_alerts_section.dart';
import 'package:memocare/features/location/providers/safezone_providers.dart';
import 'package:memocare/features/patient/presentation/screens/reminders/add_edit_reminder_screen.dart';
import 'package:memocare/providers/active_patient_provider.dart';
import 'package:memocare/providers/game_analytics_provider.dart';
import 'package:memocare/providers/sos_alert_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────
class _DS {
  // Teal family
  static const teal900 = Color(0xFF003D36);
  static const teal700 = Color(0xFF00695C);
  static const teal500 = Color(0xFF00897B);
  static const teal300 = Color(0xFF4DB6AC);
  static const teal200 = Color(0xFF80CBC4);
  static const teal100 = Color(0xFFB2DFDB);
  static const teal50 = Color(0xFFE0F2F1);

  // Accents
  static const coral = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const violet = Color(0xFF7C3AED);
  static const green = Color(0xFF22C55E);

  // Surfaces
  static const bg = Color(0xFFF4F7F6);
  static const card = Color(0xFFFFFFFF);
  static const ink900 = Color(0xFF0D1B1E);
  static const ink700 = Color(0xFF2D4A52);
  static const ink600 = Color(0xFF455A64);
  static const ink400 = Color(0xFF8A9EA2);
  static const ink200 = Color(0xFFCFD8DC);
  static const ink100 = Color(0xFFECF0F1);

  static BoxDecoration cardDeco({Color? accentColor}) => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: accentColor != null
            ? Border.all(color: accentColor.withOpacity(0.2), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003D36).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            offset: Offset(-1, -1),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────
//  Main dashboard
// ─────────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  void _goAddReminder({Reminder? existing}) {
    final state = ref.read(
      caregiverDashboardProvider(Supabase.instance.client.auth.currentUser!.id),
    );
    final patientId = state.selectedPatientId;
    if (patientId == null || patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.info_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Please select a patient first'),
          ]),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditReminderScreen(
          targetPatientId: patientId,
          existingReminder: existing,
          onSave: (r) =>
              existing != null ? vm.updateReminder(r) : vm.addReminder(r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caregiverId = Supabase.instance.client.auth.currentUser?.id;
    if (caregiverId == null) return const _UnauthView();

    final dashState = ref.watch(caregiverDashboardProvider(caregiverId));
    final vm = ref.read(caregiverDashboardProvider(caregiverId).notifier);

    final isOffline = dashState.isOffline;
    final hasPatient = dashState.hasPatientSelected;
    final error = dashState.error;
    final lastUpdated = dashState.lastUpdated;

    final reminderState = ref.watch(caregiverReminderProvider);
    final reminderVm = ref.read(caregiverReminderProvider.notifier);

    final gameAnalyticsAsync = hasPatient && dashState.selectedPatientId != null
        ? ref.watch(patientGameAnalyticsProvider(dashState.selectedPatientId!))
        : null;

    // ── SOS — new sosAlertProvider (NotifierProvider.family) ──
    // Returns SosAlertState directly (no AsyncValue wrapper).
    final _sosPid = dashState.selectedPatientId ?? '';
    final sosState = ref.watch(sosAlertProvider(_sosPid));
    final sosNote = ref.read(sosAlertProvider(_sosPid).notifier);

    return Scaffold(
      backgroundColor: _DS.bg,
      appBar: _AppBar(
        patientName: dashState.selectedPatientName,
        isOffline: isOffline,
        sosCount: sosState.unreadCount,
        onProfileTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CaregiverProfileScreen()),
        ),
      ),
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
                  padding: const EdgeInsets.only(bottom: 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── SOS Banner (patient-scoped) ──────────────────
                      Builder(builder: (_) {
                        if (sosState.isLoading) return const SizedBox.shrink();
                        final unread = sosState.unread;
                        if (unread.isEmpty) return const SizedBox.shrink();
                        final latest = unread.first;
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _SOSBanner(
                            message: latest.note,
                            timeAgo: _timeAgo(latest.triggeredAt),
                            count: sosState.unreadCount,
                            status: latest.status,
                            hasLocation: latest.hasLocation,
                            onAcknowledge: () => sosNote.acknowledge(latest.id),
                            onAcknowledgeAll: () => sosNote.acknowledgeAll(),
                          ),
                        );
                      }),
                      // SizedBox(height: 10),
                      // ── Pending location requests ────────────────────
                      Consumer(builder: (context, ref, child) {
                        final pid = ref.watch(activePatientIdProvider);
                        if (pid == null) return const SizedBox.shrink();
                        return ref
                            .watch(patientPendingRequestsProvider(pid))
                            .maybeWhen(
                              data: (reqs) => reqs.isEmpty
                                  ? const SizedBox.shrink()
                                  : _StatusBanner(
                                      icon: Icons.my_location_rounded,
                                      message:
                                          'New safe zone change request pending',
                                      color: const Color(0xFFEFF6FF),
                                      borderColor:
                                          Colors.blue.withOpacity(0.35),
                                      iconColor: Colors.blue,
                                      textColor: const Color(0xFF1E3A8A),
                                      trailing: _PillButton(
                                        label: 'View',
                                        color: Colors.blue,
                                        onTap: () => context.push(
                                            '/caregiver-location-requests'),
                                      ),
                                    ),
                              orElse: () => const SizedBox.shrink(),
                            );
                      }),

                      // ── Offline ──────────────────────────────────────
                      if (isOffline)
                        _StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          message: lastUpdated != null
                              ? 'Offline · updated ${_timeAgo(lastUpdated)}'
                              : 'You are offline',
                          color: const Color(0xFFFFFBEB),
                          borderColor: _DS.amber.withOpacity(0.4),
                          iconColor: _DS.amber,
                          textColor: const Color(0xFF78350F),
                        ),

                      // ── Error ────────────────────────────────────────
                      if (error != null)
                        _StatusBanner(
                          icon: Icons.error_outline_rounded,
                          message: error,
                          color: const Color(0xFFFEF2F2),
                          borderColor: _DS.coral.withOpacity(0.4),
                          iconColor: _DS.coral,
                          textColor: const Color(0xFF991B1B),
                          trailing: GestureDetector(
                            onTap: vm.clearError,
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF991B1B)),
                          ),
                        ),

                      // ── No patient ───────────────────────────────────
                      if (!hasPatient)
                        Consumer(builder: (context, ref, child) {
                          return ref.watch(linkedPatientsProvider).when(
                                data: (patients) => patients.isEmpty
                                    ? const _NoPatientEmptyState()
                                    : _PatientPickerSection(patients: patients),
                                loading: () => const _SkeletonLoader(),
                                error: (e, _) => _StatusBanner(
                                  icon: Icons.error_outline_rounded,
                                  message: 'Failed to load patients',
                                  color: const Color(0xFFFEF2F2),
                                  borderColor: _DS.coral.withOpacity(0.4),
                                  iconColor: _DS.coral,
                                  textColor: const Color(0xFF991B1B),
                                ),
                              );
                        })
                      else ...[
                        // ── Patient status card ──────────────────────
                        // _Pad(
                        //   top: 20,
                        //   child: PatientStatusCard(
                        //       status: dashState.patientStatus),
                        // ),

                        // ── Safety monitor ───────────────────────────
                        // if (dashState.selectedPatientId != null)
                        //   _Pad(
                        //     child: PatientSafetyMonitorCard(
                        //       patientId: dashState.selectedPatientId!,
                        //       patientName: dashState.selectedPatientName,
                        //       caregiverId: caregiverId,
                        //     ),
                        //   ),

                        // ── Analytics quick link ─────────────────────
                        _Pad(
                          child: _AnalyticsTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AnalyticsDashboardScreen()),
                            ),
                          ),
                        ),

                        // ── Live Location ────────────────────────────
                        _SectionHeader(
                          icon: Icons.location_on_rounded,
                          title: 'Live Location',
                          color: _DS.teal700,
                          badge: const _LivePill(),
                          trailing: dashState.selectedPatientId != null
                              ? _PatientTag(name: dashState.selectedPatientName)
                              : null,
                        ),
                        _Pad(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: dashState.selectedPatientId == null
                                ? const _NoPatientMap()
                                : LivePatientMap(
                                    patientId: dashState.selectedPatientId!,
                                    height: 280,
                                  ),
                          ),
                        ),

                        // ── Reminders ────────────────────────────────
                        _SectionHeader(
                          icon: Icons.alarm_rounded,
                          title: "Today's Reminders",
                          color: _DS.violet,
                          trailing: Row(
                            children: [
                              _PillButton(
                                label: '+ Add',
                                color: _DS.teal700,
                                onTap: _goAddReminder,
                              ),
                              const SizedBox(width: 8),
                              _PillButton(
                                label: 'All',
                                color: _DS.ink600,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const CaregiverRemindersScreen()),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Pad(
                          child: CaregiverReminderList(
                            reminders: reminderState.reminders
                                .where((r) {
                                  final n = DateTime.now();
                                  return r.reminderTime.day == n.day &&
                                      r.reminderTime.month == n.month &&
                                      r.reminderTime.year == n.year;
                                })
                                .take(5)
                                .toList(),
                            onDelete: reminderVm.deleteReminder,
                            onEdit: (r) => _goAddReminder(existing: r),
                            onAdd: _goAddReminder,
                          ),
                        ),

                        // ── Weekly overview ──────────────────────────
                        if (hasPatient && gameAnalyticsAsync != null) ...[
                          _SectionHeader(
                            icon: Icons.bar_chart_rounded,
                            title: 'Weekly Overview',
                            color: _DS.amber,
                          ),
                          _Pad(
                            child: gameAnalyticsAsync.when(
                              data: (stats) => stats.gamesPlayedThisWeek == 0 &&
                                      dashState.stats.adherencePercentage == 0
                                  ? const _EmptyAnalytics()
                                  : WeeklyAnalyticsCard(
                                      adherencePercentage:
                                          dashState.stats.adherencePercentage,
                                      gameStats: stats,
                                      journalConsistency: dashState
                                          .stats.memoryJournalConsistency,
                                      safeZoneBreaches: dashState
                                          .stats.safeZoneBreachesThisWeek,
                                      insightMessage:
                                          dashState.stats.insightMessage,
                                      onViewFullAnalytics: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const AnalyticsDashboardScreen()),
                                      ),
                                    ),
                              loading: () => const _CardSpinner(),
                              error: (_, __) => _StatusBanner(
                                icon: Icons.error_outline_rounded,
                                message: 'Failed to load analytics',
                                color: const Color(0xFFFEF2F2),
                                borderColor: _DS.coral.withOpacity(0.4),
                                iconColor: _DS.coral,
                                textColor: const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],

                        // ── Cognitive performance ────────────────────
                        if (hasPatient &&
                            dashState.selectedPatientId != null) ...[
                          _SectionHeader(
                            icon: Icons.psychology_rounded,
                            title: 'Cognitive Performance',
                            color: _DS.violet,
                          ),
                          _Pad(
                            child: CaregiverCognitiveAnalyticsWidget(
                              patientId: dashState.selectedPatientId!,
                            ),
                          ),
                        ],

                        // ── Memory review ────────────────────────────
                        _SectionHeader(
                          icon: Icons.auto_stories_rounded,
                          title: 'Memory Review',
                          color: _DS.teal500,
                        ),
                        const MemoryReviewWidget(),

                        // ── Activity trends ──────────────────────────
                        _SectionHeader(
                          icon: Icons.timeline_rounded,
                          title: 'Activity Trends',
                          color: _DS.teal700,
                        ),
                        _Pad(
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

// ─────────────────────────────────────────────────────────────
//  SOS Banner  (uses SosAlert fields: triggeredAt, status, hasLocation)
// ─────────────────────────────────────────────────────────────
class _SOSBanner extends StatefulWidget {
  const _SOSBanner({
    required this.message,
    required this.timeAgo,
    required this.count,
    required this.status,
    required this.hasLocation,
    required this.onAcknowledge,
    required this.onAcknowledgeAll,
  });

  final String message;
  final String timeAgo;
  final int count;
  final String status; // 'pending' | 'acknowledged' | 'resolved'
  final bool hasLocation;
  final VoidCallback onAcknowledge;
  final VoidCallback onAcknowledgeAll;

  @override
  State<_SOSBanner> createState() => _SOSBannerState();
}

class _SOSBannerState extends State<_SOSBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.status.toLowerCase()) {
      case 'acknowledged':
        return _DS.amber;
      case 'resolved':
        return const Color(0xFF16A34A);
      default:
        return _DS.coral; // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DS.coral.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _DS.coral.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top row ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pulsing icon
                AnimatedBuilder(
                  animation: _scale,
                  builder: (_, child) =>
                      Transform.scale(scale: _scale.value, child: child),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _DS.coral,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: _DS.coral.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sos_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),

                // Text block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + count badge + status chip
                      Row(children: [
                        const Text(
                          'SOS Alert',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7F1D1D),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (widget.count > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _DS.coral,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.count}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: _statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      // Message
                      Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF991B1B),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Location pill (if patient shared GPS)
                      if (widget.hasLocation) ...[
                        const SizedBox(height: 6),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.place_rounded,
                              size: 12, color: _DS.coral.withOpacity(0.75)),
                          const SizedBox(width: 4),
                          Text(
                            'Location attached — tap to view',
                            style: TextStyle(
                              fontSize: 11,
                              color: _DS.coral.withOpacity(0.85),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),

                // Acknowledge (✕) button
                GestureDetector(
                  onTap: widget.onAcknowledge,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _DS.coral.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 16, color: Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
          ),

          // ── Footer row ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _DS.coral.withOpacity(0.07),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(17)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Icon(Icons.schedule_rounded,
                  size: 13, color: _DS.coral.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(
                widget.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: _DS.coral.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              if (widget.count > 1)
                GestureDetector(
                  onTap: widget.onAcknowledgeAll,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _DS.coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _DS.coral.withOpacity(0.25)),
                    ),
                    child: Text(
                      'Dismiss all (${widget.count})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _DS.coral,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  AppBar
// ─────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({
    required this.patientName,
    required this.isOffline,
    required this.sosCount,
    required this.onProfileTap,
  });

  final String patientName;
  final bool isOffline;
  final int sosCount;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _DS.card,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D003D36),
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
          child: Row(
            children: [
              // Brand mark
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_DS.teal700, _DS.teal500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: _DS.teal700.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),

              // Title + patient picker
              Expanded(
                child: Consumer(builder: (ctx, ref, _) {
                  final patientsAsync = ref.watch(linkedPatientsProvider);
                  final patients = patientsAsync.valueOrNull ?? [];

                  return _PatientDropdown(
                    patientName: patientName,
                    patients: patients,
                    isLoading: patientsAsync.isLoading,
                    onSelect: (id) => ref
                        .read(activePatientIdProvider.notifier)
                        .setActivePatient(id),
                  );
                }),
              ),

              // SOS badge
              if (sosCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _DS.coral.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.sos_rounded, color: _DS.coral, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$sosCount',
                      style: TextStyle(
                        color: _DS.coral,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ]),
                ),

              // Offline chip
              if (isOffline)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: _DS.amber, size: 13),
                      SizedBox(width: 3),
                      Text('Offline',
                          style: TextStyle(
                              color: Color(0xFF78350F),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

              // Profile
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: _DS.teal100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _DS.teal200, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: _DS.teal700,
                          size: 20),
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
  Size get preferredSize => const Size.fromHeight(70);
}

// ─────────────────────────────────────────────────────────────
//  Patient dropdown inside AppBar
// ─────────────────────────────────────────────────────────────
class _PatientDropdown extends StatelessWidget {
  const _PatientDropdown({
    required this.patientName,
    required this.patients,
    required this.isLoading,
    required this.onSelect,
  });

  final String patientName;
  final List patients;
  final bool isLoading;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'MemoCare',
          style: TextStyle(
            color: _DS.ink900,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        if (isLoading)
          const Text('Loading…',
              style: TextStyle(
                  color: _DS.teal500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600))
        else if (patients.isEmpty)
          const Text('No patients',
              style: TextStyle(
                  color: _DS.ink400, fontSize: 11, fontStyle: FontStyle.italic))
        else
          MenuAnchor(
            builder: (ctx, ctrl, _) => GestureDetector(
              onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _DS.teal50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _DS.teal200.withOpacity(0.5)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _DS.teal700, size: 15),
                ]),
              ),
            ),
            menuChildren: (patients as List).map<Widget>((p) {
              return MenuItemButton(
                onPressed: () => onSelect(p.id as String),
                leadingIcon: CircleAvatar(
                  radius: 12,
                  backgroundColor: _DS.teal100,
                  backgroundImage: (p.profileImageUrl != null &&
                          (p.profileImageUrl as String).isNotEmpty)
                      ? NetworkImage(p.profileImageUrl as String)
                      : null,
                  child: ((p.profileImageUrl == null ||
                          (p.profileImageUrl as String).isEmpty))
                      ? Text(
                          (p.fullName as String).isNotEmpty
                              ? (p.fullName as String)[0].toUpperCase()
                              : 'P',
                          style:
                              const TextStyle(fontSize: 10, color: _DS.teal900))
                      : null,
                ),
                child: Text(
                  p.fullName as String,
                  style: TextStyle(
                    fontWeight: patientName == p.fullName
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _DS.teal900,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Analytics quick tile
// ─────────────────────────────────────────────────────────────
class _AnalyticsTile extends StatelessWidget {
  const _AnalyticsTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _DS.cardDeco(accentColor: _DS.teal500),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_DS.teal700, _DS.teal500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.analytics_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Full Analytics Dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _DS.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View detailed cognitive & activity trends',
                    style: TextStyle(fontSize: 12, color: _DS.ink400),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _DS.teal50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: _DS.teal700, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Section header
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.badge,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 16, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
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

// ─────────────────────────────────────────────────────────────
//  Patient picker section (no patient selected)
// ─────────────────────────────────────────────────────────────
class _PatientPickerSection extends ConsumerWidget {
  const _PatientPickerSection({required this.patients});
  final List patients;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Patients',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _DS.ink900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text('Select a patient to view their dashboard',
              style: TextStyle(fontSize: 13, color: _DS.ink400)),
          const SizedBox(height: 16),
          ...patients.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PatientCard(
                  patient: p as Patient,
                  onTap: () => ref
                      .read(activePatientIdProvider.notifier)
                      .setActivePatient(p.id),
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Patient card
// ─────────────────────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, required this.onTap});
  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _DS.cardDeco(),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
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
                      color: _DS.teal500, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.fullName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _DS.ink900,
                      )),
                  if (patient.age != null || patient.condition != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        [
                          if (patient.age != null) '${patient.age} yrs',
                          if (patient.condition != null) patient.condition!,
                        ].join(' · '),
                        style: const TextStyle(fontSize: 13, color: _DS.ink400),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _DS.teal50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: _DS.teal700, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared small widgets
// ─────────────────────────────────────────────────────────────
class _Pad extends StatelessWidget {
  const _Pad({required this.child, this.top = 0});
  final Widget child;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, top, 16, 0),
        child: child,
      );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    this.trailing,
  });

  final IconData icon;
  final String message;
  final Color color, borderColor, iconColor, textColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(
                  fontSize: 13, color: textColor, fontWeight: FontWeight.w500)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton(
      {required this.label, required this.onTap, required this.color});
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: Color(0xFF16A34A), shape: BoxShape.circle)),
          const SizedBox(width: 4),
          const Text('LIVE',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15803D),
                  letterSpacing: 0.8)),
        ]),
      );
}

class _PatientTag extends StatelessWidget {
  const _PatientTag({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _DS.teal50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(name,
            style: const TextStyle(
                fontSize: 11, color: _DS.teal700, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      );
}

class _NoPatientMap extends StatelessWidget {
  const _NoPatientMap();

  @override
  Widget build(BuildContext context) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: _DS.ink100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 44, color: _DS.ink400),
            SizedBox(height: 10),
            Text('Select a patient to view live location',
                style: TextStyle(color: _DS.ink400, fontSize: 13)),
          ],
        ),
      );
}

class _CardSpinner extends StatelessWidget {
  const _CardSpinner();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
            child:
                CircularProgressIndicator(color: _DS.teal500, strokeWidth: 2)),
      );
}

// ─────────────────────────────────────────────────────────────
//  Empty / Loading states
// ─────────────────────────────────────────────────────────────
class _UnauthView extends StatelessWidget {
  const _UnauthView();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: _DS.bg,
        body: Center(
            child: Text('Not authenticated',
                style: TextStyle(fontSize: 15, color: _DS.ink600))),
      );
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
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_DS.teal50, _DS.teal100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.person_search_rounded,
                size: 48, color: _DS.teal700),
          ),
          const SizedBox(height: 24),
          const Text('No Patients Linked',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _DS.ink900,
                  letterSpacing: -0.4)),
          const SizedBox(height: 10),
          const Text(
            'Connect with a patient using their\ninvite code to start managing their care.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _DS.ink400, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(children: [
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
        const Text('No Activity Yet',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF4C1D95),
                letterSpacing: -0.2)),
        const SizedBox(height: 8),
        const Text(
          'Once the patient starts playing games and following reminders, analytics will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6D28D9), fontSize: 13, height: 1.5),
        ),
      ]),
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final opacity = 0.35 + (_ctrl.value * 0.35);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
                3,
                (i) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: i == 0 ? 96 : 64,
                      decoration: BoxDecoration(
                        color: _DS.ink200.withOpacity(opacity),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    )),
          ),
        );
      },
    );
  }
}
