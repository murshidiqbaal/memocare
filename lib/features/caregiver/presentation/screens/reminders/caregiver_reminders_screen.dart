import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memocare/features/patient/presentation/screens/reminders/add_edit_reminder_screen.dart';
import 'package:memocare/providers/active_patient_provider.dart';
import 'package:memocare/providers/patient_sos_provider.dart';
import 'package:memocare/providers/service_providers.dart';
import 'package:memocare/widgets/patient_selector_dropdown.dart';

import 'caregiver_reminder_viewmodel.dart';
import 'reminder_history_screen.dart';
import 'widgets/caregiver_reminder_card.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────
class _C {
  static const teal900 = Color(0xFF003D36);
  static const teal700 = Color(0xFF00695C);
  static const teal500 = Color(0xFF00897B);
  static const teal300 = Color(0xFF4DB6AC);
  static const teal100 = Color(0xFFB2DFDB);
  static const teal50 = Color(0xFFE0F2F1);
  static const coral = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF16A34A);
  static const bg = Color(0xFFF4F7F6);
  static const card = Color(0xFFFFFFFF);
  static const ink900 = Color(0xFF0D1B1E);
  static const ink600 = Color(0xFF455A64);
  static const ink400 = Color(0xFF8A9EA2);
  static const ink100 = Color(0xFFECF0F1);
}

// ─────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────
class CaregiverRemindersScreen extends ConsumerWidget {
  const CaregiverRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(caregiverReminderProvider);
    final viewModel = ref.read(caregiverReminderProvider.notifier);
    final activePatientId = ref.watch(activePatientIdProvider);
    final linkedPatientsAsync = ref.watch(linkedPatientsProvider);
    final linkedPatients = linkedPatientsAsync.value ?? [];

    final selectedPatient = linkedPatients.any((p) => p.id == activePatientId)
        ? linkedPatients.firstWhere((p) => p.id == activePatientId)
        : null;

    // SOS — family provider scoped to active patient
    final sosPid = activePatientId ?? '';
    final sosAsync = ref.watch(patientSosProvider(sosPid));
    final sosNotifier = ref.read(patientSosProvider(sosPid).notifier);

    // ── Loading ──
    if (linkedPatientsAsync.isLoading && activePatientId != null) {
      return const Scaffold(
        backgroundColor: _C.bg,
        body: Center(
          child: CircularProgressIndicator(color: _C.teal500, strokeWidth: 2),
        ),
      );
    }

    // ── No patient selected ──
    if (selectedPatient == null || state.selectedPatientId.isEmpty) {
      return Scaffold(
        backgroundColor: _C.bg,
        appBar: _buildAppBar(context, viewModel),
        body: _NoPatientBody(),
        floatingActionButton: _GreyFab(),
      );
    }

    // ── Main view ──
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(context, viewModel),
      body: state.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: _C.teal500, strokeWidth: 2))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Gradient header ──
                SliverToBoxAdapter(
                  child: _Header(
                    selectedPatient: selectedPatient,
                    viewModel: viewModel,
                  ),
                ),

                // ── SOS section ──
                SliverToBoxAdapter(
                  child: sosAsync.when(
                    data: (sos) {
                      if (sos.messages.isEmpty) return const SizedBox.shrink();
                      return _SosSection(
                        messages: sos.messages,
                        unreadCount: sos.unreadCount,
                        onMarkRead: (id) => sosNotifier.markAsRead(id),
                        onMarkAllRead: () => sosNotifier.markAllAsRead(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // ── Reminders section label ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _C.teal50,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.alarm_rounded,
                              color: _C.teal700, size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Reminders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _C.ink900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.reminders.length} total',
                          style:
                              const TextStyle(fontSize: 12, color: _C.ink400),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Reminder list ──
                state.reminders.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyReminders(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final reminder = state.reminders[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReminderHistoryScreen(
                                          reminder: reminder),
                                    ),
                                  ),
                                  child: CaregiverReminderCard(
                                    reminder: reminder,
                                    onEdit: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditReminderScreen(
                                          existingReminder: reminder,
                                          targetPatientId:
                                              state.selectedPatientId,
                                          onSave: (r) =>
                                              viewModel.updateReminder(r),
                                        ),
                                      ),
                                    ),
                                    onDelete: () =>
                                        viewModel.deleteReminder(reminder.id),
                                    onPlayAudio: () async {
                                      final svc = ref
                                          .read(voicePlaybackServiceProvider);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('Playing voice note...'),
                                      ));
                                      await svc.playReminderVoice(reminder);
                                    },
                                  ),
                                ),
                              );
                            },
                            childCount: state.reminders.length,
                          ),
                        ),
                      ),
              ],
            ),
      floatingActionButton: _AddFab(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditReminderScreen(
              targetPatientId: state.selectedPatientId,
              onSave: (r) => viewModel.addReminder(r),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, CaregiverReminderViewModel viewModel) {
    return AppBar(
      backgroundColor: _C.card,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const PatientSelectorDropdown(),
      actions: [
        IconButton(
          icon: const Icon(Icons.sync_rounded, color: _C.teal700),
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Syncing...')),
            );
            await viewModel.refresh();
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Gradient header
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.selectedPatient, required this.viewModel});

  final dynamic selectedPatient;
  final CaregiverReminderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.teal900, _C.teal700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Patient row ──
          Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                  color: _C.teal500,
                  image: (selectedPatient?.profileImageUrl != null &&
                          (selectedPatient.profileImageUrl as String)
                              .isNotEmpty)
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                              selectedPatient.profileImageUrl as String),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (selectedPatient?.profileImageUrl == null ||
                        (selectedPatient!.profileImageUrl as String).isEmpty)
                    ? Text(
                        (selectedPatient?.fullName as String?)?.isNotEmpty ==
                                true
                            ? (selectedPatient!.fullName as String)[0]
                                .toUpperCase()
                            : '?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Managing For',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedPatient?.fullName as String? ??
                          'No Patient Selected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Online badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('Online',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Stats row ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  label: 'Completed',
                  value: '${viewModel.completedTodayCount}',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF4ADE80),
                ),
                _StatDiv(),
                _Stat(
                  label: 'Pending',
                  value: '${viewModel.pendingCount}',
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFFBBF24),
                ),
                _StatDiv(),
                _Stat(
                  label: 'Missed',
                  value: '${viewModel.missedCount}',
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFF87171),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(icon, color: color, size: 16),
            ),
          ],
        ),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }
}

