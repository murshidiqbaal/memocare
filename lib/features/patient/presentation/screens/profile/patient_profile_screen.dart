import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memocare/core/utils/profile_completion_helper.dart';
import 'package:memocare/data/models/patient_profile.dart';
import 'package:memocare/data/models/safe_zone.dart';
import 'package:memocare/features/auth/providers/auth_provider.dart';
import 'package:memocare/features/linking/presentation/controllers/link_controller.dart';
import 'package:memocare/features/patient/presentation/screens/profile/edit_patient_profile_screen.dart';
import 'package:memocare/features/patient/presentation/screens/profile/safe_zone_picker_screen.dart';
import 'package:memocare/features/patient/presentation/screens/profile/viewmodels/patient_profile_viewmodel.dart';
import 'package:memocare/providers/profile_photo_provider.dart';
import 'package:memocare/widgets/editable_avatar.dart';

// ─── THEME ────────────────────────────────────────────────────────────────────
class _T {
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF8B5CF6);
  static const soft = Color(0xFFEDE9FE);
  static const accent = Color(0xFFC084FC);
  static const bg = Color(0xFFF5F3FF);
  static const gStart = Color(0xFF6D28D9);
  static const gEnd = Color(0xFF9333EA);
  static const dark = Color(0xFF1E1B4B);
  static const mid = Color(0xFF6B7280);
  static const light = Color(0xFF9CA3AF);
  static const cardShadow = Color(0x147C3AED);
}

// ─── ANIMATED SECTION CARD ────────────────────────────────────────────────────
class _AnimatedSectionCard extends StatefulWidget {
  final Widget child;
  final int index;
  final AnimationController parentController;

  const _AnimatedSectionCard({
    required this.child,
    required this.index,
    required this.parentController,
  });

  @override
  State<_AnimatedSectionCard> createState() => _AnimatedSectionCardState();
}

class _AnimatedSectionCardState extends State<_AnimatedSectionCard> {
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final start = (widget.index * 0.07).clamp(0.0, 0.7);
    final end = (start + 0.35).clamp(0.0, 1.0);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.parentController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.parentController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}

// ─── ANIMATED TILE (press micro-interaction) ──────────────────────────────────
class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableTile({required this.child, this.onTap});

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─── SHIMMER WIDGET ───────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
      builder: (_, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              Color(0xFFE5E7EB),
              Color(0xFFF9FAFB),
              Color(0xFFE5E7EB),
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─── ANIMATED GRADIENT BORDER ─────────────────────────────────────────────────
class _GradientBorderContainer extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final double borderRadius;
  final double borderWidth;

  const _GradientBorderContainer({
    required this.child,
    required this.colors,
    this.borderRadius = 18,
    this.borderWidth = 1.5,
  });

  @override
  State<_GradientBorderContainer> createState() =>
      _GradientBorderContainerState();
}

class _GradientBorderContainerState extends State<_GradientBorderContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotAnim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _rotAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotAnim,
      builder: (_, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            colors: widget.colors,
            rotation: _rotAnim.value,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double rotation;
  final double borderRadius;
  final double borderWidth;

  const _GradientBorderPainter({
    required this.colors,
    required this.rotation,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = SweepGradient(
        colors: [...colors, colors.first],
        transform: GradientRotation(rotation),
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) => old.rotation != rotation;
}

// ─── BOUNCING ICON WIDGET ─────────────────────────────────────────────────────
class _BouncingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final List<Color> grad;
  final double size;

  const _BouncingIcon({
    required this.icon,
    required this.color,
    required this.grad,
    this.size = 16,
  });

  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    final delay =
        Duration(milliseconds: (Random().nextDouble() * 2000).toInt());
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _bounce = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: widget.grad),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: widget.grad.first.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(widget.icon, color: Colors.white, size: widget.size),
      ),
    );
  }
}

// ─── MAIN SCREEN ─────────────────────────────────────────────────────────────
class PatientProfileScreen extends ConsumerStatefulWidget {
  final String? patientId;
  const PatientProfileScreen({super.key, this.patientId});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  late AnimationController _masterCtrl;
  late AnimationController _headerPulseCtrl;
  late AnimationController _completionBarCtrl;
  late Animation<double> _completionBarAnim;
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;

