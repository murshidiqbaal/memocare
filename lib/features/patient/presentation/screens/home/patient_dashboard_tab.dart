import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memocare/core/services/location_tracking_service.dart';
import 'package:memocare/data/models/reminder.dart';
import 'package:memocare/features/auth/providers/auth_provider.dart';
import 'package:memocare/features/patient/presentation/screens/games/games_screen.dart';
import 'package:memocare/features/patient/presentation/screens/home/viewmodels/home_viewmodel.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/memory_highlight_widget.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/offline_status_widget.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/reminder_section_card.dart';
import 'package:memocare/features/patient/presentation/screens/home/widgets/safety_status_card.dart';
import 'package:memocare/features/patient/presentation/screens/memories/memories_screen.dart';
import 'package:memocare/features/patient/presentation/screens/reminders/add_edit_reminder_screen.dart';
import 'package:memocare/features/patient/presentation/screens/reminders/reminder_list_screen.dart';
import 'package:memocare/features/patient/presentation/screens/sos/patient_emergency_alert_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens — warm morning light
// ─────────────────────────────────────────────────────────────
class _D {
  // Backgrounds
  static const bg = Color(0xFFFFF8F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFF3E8);

  // Accent palette
  static const lavender = Color(0xFF7C5CBF); // primary / header
  static const lavenderSoft = Color(0xFFEDE8F8);
  static const teal = Color(0xFF0D9488); // reminders
  static const tealSoft = Color(0xFFE0F5F3);
  static const sage = Color(0xFF4A7C6F); // safety
  static const sageSoft = Color(0xFFE6F2EF);
  static const amber = Color(0xFFD97706); // memories
  static const amberSoft = Color(0xFFFFF3D6);
  static const rose = Color(0xFFE11D48); // SOS
  static const roseSoft = Color(0xFFFFE4EC);
  static const coral = Color(0xFFEA6B47); // games

  // Text
  static const inkDark = Color(0xFF1E1B2E);
  static const inkMid = Color(0xFF5C5470);
  static const inkLight = Color(0xFF9B96AA);

  // Shadow
  static const shadowWarm = Color(0xFFD4B8A0);
}

// ─────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────
String _timeOfDayLabel() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String _timeOfDayEmoji() {
  final h = DateTime.now().hour;
  if (h < 12) return '🌅';
  if (h < 17) return '☀️';
  return '🌙';
}

// ─────────────────────────────────────────────────────────────
//  Wave painter for header background
// ─────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.35,
        size.width * 0.65,
        size.height * 0.75,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final path2 = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.7,
        size.height * 0.85,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path2,
      paint..color = Colors.white.withOpacity(0.08),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
//  Dot pattern painter (decorative)
// ─────────────────────────────────────────────────────────────
class _DotsPainter extends CustomPainter {
  final Color color;
  _DotsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.18);
    const spacing = 18.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
//  Main dashboard
// ─────────────────────────────────────────────────────────────
final userId = Supabase.instance.client.auth.currentUser!.id;

class PatientDashboardTab extends ConsumerStatefulWidget {
  const PatientDashboardTab({super.key});

  @override
  ConsumerState<PatientDashboardTab> createState() =>
      _PatientDashboardTabState();
}

