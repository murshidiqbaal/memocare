import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memocare/data/models/caregiver.dart';
import 'package:memocare/data/models/patient.dart';
import 'package:memocare/providers/auth_provider.dart';
import 'package:memocare/providers/caregiver_patients_provider.dart';
import 'package:memocare/providers/caregiver_profile_provider.dart';
import 'package:memocare/providers/profile_photo_provider.dart';
import 'package:memocare/widgets/editable_avatar.dart';

import '../patients/caregiver_patients_screen.dart';
import 'edit_caregiver_profile_screen.dart';

// ─── Design System ────────────────────────────────────────────────────────────
class _C {
  // Core palette — deep navy with warm coral/amber soul
  static const Color bg = Color(0xFF0D1B2A);
  static const Color surface = Color(0xFF162032);
  static const Color surfaceAlt = Color(0xFF1C2B3E);
  static const Color surfaceHighlight = Color(0xFF233347);
  static const Color border = Color(0xFF2A3F58);

  static const Color coral = Color(0xFFFF6B6B);
  static const Color amber = Color(0xFFFFB347);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color blue = Color(0xFF60A5FA);
  static const Color lavender = Color(0xFFA78BFA);
  static const Color green = Color(0xFF34D399);

  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSub = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF4E687A);

  static const rLg = 24.0;
  static const rMd = 16.0;
  static const rSm = 10.0;
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
class CaregiverProfileScreen extends ConsumerWidget {
  const CaregiverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(caregiverProfileProvider);
    final patientsAsync = ref.watch(connectedPatientsStreamProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: _C.bg,
      body: profileAsync.when(
        data: (caregiver) {
          if (caregiver == null) return _EmptyProfile();
          return _ProfileBody(
            caregiver: caregiver,
            patientsAsync: patientsAsync,
            authFullName: userProfile?.fullName,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: _C.teal),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: _C.coral)),
        ),
      ),
    );
  }
}

// ─── Profile Body ─────────────────────────────────────────────────────────────
class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({
    required this.caregiver,
    required this.patientsAsync,
    required this.authFullName,
  });

  final Caregiver caregiver;
  final AsyncValue<List<Patient>> patientsAsync;
  final String? authFullName;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody>
    with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final AnimationController _cardsCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _cardsSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _cardsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardsCtrl.forward();
    });

    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);

    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caregiver;
    final name = c.fullName ?? widget.authFullName ?? 'Caregiver';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero Header ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _headerFade,
            child: _HeroHeader(
              caregiver: c,
              name: name,
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditCaregiverProfileScreen(existingProfile: c),
                ),
              ),
            ),
          ),
        ),

        // ── All cards below ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SlideTransition(
            position: _cardsSlide,
            child: FadeTransition(
              opacity: _cardsCtrl,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── Activity metrics row ─────────────────────────────────
                    _sectionLabel('Today\'s Activity'),
                    const SizedBox(height: 12),
                    _ActivityMetricsRow(caregiver: c),
                    const SizedBox(height: 28),

                    // ── Personal information ─────────────────────────────────
                    _sectionLabel('Personal Information'),
                    const SizedBox(height: 12),
                    _PersonalInfoCard(caregiver: c),
                    const SizedBox(height: 28),

                    // ── Professional details ─────────────────────────────────
                    _sectionLabel('Professional Details'),
                    const SizedBox(height: 12),
                    _ProfessionalCard(caregiver: c),
                    const SizedBox(height: 28),

                    // ── Availability / Shift ─────────────────────────────────
                    _sectionLabel('Availability & Shift'),
                    const SizedBox(height: 12),
                    _AvailabilityCard(caregiver: c),
                    const SizedBox(height: 28),

                    // ── Care notes ───────────────────────────────────────────
                    _sectionLabel('Recent Care Notes'),
                    const SizedBox(height: 12),
                    _CareNotesCard(caregiver: c),
                    const SizedBox(height: 28),

                    // ── Connected patients ───────────────────────────────────
                    _sectionLabel('Connected Patients'),
                    const SizedBox(height: 12),
                    _ConnectedPatientsCard(patientsAsync: widget.patientsAsync),
                    const SizedBox(height: 28),

                    // ── Actions ───────────────────────────────────────────────
                    _sectionLabel('Actions'),
                    const SizedBox(height: 12),
                    _ActionsCard(
                      onManagePatients: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CaregiverPatientsScreen()),
                      ),
                      onSignOut: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _C.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────