  // Header parallax offset
  double _headerOffset = 0;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _headerPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _completionBarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _completionBarAnim = CurvedAnimation(
      parent: _completionBarCtrl,
      curve: Curves.easeOutCubic,
    );

    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _completionBarCtrl.forward();
        _fabCtrl.forward();
      }
    });

    _scrollController.addListener(() {
      final offset = _scrollController.hasClients
          ? _scrollController.offset.clamp(0.0, 120.0)
          : 0.0;
      if (mounted) setState(() => _headerOffset = offset.toDouble());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _masterCtrl.dispose();
    _headerPulseCtrl.dispose();
    _completionBarCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateToEdit(PatientProfile? profile) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: EditPatientProfileScreen(
            existingProfile: profile,
            patientId: widget.patientId,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (result == true && mounted) {
      ref.invalidate(patientProfileProvider(widget.patientId));
    }
  }

  Future<void> _signOut() async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (_, __, ___) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child:
                const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          const Text('Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: const Text(
          'Are you sure you want to sign out of Memo Care?',
          style: TextStyle(color: _T.mid, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = patientProfileProvider(widget.patientId);
    final profileState = ref.watch(provider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isCaregiver = userProfile?.role == 'caregiver';
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: _T.bg,
      body: profileState.when(
        loading: () => _loadingState(),
        error: (err, _) => _errorState(err, provider),
        data: (profile) {
          if (profile == null) return _emptyState(scale);
          final pct = ProfileCompletionHelper.calculateCompletion(profile);
          final msg = ProfileCompletionHelper.getCompletionMessage(pct);

          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (_, __) => [
              _sliverAppBar(profile, isCaregiver, scale),
            ],
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  16 * scale, 14 * scale, 16 * scale, 120 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildSections(profile, pct, msg, isCaregiver, scale),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSections(PatientProfile profile, int pct, String msg,
      bool isCaregiver, double scale) {
    final sections = <Widget>[];
    int idx = 0;

    Widget wrap(Widget child) {
      final w = _AnimatedSectionCard(
        index: idx,
        parentController: _masterCtrl,
        child: child,
      );
      idx++;
      return w;
    }

    // Completion card
    if (pct < 100) {
      sections.add(wrap(_completionCard(pct, msg, scale)));
      sections.add(SizedBox(height: 20 * scale));
    }

    // Stats row
    sections.add(wrap(_statsRow(profile, scale)));
    sections.add(SizedBox(height: 20 * scale));

    // Personal info
    sections.add(wrap(_section(
      title: 'Personal Information',
      icon: Icons.person_rounded,
      grad: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
      scale: scale,
      sectionIndex: idx,
      children: [
        _tile('Full Name', profile.fullName ?? 'Not set', Icons.badge_outlined,
            const Color(0xFF7C3AED), scale),
        if (profile.dateOfBirth != null)
          _tile(
              'Date of Birth',
              DateFormat('dd MMM yyyy').format(profile.dateOfBirth!),
              Icons.cake_outlined,
              const Color(0xFFEC4899),
              scale,
              sub: '${_age(profile.dateOfBirth!)} years old'),
        if (profile.gender != null)
          _tile('Gender', profile.gender!, Icons.wc_rounded,
              const Color(0xFF8B5CF6), scale),
        if (profile.phoneNumber != null)
          _tile('Phone', profile.phoneNumber!, Icons.phone_outlined,
              const Color(0xFF10B981), scale),
        if (profile.address != null)
          _tile('Address', profile.address!, Icons.location_on_outlined,
              const Color(0xFFF59E0B), scale),
      ],
    )));
    sections.add(SizedBox(height: 20 * scale));

    // Emergency & Medical
    sections.add(wrap(_section(
      title: 'Emergency & Medical',
      icon: Icons.local_hospital_rounded,
      grad: const [Color(0xFFDC2626), Color(0xFFEF4444)],
      scale: scale,
      sectionIndex: idx,
      children: [
        if (profile.emergencyContactName != null)
          _tile('Emergency Contact', profile.emergencyContactName!,
              Icons.contact_emergency_outlined, const Color(0xFFDC2626), scale),
        if (profile.emergencyContactPhone != null)
          _tile('Emergency Phone', profile.emergencyContactPhone!,
              Icons.phone_in_talk_outlined, const Color(0xFFEA580C), scale),
        if (profile.medicalNotes != null)
          _tile('Medical Notes', profile.medicalNotes!,
              Icons.medical_services_outlined, const Color(0xFF2563EB), scale),
        if (!ProfileCompletionHelper.hasCriticalInfo(profile))
          _warning('Please add emergency contact information', scale),
      ],
    )));
    sections.add(SizedBox(height: 20 * scale));

    // Hobbies
    sections.add(wrap(_section(
      title: 'Hobbies & Interests',
      icon: Icons.favorite_rounded,
      grad: const [Color(0xFFEC4899), Color(0xFFF472B6)],
      badge: 'Optional',
      scale: scale,
      sectionIndex: idx,
      children: [
        _chips(
          label: 'Activities',
          chips: profile.hobbies ?? [],
          color: const Color(0xFFEC4899),
          icon: Icons.sports_soccer_outlined,
          hint: 'e.g. Gardening, Reading, Painting',
          scale: scale,
        ),
        _tile(
            'Favourite Pastime / Craft',
            profile.favouritePastime ?? 'Not added',
            Icons.brush_outlined,
            const Color(0xFFF59E0B),
            scale),
        _tile(
            'Outdoor / Indoor Preference',
            profile.indoorOutdoorPref ?? 'Not added',
            Icons.wb_sunny_outlined,
            const Color(0xFF10B981),
            scale),
      ],
    )));
    sections.add(SizedBox(height: 20 * scale));

    // Favourite Things
    sections.add(wrap(_section(
      title: 'Favourite Things',
      icon: Icons.star_rounded,
      grad: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
      badge: 'Optional',
      scale: scale,
      sectionIndex: idx,
      children: [
        _tile('Favourite Food / Snack', profile.favouriteFood ?? 'Not added',
            Icons.restaurant_outlined, const Color(0xFFF59E0B), scale),
        _tile('Favourite Drink', profile.favouriteDrink ?? 'Not added',
            Icons.local_cafe_outlined, const Color(0xFF92400E), scale),
        _tile('Favourite Music / Artist', profile.favouriteMusic ?? 'Not added',
            Icons.music_note_outlined, const Color(0xFF7C3AED), scale),
        _tile('Favourite TV Show / Movie', profile.favouriteShow ?? 'Not added',
            Icons.tv_outlined, const Color(0xFF2563EB), scale),
        _tile('Favourite Place / Memory', profile.favouritePlace ?? 'Not added',
            Icons.place_outlined, const Color(0xFF10B981), scale),
      ],
    )));
    sections.add(SizedBox(height: 20 * scale));

    // Daily Routine
    sections.add(wrap(_section(
      title: 'Daily Routine',
      icon: Icons.schedule_rounded,
      grad: const [Color(0xFF0891B2), Color(0xFF06B6D4)],
      badge: 'Optional',
      scale: scale,
      sectionIndex: idx,
      children: [
        _tile('Wake Up Time', profile.wakeUpTime ?? 'Not set',
            Icons.wb_sunny_outlined, const Color(0xFFF59E0B), scale),
        _tile('Bedtime', profile.bedTime ?? 'Not set', Icons.bedtime_outlined,
            const Color(0xFF6366F1), scale),
        _tile('Meal Preferences', profile.mealPreferences ?? 'Not set',
            Icons.lunch_dining_outlined, const Color(0xFF10B981), scale),
        _tile('Exercise / Walk Routine', profile.exerciseRoutine ?? 'Not set',
            Icons.directions_walk_outlined, const Color(0xFF059669), scale),
        _tile(
            'Religious / Cultural Practices',
            profile.religiousPractices ?? 'Not set',
            Icons.volunteer_activism_outlined,
            const Color(0xFF7C3AED),
            scale),
        _tile('Nap / Rest Time', profile.napTime ?? 'Not set',
            Icons.airline_seat_flat_outlined, const Color(0xFF8B5CF6), scale),
      ],
    )));
    sections.add(SizedBox(height: 20 * scale));

    // Language & Communication
    sections.add(wrap(_section(
      title: 'Language & Communication',
      icon: Icons.chat_bubble_outline_rounded,
      grad: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
      badge: 'Optional',
      scale: scale,
      sectionIndex: idx,
      children: [
        _tile('Preferred Language', profile.preferredLanguage ?? 'Not set',
            Icons.language_outlined, const Color(0xFF0D9488), scale),
        _tile('Communication Style', profile.communicationStyle ?? 'Not set',
            Icons.record_voice_over_outlined, const Color(0xFF0891B2), scale),
        _tile('Triggers to Avoid', profile.triggers ?? 'Not set',
            Icons.warning_amber_outlined, const Color(0xFFDC2626), scale),
        _tile('Calming Strategies', profile.calmingStrategies ?? 'Not set',
            Icons.spa_outlined, const Color(0xFF10B981), scale),
        _tile(
            'Important People They Remember',
            profile.importantPeople ?? 'Not set',
            Icons.people_outline_rounded,
            const Color(0xFFEC4899),
            scale),
      ],
    )));
    sections.add(SizedBox(height: 20 * scale));

    // Caregiver + Security (patients only)
    if (!isCaregiver) {
      sections.add(wrap(_section(
        title: 'Caregiver Access',
        icon: Icons.people_alt_rounded,
        grad: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
        scale: scale,
        sectionIndex: idx,
        children: [_linkingContent(scale, profile)],
      )));
      sections.add(SizedBox(height: 20 * scale));

      //sections.add(wrap(_homeLocationSection(scale, profile.id)));

      sections.add(wrap(_section(
        title: 'Security',
        icon: Icons.security_rounded,
        grad: const [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
        scale: scale,
        sectionIndex: idx,
        children: [
          _tile('Biometric Login', 'Tap to configure',
              Icons.fingerprint_rounded, const Color(0xFF1D4ED8), scale),
          _tile(
            'Home Safe Zone',
            'Request home location change',
            Icons.home_work_outlined,
            const Color(0xFF10B981),
            scale,
            onTap: () => context.push('/patient-home-location/${profile.id}'),
          ),
        ],
      )));
      sections.add(SizedBox(height: 20 * scale));
    }

    return sections;
  }

  // ── LOADING STATE ─────────────────────────────────────────────────────────
  Widget _loadingState() {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          // Shimmer header
          _Shimmer(
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                color: Color(0xFFE5E7EB),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _Shimmer(
                      child: Container(
                        height: 100 + (i * 10).toDouble(),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS ROW ─────────────────────────────────────────────────────────────
  Widget _statsRow(PatientProfile profile, double scale) {
    final hasHobbies = (profile.hobbies?.isNotEmpty ?? false);
    final hasMedical = profile.medicalNotes != null;
    final hasContacts = profile.emergencyContactName != null;
    final pct = ProfileCompletionHelper.calculateCompletion(profile);

    return Row(
      children: [
        _statCard(
            '$pct%',
            'Complete',
            const [Color(0xFF7C3AED), Color(0xFF9333EA)],
            Icons.insert_chart_outlined_rounded,
            scale),
        SizedBox(width: 10 * scale),
        _statCard(
            hasHobbies ? '${profile.hobbies!.length}' : '0',
            'Hobbies',
            const [Color(0xFFEC4899), Color(0xFFF472B6)],
            Icons.favorite_rounded,
            scale),
        SizedBox(width: 10 * scale),
        _statCard(
          hasContacts ? '✓' : '✗',
          'Emergency',
          hasContacts
              ? const [Color(0xFF10B981), Color(0xFF34D399)]
              : const [Color(0xFFEF4444), Color(0xFFF87171)],
          Icons.contact_emergency_rounded,
          scale,
        ),
        SizedBox(width: 10 * scale),
        _statCard(
          hasMedical ? '✓' : '✗',
          'Medical',
          hasMedical
              ? const [Color(0xFF2563EB), Color(0xFF60A5FA)]
              : const [Color(0xFF9CA3AF), Color(0xFFD1D5DB)],
          Icons.medical_services_rounded,
          scale,
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, List<Color> grad, IconData icon,
      double scale) {
    return Expanded(
      child: _PressableTile(
        child: Container(
          padding:
              EdgeInsets.symmetric(vertical: 14 * scale, horizontal: 8 * scale),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: grad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16 * scale),
            boxShadow: [
              BoxShadow(
                color: grad.first.withOpacity(0.38),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: Colors.white.withOpacity(0.85), size: 18 * scale),
              SizedBox(height: 6 * scale),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9 * scale,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SLIVER APP BAR ────────────────────────────────────────────────────────
  SliverAppBar _sliverAppBar(
      PatientProfile profile, bool isCaregiver, double scale) {
    final isUploading = ref.watch(profilePhotoUploadProvider) is AsyncLoading;

    return SliverAppBar(
      expandedHeight: 280 * scale,
      pinned: true,
      floating: false,
      stretch: true,
      backgroundColor: _T.gStart,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: _T.gStart.withOpacity(0.5),
      title: Text(
        widget.patientId != null ? 'Patient Profile' : 'My Profile',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      actions: [
        if (!isCaregiver)
          _AppBarButton(
            icon: Icons.edit_rounded,
            onTap: () => _navigateToEdit(
                ref.read(patientProfileProvider(widget.patientId)).value),
          ),
        _AppBarButton(icon: Icons.logout_rounded, onTap: _signOut),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: AnimatedBuilder(
          animation: _headerPulseCtrl,
          builder: (_, __) {
            final pulse = _headerPulseCtrl.value;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(
                        _T.gStart, const Color(0xFF4C1D95), pulse * 0.3)!,
                    Color.lerp(_T.gEnd, const Color(0xFF7C3AED), pulse * 0.2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                // Animated blobs
                Positioned(
                  top: -50 + pulse * 15,
                  right: -50 + pulse * 10,
                  child: _animatedBlob(200, 0.07 + pulse * 0.03),
                ),
                Positioned(
                  top: 70 + pulse * 10,
                  right: 90 + pulse * 5,
                  child: _animatedBlob(70, 0.05 + pulse * 0.02),
                ),
                Positioned(
                  bottom: 0 + pulse * 12,
                  left: -40 + pulse * 5,
                  child: _animatedBlob(130, 0.06 + pulse * 0.02),
                ),
                Positioned(
                  bottom: 60,
                  right: 20 + pulse * 8,
                  child: _animatedBlob(55, 0.04 + pulse * 0.02),
                ),

                // Diagonal stripe decoration
                Positioned.fill(
                  child: CustomPaint(
                    painter:
                        _DiagonalStripePainter(opacity: 0.03 + pulse * 0.01),
                  ),
                ),

                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 24 * scale),

                      // Hero avatar with animated ring
                      Hero(
                        tag: 'patient_avatar_${widget.patientId ?? "me"}',
                        child: _AnimatedAvatarRing(
                          child: EditableAvatar(
                            profilePhotoUrl: profile.profileImageUrl,
                            isUploading: isUploading,
                            radius: 52 * scale,
                            onTap: () => ref
                                .read(profilePhotoUploadProvider.notifier)
                                .pickAndUpload(),
                          ),
                          pulseController: _headerPulseCtrl,
                          scale: scale,
                        ),
                      ),
                      SizedBox(height: 14 * scale),

                      // Hero name text
                      Hero(
                        tag: 'patient_name_${widget.patientId ?? "me"}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            profile.fullName ?? 'Memo Care Patient',
                            style: TextStyle(
                              fontSize: 22 * scale,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(height: 4 * scale),

                      if (profile.dateOfBirth != null)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, (1 - v) * 10),
                              child: child,
                            ),
                          ),
                          child: Text(
                            '${_age(profile.dateOfBirth!)} years old',
                            style: TextStyle(
                              fontSize: 13 * scale,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                        ),
                      SizedBox(height: 12 * scale),

                      // Animated pill badge
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.elasticOut,
                        builder: (_, v, child) =>
                            Transform.scale(scale: v, child: child),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16 * scale, vertical: 6 * scale),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.28)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '🧠  Memo Care Patient',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _animatedBlob(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  // ── SECTION ───────────────────────────────────────────────────────────────
  Widget _section({
    required String title,
    required IconData icon,
    required List<Color> grad,
    required double scale,
    required List<Widget> children,
    required int sectionIndex,
    String? badge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(children: [
          Hero(
            tag: 'section_icon_$title',
            child: _BouncingIcon(
              icon: icon,
              color: grad.first,
              grad: grad,
              size: 16 * scale,
            ),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: _T.dark,
              ),
            ),
          ),
          if (badge != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale, vertical: 3 * scale),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      grad.first.withOpacity(0.12),
                      grad.last.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: grad.first.withOpacity(0.25)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10 * scale,
                    color: grad.first,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ]),
        SizedBox(height: 10 * scale),

        // Card with animated gradient border
        _GradientBorderContainer(
          colors: [...grad, Colors.transparent, Colors.transparent],
          borderRadius: 18,
          borderWidth: 1.2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18 * scale),
              boxShadow: [
                BoxShadow(
                  color: grad.first.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                const BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18 * scale),
              child: children.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(24 * scale),
                      child: Center(
                        child: Text(
                          'No information added yet',
                          style: TextStyle(
                            color: _T.light,
                            fontSize: 14 * scale,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: _divide(
                        children,
                        Container(
                          height: 1,
                          margin: EdgeInsets.only(
                              left: 66 * scale, right: 16 * scale),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                grad.first.withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── INFO TILE ─────────────────────────────────────────────────────────────
  Widget _tile(
      String label, String value, IconData icon, Color color, double scale,
      {String? sub, VoidCallback? onTap}) {
    final empty =
        value == 'Not set' || value == 'Not added' || value.trim().isEmpty;

    return _PressableTile(
      onTap: onTap,
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Animated icon container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 38 * scale,
              height: 38 * scale,
              decoration: BoxDecoration(
                color: empty ? const Color(0xFFF3F4F6) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: empty
                    ? []
                    : [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                color: empty ? _T.light : color,
                size: 18 * scale,
              ),
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5 * scale,
                    color: _T.light,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                SizedBox(height: 3 * scale),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5 * scale,
                    color: empty ? _T.light : _T.dark,
                    fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                    fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                    height: 1.3,
                  ),
                ),
                if (sub != null) ...[
                  SizedBox(height: 3 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale, vertical: 2 * scale),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(sub,
                        style: TextStyle(
                            fontSize: 11 * scale,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
          // Subtle arrow for non-empty tiles
          if (!empty)
            Icon(Icons.chevron_right_rounded,
                color: _T.light.withOpacity(0.5), size: 16 * scale),
        ]),
      ),
    );
  }

  // ── CHIP ROW ──────────────────────────────────────────────────────────────
  Widget _chips({
    required String label,
    required List<String> chips,
    required Color color,
    required IconData icon,
    required double scale,
    String? hint,
  }) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: BoxDecoration(
              color: chips.isEmpty
                  ? const Color(0xFFF3F4F6)
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: chips.isEmpty ? _T.light : color,
              size: 18 * scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5 * scale,
                    color: _T.light,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                SizedBox(height: 8 * scale),
                chips.isEmpty
                    ? Text(
                        hint ?? 'Not added',
                        style: TextStyle(
                          fontSize: 14 * scale,
                          color: _T.light,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: chips
                            .asMap()
                            .entries
                            .map((e) => TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration:
                                      Duration(milliseconds: 400 + e.key * 80),
                                  curve: Curves.easeOutBack,
                                  builder: (_, v, child) =>
                                      Transform.scale(scale: v, child: child),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12 * scale,
                                        vertical: 6 * scale),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withOpacity(0.12),
                                          color.withOpacity(0.06),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                          color: color.withOpacity(0.3)),
                                    ),
                                    child: Text(e.value,
                                        style: TextStyle(
                                          fontSize: 12 * scale,
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ),
                                ))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── WARNING ───────────────────────────────────────────────────────────────
  Widget _warning(String msg, double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF97316), size: 16),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Text(msg,
              style: TextStyle(
                  color: const Color(0xFF92400E),
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  // ── COMPLETION CARD ───────────────────────────────────────────────────────
  Widget _completionCard(int pct, String msg, double scale) {
    return _GradientBorderContainer(
      colors: const [
        Color(0xFFC084FC),
        Color(0xFF7C3AED),
        Color(0xFF4C1D95),
        Color(0xFFC084FC),
      ],
      borderRadius: 22,
      borderWidth: 2,
      child: Container(
        padding: EdgeInsets.all(20 * scale),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF9333EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22 * scale),
          boxShadow: [
            BoxShadow(
              color: _T.primary.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Profile Completion',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                SizedBox(height: 3 * scale),
                AnimatedBuilder(
                  animation: _completionBarAnim,
                  builder: (_, __) {
                    final displayPct = (pct * _completionBarAnim.value).round();
                    return Text(
                      '$displayPct%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36 * scale,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    );
                  },
                ),
              ]),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 64 * scale,
                  height: 64 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      pct < 50
                          ? '🚀'
                          : pct < 80
                              ? '⚡'
                              : '🌟',
                      style: TextStyle(fontSize: 28 * scale),
                    ),
                  ),
                ),
              ),
            ]),
            SizedBox(height: 16 * scale),
            // Animated progress bar
            AnimatedBuilder(
              animation: _completionBarAnim,
              builder: (_, __) {
                return Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 10,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FractionallySizedBox(
                      widthFactor: (pct / 100) * _completionBarAnim.value,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF9A8D4), Color(0xFFE879F9)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]);
              },
            ),
            SizedBox(height: 10 * scale),
            Text(msg,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12 * scale,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }

  // ── HOME LOCATION SECTION ─────────────────────────────────────────────────
  // Widget _homeLocationSection(double scale, String patientId) {
  //   final safeZoneAsync = ref.watch(patientSafeZoneProvider(patientId));
  //   final homeLocAsync = ref.watch(patientHomeLocationProvider(patientId));

  //   if (safeZoneAsync.value != null || homeLocAsync.value != null) {
  //     return const SizedBox.shrink();
  //   }

  //   return Column(children: [
  //     _section(
  //       title: 'Home Location',
  //       icon: Icons.home_rounded,
  //       grad: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
  //       scale: scale,
  //       sectionIndex: 0,
  //       children: [
  //         safeZoneAsync.when(
  //           data: (_) => homeLocAsync.when(
  //             data: (_) => Padding(
  //               padding: EdgeInsets.all(24 * scale),
  //               child: Column(children: [
  //                 TweenAnimationBuilder<double>(
  //                   tween: Tween(begin: 0, end: 1),
  //                   duration: const Duration(milliseconds: 700),
  //                   curve: Curves.easeOutBack,
  //                   builder: (_, v, child) =>
  //                       Transform.scale(scale: v, child: child),
  //                   child: Container(
  //                     padding: const EdgeInsets.all(20),
  //                     decoration: BoxDecoration(
  //                       color: _T.soft,
  //                       shape: BoxShape.circle,
  //                     ),
  //                     child: const Icon(Icons.add_location_alt_outlined,
  //                         size: 40, color: _T.primary),
  //                   ),
  //                 ),
  //                 SizedBox(height: 14 * scale),
  //                 Text('Set Home Location',
  //                     style: TextStyle(
  //                         fontSize: 16 * scale,
  //                         fontWeight: FontWeight.bold,
  //                         color: _T.dark)),
  //                 SizedBox(height: 6 * scale),
  //                 Text(
  //                   'Setting a home location helps caregivers know you are safe.',
  //                   textAlign: TextAlign.center,
  //                   style: TextStyle(
  //                       fontSize: 13 * scale, color: _T.mid, height: 1.5),
  //                 ),
  //                 SizedBox(height: 18 * scale),
  //                 ScaleTransition(
  //                   scale: _fabScale,
  //                   child: ElevatedButton.icon(
  //                     onPressed: () =>
  //                         _navigateToSafeZonePicker(patientId, null),
  //                     icon: const Icon(Icons.add_location_alt_rounded),
  //                     label: const Text('Set Location',
  //                         style: TextStyle(fontWeight: FontWeight.bold)),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: _T.primary,
  //                       foregroundColor: Colors.white,
  //                       elevation: 0,
  //                       padding: EdgeInsets.symmetric(
  //                           horizontal: 24 * scale, vertical: 14 * scale),
  //                       shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(14)),
  //                       shadowColor: _T.primary.withOpacity(0.4),
  //                     ),
  //                   ),
  //                 ),
  //               ]),
  //             ),
  //             loading: () => const Center(
  //                 child: Padding(
  //               padding: EdgeInsets.all(24),
  //               child: CircularProgressIndicator(
  //                   color: _T.primary, strokeWidth: 2),
  //             )),
  //             error: (e, _) => Text('Error: $e'),
  //           ),
  //           loading: () => const Center(
  //               child: Padding(
  //             padding: EdgeInsets.all(24),
  //             child:
  //                 CircularProgressIndicator(color: _T.primary, strokeWidth: 2),
  //           )),
  //           error: (e, _) => Text('Error: $e'),
  //         ),
  //       ],
  //     ),
  //     SizedBox(height: 20 * scale),
  //   ]);
  // }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _emptyState(double scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32 * scale),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: EdgeInsets.all(32 * scale),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _T.soft,
                    _T.accent.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _T.primary.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.person_add_alt_1_rounded,
                  size: 64 * scale, color: _T.primary),
            ),
          ),
          SizedBox(height: 28 * scale),
          Text('No Profile Found',
              style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w800,
                  color: _T.dark)),
          SizedBox(height: 10 * scale),
          Text('Create a profile to get started with Memo Care',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14 * scale, color: _T.mid, height: 1.5)),
          SizedBox(height: 32 * scale),
          ScaleTransition(
            scale: _fabScale,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToEdit(null),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                    horizontal: 32 * scale, vertical: 16 * scale),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                shadowColor: _T.primary.withOpacity(0.45),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text('Create Profile',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16 * scale)),
            ),
          ),
          SizedBox(height: 12 * scale),
          TextButton(
            onPressed: () =>
                ref.refresh(patientProfileProvider(widget.patientId)),
            child: const Text('Retry', style: TextStyle(color: _T.primary)),
          ),
        ]),
      ),
    );
  }

  // ── ERROR STATE ───────────────────────────────────────────────────────────
  Widget _errorState(Object err, dynamic provider) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red),
          ),
        ),
        const SizedBox(height: 20),
        Text('$err',
            textAlign: TextAlign.center, style: const TextStyle(color: _T.mid)),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _T.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => ref.refresh(provider),
          child: const Text('Retry'),
        ),
      ]),
    );
  }

  // ── LINKING CONTENT ───────────────────────────────────────────────────────
  Widget _linkingContent(double scale, PatientProfile profile) {
    final activeCode = ref.watch(activeInviteCodeProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Invite code
      Padding(
        padding: EdgeInsets.all(16 * scale),
        child: activeCode.when(
          loading: () => const Center(
              child:
                  CircularProgressIndicator(color: _T.primary, strokeWidth: 2)),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
          data: (code) {
            if (code != null) {
              return Column(children: [
                Text('Share this code with your caregiver',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _T.mid, fontSize: 13 * scale, height: 1.4)),
                SizedBox(height: 14 * scale),
                _GradientBorderContainer(
                  colors: const [
                    Color(0xFF7C3AED),
                    Color(0xFFC084FC),
                    Color(0xFF9333EA),
                    Color(0xFF7C3AED),
                  ],
                  borderRadius: 16,
                  borderWidth: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20 * scale, vertical: 16 * scale),
                    decoration: BoxDecoration(
                      color: _T.soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            code.code,
                            style: TextStyle(
                              fontSize: 32 * scale,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: _T.primary,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          _PressableTile(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code.code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Code copied to clipboard!'),
                                  ]),
                                  backgroundColor: _T.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _T.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.copy_rounded,
                                  color: _T.primary, size: 20),
                            ),
                          ),
                        ]),
                  ),
                ),
                SizedBox(height: 10 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12 * scale, vertical: 5 * scale),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.timer_outlined,
                        size: 14, color: Colors.red.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Expires in ${code.expiresAt.difference(DateTime.now()).inHours} hours',
                      style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ]);
            } else {
              return Center(
                child: ScaleTransition(
                  scale: _fabScale,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(linkControllerProvider.notifier)
                        .generateCode(),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Generate Invite Code',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24 * scale, vertical: 14 * scale),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),

      Container(
        height: 1,
        margin: EdgeInsets.symmetric(horizontal: 16 * scale),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, _T.soft, Colors.transparent],
          ),
        ),
      ),

      // Linked caregivers
      Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: _T.primary),
            ),
            SizedBox(width: 8 * scale),
            Text('Linked Caregivers',
                style: TextStyle(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w700,
                    color: _T.mid,
                    letterSpacing: 0.3)),
          ]),
          SizedBox(height: 12 * scale),
          ref.watch(patientCaregiversProvider(profile.id)).when(
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
                data: (links) {
                  if (links.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16 * scale),
                        child: Column(children: [
                          Icon(Icons.person_search_rounded,
                              size: 36, color: _T.light),
                          SizedBox(height: 8 * scale),
                          Text('No caregivers linked yet.',
                              style: TextStyle(
                                  color: _T.light,
                                  fontSize: 14 * scale,
                                  fontStyle: FontStyle.italic)),
                        ]),
                      ),
                    );
                  }
                  return Column(
                    children: links.asMap().entries.map((entry) {
                      final i = entry.key;
                      final link = entry.value;
                      final cp = link['caregiver_profiles']
                              is Map<String, dynamic>
                          ? link['caregiver_profiles'] as Map<String, dynamic>
                          : <String, dynamic>{};
                      final name =
                          cp['full_name']?.toString() ?? 'Linked Caregiver';
                      final photo = cp['profile_photo_url']?.toString();
                      final rel = cp['relationship']?.toString();
                      final phone =
                          cp['phone_number']?.toString() ?? 'No phone number';

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 400 + i * 100),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(
                            offset: Offset(30 * (1 - v), 0),
                            child: child,
                          ),
                        ),
                        child: _PressableTile(
                          onTap: () => _showCaregiverDialog(
                              name, photo, rel, phone, scale),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 10 * scale),
                            padding: EdgeInsets.all(12 * scale),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _T.soft.withOpacity(0.8),
                                  _T.soft.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: _T.accent.withOpacity(0.2)),
                            ),
                            child: Row(children: [
                              Hero(
                                tag: 'caregiver_avatar_${link['id']}',
                                child: CircleAvatar(
                                  radius: 24 * scale,
                                  backgroundColor: _T.soft,
                                  backgroundImage:
                                      (photo != null && photo.isNotEmpty)
                                          ? NetworkImage(photo)
                                          : null,
                                  child: (photo == null || photo.isEmpty)
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'C',
                                          style: TextStyle(
                                              color: _T.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16 * scale),
                                        )
                                      : null,
                                ),
                              ),
                              SizedBox(width: 12 * scale),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15 * scale,
                                            color: _T.dark)),
                                    if (rel != null)
                                      Text(rel,
                                          style: TextStyle(
                                              color: _T.primary,
                                              fontSize: 12 * scale,
                                              fontWeight: FontWeight.w600)),
                                    Text(phone,
                                        style: TextStyle(
                                            fontSize: 12 * scale,
                                            color: _T.mid)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.verified_rounded,
                                    color: Color(0xFF10B981), size: 16),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
        ]),
      ),
    ]);
  }

  void _showCaregiverDialog(
      String name, String? photo, String? rel, String phone, double scale) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (_, __, ___) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(28 * scale),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Gradient avatar ring
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFC084FC), Color(0xFF6D28D9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _T.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 42 * scale,
                backgroundColor: _T.soft,
                backgroundImage: (photo != null && photo.isNotEmpty)
                    ? NetworkImage(photo)
                    : null,
                child: (photo == null || photo.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: TextStyle(
                            fontSize: 34 * scale,
                            color: _T.primary,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 18 * scale),
            Text(name,
                style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w800,
                    color: _T.dark),
                textAlign: TextAlign.center),
            if (rel != null) ...[
              SizedBox(height: 6 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale, vertical: 4 * scale),
                decoration: BoxDecoration(
                  color: _T.soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(rel,
                    style: TextStyle(
                        fontSize: 13 * scale,
                        color: _T.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
            SizedBox(height: 12 * scale),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale, vertical: 8 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.phone_rounded,
                    size: 15, color: Color(0xFF10B981)),
                SizedBox(width: 6 * scale),
                Text(phone,
                    style: TextStyle(
                        fontSize: 14 * scale,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            SizedBox(height: 24 * scale),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: EdgeInsets.symmetric(vertical: 14 * scale),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _navigateToSafeZonePicker(String patientId, SafeZone? zone) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => FadeTransition(
        opacity: anim,
        child: SafeZonePickerScreen(
          patientId: patientId,
          initialLatitude: zone?.homeLat,
          initialLongitude: zone?.homeLng,
          initialRadiusMeters: zone?.radius.toInt(),
          existingZoneId: null,
          initialLabel: null,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  int _age(DateTime dob) {
    final t = DateTime.now();
    int a = t.year - dob.year;
    if (t.month < dob.month || (t.month == dob.month && t.day < dob.day)) a--;
    return a;
  }

  List<Widget> _divide(List<Widget> list, Widget sep) {
    final r = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      r.add(list[i]);
      if (i < list.length - 1) r.add(sep);
    }
    return r;
  }
}

// ─── APP BAR BUTTON ───────────────────────────────────────────────────────────
class _AppBarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarButton({required this.icon, required this.onTap});

  @override
  State<_AppBarButton> createState() => _AppBarButtonState();
}

class _AppBarButtonState extends State<_AppBarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ─── ANIMATED AVATAR RING ─────────────────────────────────────────────────────
class _AnimatedAvatarRing extends StatelessWidget {
  final Widget child;
  final AnimationController pulseController;
  final double scale;

  const _AnimatedAvatarRing({
    required this.child,
    required this.pulseController,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, innerChild) {
        final pulse = pulseController.value;
        return Container(
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFC084FC), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFFC084FC).withOpacity(0.3 + pulse * 0.2),
                blurRadius: 30 + pulse * 15,
                spreadRadius: pulse * 5,
              ),
            ],
          ),
          child: innerChild,
        );
      },
      child: child,
    );
  }
}

// ─── DIAGONAL STRIPE PAINTER ──────────────────────────────────────────────────
class _DiagonalStripePainter extends CustomPainter {
  final double opacity;
  const _DiagonalStripePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 28.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter old) => old.opacity != opacity;
}