class _PatientDashboardTabState extends ConsumerState<PatientDashboardTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTrackingIfPossible();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _startTrackingIfPossible() {
    final patientId = ref.read(currentPatientIdProvider).value;
    if (patientId != null) {
      ref.read(locationTrackingServiceProvider).startTracking(userId);
    }
  }

  Animation<double> _stagger(int index) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(
          (index * 0.12).clamp(0.0, 0.8),
          ((index * 0.12) + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  @override
  Widget build(BuildContext context) {
    ref.listen(currentPatientIdProvider, (prev, next) {
      if (next.value != null && prev?.value == null) {
        _startTrackingIfPossible();
      }
    });

    final homeState = ref.watch(homeViewModelProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: _D.bg,
      body: Stack(
        children: [
          // ── Dot pattern in bg ──
          Positioned.fill(
            child: CustomPaint(painter: _DotsPainter(_D.lavender)),
          ),

          // ── Main scroll area ──
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Greeting header ──
              SliverToBoxAdapter(
                child: _SlideIn(
                  anim: _stagger(0),
                  child: _GreetingHeader(profileAsync: profileAsync),
                ),
              ),

              // ── Body ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Offline banner
                    if (homeState.isOffline) ...[
                      _SlideIn(
                        anim: _stagger(1),
                        child: _OfflineBanner(isOffline: homeState.isOffline),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Quick actions row
                    _SlideIn(
                      anim: _stagger(1),
                      child: _QuickActionsRow(
                        onMemories: () => _push(
                          context,
                          const MemoriesScreen(),
                        ),
                        onGames: () => _push(
                          context,
                          const GamesScreen(),
                        ),
                        onSOS: () => _push(
                          context,
                          const PatientEmergencyAlertScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Caregiver card
                    // _SlideIn(
                    //   anim: _stagger(2),
                    //   child: _SectionLabel(
                    //     label: 'My Caregiver',
                    //     icon: Icons.favorite_rounded,
                    //     color: _D.lavender,
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // _SlideIn(
                    //   anim: _stagger(2),
                    //   child: _CardShell(
                    //     child: const CaregiverDashCard(),
                    //   ),
                    // ),

                    const SizedBox(height: 20),

                    // Safety status
                    if (profileAsync.value != null) ...[
                      _SlideIn(
                        anim: _stagger(3),
                        child: _SectionLabel(
                          label: 'Safety Status',
                          icon: Icons.shield_rounded,
                          color: _D.sage,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SlideIn(
                        anim: _stagger(3),
                        child: _CardShell(
                          accentColor: _D.sage,
                          child: SafetyStatusCard(
                            patientId: profileAsync.value!.id,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Reminders
                    _SlideIn(
                      anim: _stagger(4),
                      child: _SectionLabel(
                        label: "Today's Reminders",
                        icon: Icons.alarm_rounded,
                        color: _D.teal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SlideIn(
                      anim: _stagger(4),
                      child: _CardShell(
                        accentColor: _D.teal,
                        child: ReminderSectionCard(
                          onAddPressed: () => _navigateToAddReminder(context),
                          onViewAllPressed: () => _navigateToReminders(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Memory of the day
                    _SlideIn(
                      anim: _stagger(5),
                      child: _SectionLabel(
                        label: 'Memory of the Day',
                        icon: Icons.auto_awesome_rounded,
                        color: _D.amber,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SlideIn(
                      anim: _stagger(5),
                      child: _CardShell(
                        accentColor: _D.amber,
                        child: MemoryHighlightCard(
                          onViewDay: () => _push(
                            context,
                            const MemoriesScreen(),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // // ── Floating SOS button (bottom-right) ──
          // Positioned(
          //   bottom: 24,
          //   right: 20,
          //   child: _SlideIn(
          //     anim: _stagger(6),
          //     child: _SOSFab(
          //       onTap: () => _push(
          //         context,
          //         const PatientEmergencyAlertScreen(),
          //       ),
          //     ),
          //   ),
          // ),

          // ── Floating add reminder (bottom-right above SOS) ──
          Positioned(
            bottom: 25,
            right: 25,
            child: _SlideIn(
              anim: _stagger(6),
              child: _MiniReminderFab(
                onTap: () => _navigateToAddReminder(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _navigateToReminders(BuildContext context) => _push(
        context,
        const ReminderListScreen(),
      );

  void _navigateToAddReminder(BuildContext context) => _push(
        context,
        const AddEditReminderScreen(
          initialTitle: '',
          initialType: ReminderType.task,
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  Greeting header
// ─────────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.profileAsync});
  final AsyncValue profileAsync;

  @override
  Widget build(BuildContext context) {
    final name = profileAsync.value?.fullName?.split(' ').first ?? '';
    final today = _todayString();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C5CBF), Color(0xFF5B4A8A)],
        ),
      ),
      child: Stack(
        children: [
          // Wave decoration
          Positioned.fill(
            child: CustomPaint(painter: _WavePainter()),
          ),
          // Dot decor top-right
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(painter: _DotsPainter(Colors.white)),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji + greeting
                  Row(
                    children: [
                      Text(
                        _timeOfDayEmoji(),
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeOfDayLabel(),
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Name
                  Text(
                    name.isNotEmpty ? name : 'Welcome Back',
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Date chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 13, color: Colors.white.withOpacity(0.85)),
                        const SizedBox(width: 6),
                        Text(
                          today,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _todayString() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final weekday = days[now.weekday - 1];
    return '$weekday, ${months[now.month - 1]} ${now.day}';
  }
}

// ─────────────────────────────────────────────────────────────
//  Quick actions row
// ─────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onMemories,
    required this.onGames,
    required this.onSOS,
  });

  final VoidCallback onMemories;
  final VoidCallback onGames;
  final VoidCallback onSOS;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickTile(
          emoji: '📸',
          label: 'Memories',
          color: _D.amber,
          softColor: _D.amberSoft,
          onTap: onMemories,
        ),
        const SizedBox(width: 12),
        _QuickTile(
          emoji: '🎮',
          label: 'Games',
          color: _D.coral,
          softColor: const Color(0xFFFFF0EB),
          onTap: onGames,
        ),
        const SizedBox(width: 12),
        _QuickTile(
          emoji: '🚨',
          label: 'SOS',
          color: _D.rose,
          softColor: _D.roseSoft,
          onTap: onSOS,
          isSOS: true,
        ),
      ],
    );
  }
}

class _QuickTile extends StatefulWidget {
  const _QuickTile({
    required this.emoji,
    required this.label,
    required this.color,
    required this.softColor,
    required this.onTap,
    this.isSOS = false,
  });

  final String emoji, label;
  final Color color, softColor;
  final VoidCallback onTap;
  final bool isSOS;

  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: GestureDetector(
          onTapDown: (_) => _ctrl.forward(),
          onTapUp: (_) {
            _ctrl.reverse();
            widget.onTap();
          },
          onTapCancel: () => _ctrl.reverse(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: widget.softColor,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: widget.color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(widget.isSOS ? 0.25 : 0.12),
                  blurRadius: widget.isSOS ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                    letterSpacing: 0.2,
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
//  Section label
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _D.inkDark,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Card shell wrapper
// ─────────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.accentColor});
  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(22),
        border: accentColor != null
            ? Border.all(color: accentColor!.withOpacity(0.18), width: 1.5)
            : Border.all(color: _D.shadowWarm.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: (accentColor ?? _D.shadowWarm).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 0,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      // Clip the child so it respects the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Offline banner
// ─────────────────────────────────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.isOffline});
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return OfflineStatusIndicator(isOffline: isOffline);
  }
}

// ─────────────────────────────────────────────────────────────
//  SOS floating button
// ─────────────────────────────────────────────────────────────
class _SOSFab extends StatefulWidget {
  const _SOSFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SOSFab> createState() => _SOSFabState();
}

class _SOSFabState extends State<_SOSFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ring = Tween(begin: 0.85, end: 1.35).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            AnimatedBuilder(
              animation: _ring,
              builder: (_, __) => Transform.scale(
                scale: _ring.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _D.rose.withOpacity(0.4 * (1 - _pulse.value)),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            // Button
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _D.rose,
                boxShadow: [
                  BoxShadow(
                    color: _D.rose.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sos_rounded, color: Colors.white, size: 22),
                  SizedBox(height: 1),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Mini reminder FAB
// ─────────────────────────────────────────────────────────────
class _MiniReminderFab extends StatelessWidget {
  const _MiniReminderFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _D.teal,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _D.teal.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child:
            const Icon(Icons.add_alarm_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Slide-in animation wrapper
// ─────────────────────────────────────────────────────────────
class _SlideIn extends AnimatedWidget {
  const _SlideIn({required this.anim, required this.child})
      : super(listenable: anim);

  final Animation<double> anim;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, 28 * (1 - anim.value)),
      child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
    );
  }
}