class _HeroHeader extends ConsumerWidget {
  const _HeroHeader({
    required this.caregiver,
    required this.name,
    required this.onEdit,
  });

  final Caregiver caregiver;
  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(profilePhotoUploadProvider);
    final isUploading = uploadState is AsyncLoading;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient background
        Container(
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0E4F6A), Color(0xFF0D1B2A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.teal.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.coral.withOpacity(0.06),
                  ),
                ),
              ),
              // Back + Edit buttons
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _IconBtn(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.maybePop(context)),
                      _IconBtn(icon: Icons.edit_rounded, onTap: onEdit),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Avatar overlapping the hero
        Positioned(
          top: 150,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Hero(
                tag: 'caregiver_avatar',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.bg, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: _C.teal.withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: EditableAvatar(
                    profilePhotoUrl: caregiver.profilePhotoUrl,
                    isUploading: isUploading,
                    radius: 56,
                    onTap: () => ref
                        .read(profilePhotoUploadProvider.notifier)
                        .pickAndUpload(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.green,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    caregiver.relationship ?? 'Family Caregiver',
                    style: const TextStyle(
                      color: _C.textSub,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Verification badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.teal.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_rounded, color: _C.teal, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Verified Caregiver',
                      style: TextStyle(
                        color: _C.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Spacer to push content below avatar
        const SizedBox(height: 420),
      ],
    );
  }
}

// ─── Activity Metrics Row ─────────────────────────────────────────────────────
class _ActivityMetricsRow extends StatelessWidget {
  const _ActivityMetricsRow({required this.caregiver});
  final Caregiver caregiver;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricChip(
            value: '3',
            label: 'Alerts\nHandled',
            icon: Icons.notifications_active_rounded,
            color: _C.coral,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricChip(
            value: '7',
            label: 'Meds\nGiven',
            icon: Icons.medication_rounded,
            color: _C.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricChip(
            value: '2',
            label: 'Check-\nins',
            icon: Icons.checklist_rounded,
            color: _C.amber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricChip(
            value: '6h',
            label: 'On\nDuty',
            icon: Icons.access_time_rounded,
            color: _C.lavender,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(_C.rMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _C.textMuted,
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Personal Info Card ───────────────────────────────────────────────────────
class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard({required this.caregiver});
  final Caregiver caregiver;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_rounded,
            iconColor: _C.green,
            label: 'Phone Number',
            value: caregiver.phone ?? 'Not added',
          ),
          _divider(),
          _InfoRow(
            icon: Icons.email_rounded,
            iconColor: _C.blue,
            label: 'Email Address',
            value: caregiver.email ?? 'Not added',
          ),
          _divider(),
          _InfoRow(
            icon: Icons.location_on_rounded,
            iconColor: _C.coral,
            label: 'Location',
            value: caregiver.address ?? 'Not added',
          ),
          _divider(),
          _InfoRow(
            icon: Icons.family_restroom_rounded,
            iconColor: _C.amber,
            label: 'Relationship to Patient',
            value: caregiver.relationship ?? 'Not specified',
          ),
          _divider(),
          _InfoRow(
            icon: Icons.language_rounded,
            iconColor: _C.lavender,
            label: 'Languages Spoken',
            value: caregiver.languages?.join(', ') ?? 'Not specified',
          ),
          _divider(),
          _InfoRow(
            icon: Icons.cake_rounded,
            iconColor: _C.teal,
            label: 'Date of Birth',
            value: caregiver.dateOfBirth != null
                ? _formatDate(caregiver.dateOfBirth!)
                : 'Not added',
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        color: _C.border,
        height: 1,
        thickness: 1,
      );

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';
}

// ─── Professional Details Card ────────────────────────────────────────────────
class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({required this.caregiver});
  final Caregiver caregiver;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.work_history_rounded,
            iconColor: _C.teal,
            label: 'Experience',
            value: caregiver.yearsOfExperience != null
                ? '${caregiver.yearsOfExperience} years'
                : 'Not specified',
          ),
          const Divider(color: _C.border, height: 1),
          _InfoRow(
            icon: Icons.school_rounded,
            iconColor: _C.blue,
            label: 'Qualification',
            value: caregiver.qualification ?? 'Not added',
          ),
          const Divider(color: _C.border, height: 1),
          _InfoRow(
            icon: Icons.badge_rounded,
            iconColor: _C.amber,
            label: 'License / ID',
            value: caregiver.licenseNumber ?? 'Not added',
          ),
          const Divider(color: _C.border, height: 1),
          // Certifications
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _C.lavender.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_user_rounded,
                          color: _C.lavender, size: 18),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Certifications',
                      style: TextStyle(
                        color: _C.textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (caregiver.certifications?.isNotEmpty == true
                          ? caregiver.certifications!
                          : ['CPR Certified', 'First Aid', 'Dementia Care'])
                      .map((cert) => _Pill(label: cert, color: _C.lavender))
                      .toList(),
                ),
              ],
            ),
          ),
          const Divider(color: _C.border, height: 1),
          _InfoRow(
            icon: Icons.notifications_rounded,
            iconColor: caregiver.notificationEnabled ? _C.green : _C.textMuted,
            label: 'Notifications',
            value: caregiver.notificationEnabled ? 'Enabled' : 'Muted',
            valueColor: caregiver.notificationEnabled ? _C.green : _C.textMuted,
          ),
        ],
      ),
    );
  }
}