class _StatDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.2));
}

// ─────────────────────────────────────────────────────────────
//  SOS section
// ─────────────────────────────────────────────────────────────
class _SosSection extends StatelessWidget {
  const _SosSection({
    required this.messages,
    required this.unreadCount,
    required this.onMarkRead,
    required this.onMarkAllRead,
  });

  final List<SosMessage> messages;
  final int unreadCount;
  final ValueChanged<String> onMarkRead;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _C.coral.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.sos_rounded, color: _C.coral, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'SOS Alerts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.ink900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              // Unread count badge
              if (unreadCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.coral,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount unread',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              const Spacer(),
              // Mark all read
              if (unreadCount > 0)
                GestureDetector(
                  onTap: onMarkAllRead,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _C.coral.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.coral.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'Dismiss all',
                      style: TextStyle(
                          fontSize: 11,
                          color: _C.coral,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // SOS cards
          ...messages.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SosCard(
                  message: msg,
                  onMarkRead: () => onMarkRead(msg.id),
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Single SOS card
// ─────────────────────────────────────────────────────────────
class _SosCard extends StatefulWidget {
  const _SosCard({required this.message, required this.onMarkRead});
  final SosMessage message;
  final VoidCallback onMarkRead;

  @override
  State<_SosCard> createState() => _SosCardState();
}

class _SosCardState extends State<_SosCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _scale = Tween(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    if (!widget.message.isRead) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !widget.message.isRead;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFFEF2F2) : _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? _C.coral.withOpacity(0.4) : _C.ink100,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: _C.coral.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: _C.ink900.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isUnread ? _C.coral : _C.coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.sos_rounded,
                      color: isUnread ? Colors.white : _C.coral,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            isUnread ? 'SOS Alert' : 'SOS (acknowledged)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isUnread
                                  ? const Color(0xFF7F1D1D)
                                  : _C.ink600,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const Spacer(),
                          // Unread dot
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _C.coral,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          widget.message.note?.isNotEmpty == true
                              ? widget.message.note!
                              : 'Emergency alert triggered',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isUnread ? const Color(0xFF991B1B) : _C.ink600,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                color: isUnread
                    ? _C.coral.withOpacity(0.06)
                    : _C.ink100.withOpacity(0.5),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Row(children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: isUnread ? _C.coral.withOpacity(0.6) : _C.ink400,
                ),
                const SizedBox(width: 5),
                Text(
                  _timeAgo(widget.message.triggeredAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isUnread ? _C.coral.withOpacity(0.7) : _C.ink400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                if (isUnread)
                  GestureDetector(
                    onTap: () {
                      _pulse.stop();
                      widget.onMarkRead();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _C.coral,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _C.coral.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Acknowledge',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: _C.green),
                      const SizedBox(width: 4),
                      const Text('Acknowledged',
                          style: TextStyle(
                              fontSize: 11,
                              color: _C.green,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FABs
// ─────────────────────────────────────────────────────────────
class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        heroTag: 'addReminderFab',
        onPressed: onTap,
        backgroundColor: _C.teal700,
        icon:
            const Icon(Icons.add_alarm_rounded, color: Colors.white, size: 20),
        label: const Text('New Reminder',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      );
}

class _GreyFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        heroTag: 'noPatientReminderFab',
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a patient first.'),
              backgroundColor: Colors.red),
        ),
        label: const Text('New Reminder'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.grey,
      );
}

// ─────────────────────────────────────────────────────────────
//  Empty states
// ─────────────────────────────────────────────────────────────
class _NoPatientBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 80, color: _C.ink100),
            const SizedBox(height: 16),
            const Text('No patient selected',
                style: TextStyle(fontSize: 18, color: _C.ink400)),
            const SizedBox(height: 8),
            const Text(
              'Use the dropdown above to select a patient.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.ink400, fontSize: 13),
            ),
          ],
        ),
      );
}

class _EmptyReminders extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _C.teal50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.alarm_off_rounded,
                  size: 40, color: _C.teal300),
            ),
            const SizedBox(height: 16),
            const Text('No reminders yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _C.ink900)),
            const SizedBox(height: 8),
            const Text('Tap + New Reminder to add one.',
                style: TextStyle(fontSize: 13, color: _C.ink400)),
          ],
        ),
      );
}