// ─── Availability Card ────────────────────────────────────────────────────────
class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.caregiver});
  final Caregiver caregiver;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    // Fallback availability: assume Mon–Fri
    final activeDays = caregiver.availableDays ?? [0, 1, 2, 3, 4];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.schedule_rounded,
            iconColor: _C.blue,
            label: 'Shift Hours',
            value: caregiver.shiftHours ?? '08:00 AM – 04:00 PM',
          ),
          const Divider(color: _C.border, height: 1),
          _InfoRow(
            icon: Icons.home_rounded,
            iconColor: _C.teal,
            label: 'Care Type',
            value: caregiver.careType ?? 'In-Home Care',
          ),
          const Divider(color: _C.border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Days',
                  style: TextStyle(
                    color: _C.textSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final isActive = activeDays.contains(i);
                    return _DayDot(
                      label: _days[i],
                      isActive: isActive,
                    );
                  }),
                ),
              ],
            ),
          ),
          const Divider(color: _C.border, height: 1),
          _InfoRow(
            icon: Icons.emergency_rounded,
            iconColor: _C.coral,
            label: 'Emergency Available',
            value: caregiver.emergencyAvailable == true ? 'Yes' : 'No',
            valueColor:
                caregiver.emergencyAvailable == true ? _C.green : _C.coral,
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.label, required this.isActive});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [_C.teal, _C.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : _C.surfaceHighlight,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _C.teal.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label[0],
              style: TextStyle(
                color: isActive ? Colors.white : _C.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: isActive ? _C.teal : _C.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Care Notes Card ──────────────────────────────────────────────────────────
class _CareNotesCard extends StatelessWidget {
  const _CareNotesCard({required this.caregiver});
  final Caregiver caregiver;

  // Fallback notes when none from model
  static final List<_NoteEntry> _fallbackNotes = [
    _NoteEntry(
      text: 'Patient had a good morning, took breakfast without assistance.',
      time: '08:30 AM',
      icon: Icons.wb_sunny_rounded,
      color: _C.amber,
    ),
    _NoteEntry(
      text: 'Medication administered on schedule — Aricept 10mg.',
      time: '09:00 AM',
      icon: Icons.medication_rounded,
      color: _C.teal,
    ),
    _NoteEntry(
      text: 'Short walk in the garden. Patient was calm and cooperative.',
      time: '11:00 AM',
      icon: Icons.directions_walk_rounded,
      color: _C.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final notes = (caregiver.careNotes?.isNotEmpty == true)
        ? caregiver.careNotes!
            .take(3)
            .map((n) => _NoteEntry(
                  text: n,
                  time: 'Today',
                  icon: Icons.note_rounded,
                  color: _C.lavender,
                ))
            .toList()
        : _fallbackNotes;

    return _Card(
      child: Column(
        children: [
          ...List.generate(notes.length, (i) {
            final note = notes[i];
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: note.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(note.icon, color: note.color, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.text,
                              style: const TextStyle(
                                color: _C.textPrimary,
                                fontSize: 13.5,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note.time,
                              style: const TextStyle(
                                color: _C.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < notes.length - 1)
                  const Divider(color: _C.border, height: 1),
              ],
            );
          }),
          const Divider(color: _C.border, height: 1),
          _TapRow(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add care note',
            color: _C.teal,
            onTap: () {}, // hook to your note creation flow
          ),
        ],
      ),
    );
  }
}

class _NoteEntry {
  const _NoteEntry(
      {required this.text,
      required this.time,
      required this.icon,
      required this.color});
  final String text;
  final String time;
  final IconData icon;
  final Color color;
}

// ─── Connected Patients Card ──────────────────────────────────────────────────
class _ConnectedPatientsCard extends StatelessWidget {
  const _ConnectedPatientsCard({required this.patientsAsync});
  final AsyncValue<List<Patient>> patientsAsync;

  @override
  Widget build(BuildContext context) {
    return patientsAsync.when(
      loading: () => const _Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: _C.teal, strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => _Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e', style: const TextStyle(color: _C.coral)),
        ),
      ),
      data: (patients) {
        if (patients.isEmpty) {
          return _Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.person_add_rounded, color: _C.textMuted, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'No patients connected yet',
                    style: TextStyle(color: _C.textSub, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }
        return _Card(
          child: Column(
            children: [
              ...List.generate(patients.length, (i) {
                final p = patients[i];
                return Column(
                  children: [
                    _PatientRow(patient: p),
                    if (i < patients.length - 1)
                      const Divider(color: _C.border, height: 1),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient});
  final Patient patient;

  int _age(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) age--;
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = patient.profilePhotoUrl?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          // Avatar with status ring
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _C.surfaceHighlight,
                backgroundImage:
                    hasPhoto ? NetworkImage(patient.profilePhotoUrl!) : null,
                child: hasPhoto
                    ? null
                    : const Icon(Icons.person, color: _C.textSub, size: 26),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _C.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName ?? 'Unknown',
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (patient.dateOfBirth != null) ...[
                      Text(
                        '${_age(patient.dateOfBirth!)} yrs',
                        style: const TextStyle(color: _C.textSub, fontSize: 12),
                      ),
                      const Text('  ·  ',
                          style: TextStyle(color: _C.textMuted, fontSize: 12)),
                    ],
                    if (patient.emergencyContactPhone != null)
                      Row(
                        children: [
                          const Icon(Icons.phone_in_talk_rounded,
                              size: 11, color: _C.coral),
                          const SizedBox(width: 3),
                          Text(
                            patient.emergencyContactPhone!,
                            style:
                                const TextStyle(color: _C.coral, fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: _C.green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actions Card ─────────────────────────────────────────────────────────────
class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.onManagePatients,
    required this.onSignOut,
  });
  final VoidCallback onManagePatients;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _TapRow(
            icon: Icons.manage_accounts_rounded,
            label: 'Manage Patients',
            color: _C.teal,
            onTap: onManagePatients,
          ),
          const Divider(color: _C.border, height: 1),
          _TapRow(
            icon: Icons.history_rounded,
            label: 'View Activity Log',
            color: _C.blue,
            onTap: () {},
          ),
          const Divider(color: _C.border, height: 1),
          _TapRow(
            icon: Icons.lock_reset_rounded,
            label: 'Change Password',
            color: _C.amber,
            onTap: () {},
          ),
          const Divider(color: _C.border, height: 1),
          _TapRow(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: _C.coral,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(_C.rLg),
        border: Border.all(color: _C.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        child: child,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _C.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? _C.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_C.rMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _C.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Empty Profile ────────────────────────────────────────────────────────────
class _EmptyProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _C.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border),
            ),
            child:
                const Icon(Icons.person_outline, size: 50, color: _C.textMuted),
          ),
          const SizedBox(height: 20),
          const Text(
            'No profile found',
            style: TextStyle(
                color: _C.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditCaregiverProfileScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.teal, _C.blue]),
                borderRadius: BorderRadius.circular(_C.rMd),
              ),
              child: const Text(
                'Create Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
