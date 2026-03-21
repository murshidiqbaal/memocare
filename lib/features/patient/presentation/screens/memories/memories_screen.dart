import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memocare/features/auth/providers/auth_provider.dart';
import 'package:memocare/providers/memory_providers.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────
class _Ink {
  static const cream = Color(0xFFFDF6EC);
  static const paper = Color(0xFFF5ECD7);
  static const tape = Color(0xFFEDD9A3);
  static const shadow = Color(0xFFB8A99A);
  static const inkDark = Color(0xFF3D2B1F);
  static const inkMid = Color(0xFF7A5C4A);
  static const inkLight = Color(0xFFB0917A);
  static const accent = Color(0xFFD2691E); // warm chocolate
  static const accentSoft = Color(0xFFF4A460);
  static const white = Color(0xFFFFFDF9);
}

// ─────────────────────────────────────────────────────────────
//  Pre-computed card tilts so rebuilds don't re-randomise
// ─────────────────────────────────────────────────────────────
final _tiltList = List.generate(
  64,
  (i) {
    final rng = math.Random(i * 31 + 7);
    return (rng.nextDouble() - 0.5) * 0.08; // radians, ±~2.3°
  },
);

// ─────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────
class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final patientId = user?.id;

    if (patientId == null) {
      return const _NotLoggedIn();
    }

    final memoryState = ref.watch(memoryListProvider(patientId));

    return Scaffold(
      backgroundColor: _Ink.cream,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _AlbumAppBar(
            onRefresh: () =>
                ref.read(memoryListProvider(patientId).notifier).refresh(),
          ),
          if (memoryState.isLoading && memoryState.memories.isEmpty)
            const SliverFillRemaining(child: _LoadingState())
          else if (memoryState.error != null)
            SliverFillRemaining(
              child: _ErrorState(
                message: memoryState.error!,
                onRetry: () =>
                    ref.read(memoryListProvider(patientId).notifier).refresh(),
              ),
            )
          else if (memoryState.memories.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final memory = memoryState.memories[index];
                    final tilt = _tiltList[index % _tiltList.length];
                    return _PolaroidCard(
                      memory: memory,
                      tilt: tilt,
                      index: index,
                    );
                  },
                  childCount: memoryState.memories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Decorative SliverAppBar
// ─────────────────────────────────────────────────────────────
class _AlbumAppBar extends StatelessWidget {
  const _AlbumAppBar({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _Ink.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          children: [
            // ── Warm gradient wash ──
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF3DC), _Ink.cream],
                ),
              ),
            ),
            // ── Decorative scattered dots (film grain feel) ──
            Positioned.fill(
              child: CustomPaint(painter: _GrainPainter()),
            ),
            // ── Washi tape strip at top ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 10,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFEDD9A3),
                      Color(0xFFD4B483),
                      Color(0xFFEDD9A3),
                    ],
                  ),
                ),
              ),
            ),
            // ── Title block ──
            Positioned(
              bottom: 20,
              left: 24,
              right: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _Ink.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.photo_camera_back_rounded,
                          color: _Ink.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'My Memories',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _Ink.inkDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A lifetime of precious moments',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: _Ink.inkLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: _Ink.accent.withOpacity(0.12),
              foregroundColor: _Ink.accent,
            ),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRefresh,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Polaroid card (grid item)
// ─────────────────────────────────────────────────────────────
class _PolaroidCard extends StatefulWidget {
  const _PolaroidCard({
    required this.memory,
    required this.tilt,
    required this.index,
  });

  final dynamic memory;
  final double tilt;
  final int index;

  @override
  State<_PolaroidCard> createState() => _PolaroidCardState();
}

class _PolaroidCardState extends State<_PolaroidCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _lift;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _lift = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _lift,
      builder: (context, child) {
        final liftVal = _lift.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(0.0, -liftVal * 6)
            ..rotateZ(widget.tilt - liftVal * widget.tilt * 0.4),
          child: GestureDetector(
            onTapDown: (_) => _hoverCtrl.forward(),
            onTapUp: (_) {
              _hoverCtrl.reverse();
              _showPolaroidDialog(context, widget.memory);
            },
            onTapCancel: () => _hoverCtrl.reverse(),
            child: child,
          ),
        );
      },
      child: _buildPolaroid(context),
    );
  }

  Widget _buildPolaroid(BuildContext context) {
    final memory = widget.memory;
    return Container(
      decoration: BoxDecoration(
        color: _Ink.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: _Ink.shadow.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(3, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 0,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Photo area ──
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: memory.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: memory.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: _Ink.paper,
                          child: Center(
                            child: Icon(Icons.image_outlined,
                                color: _Ink.inkLight, size: 32),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: _Ink.paper,
                          child: Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: _Ink.inkLight, size: 32),
                          ),
                        ),
                      )
                    : Container(
                        color: _Ink.paper,
                        child: Center(
                          child: Icon(Icons.photo_outlined,
                              color: _Ink.inkLight, size: 40),
                        ),
                      ),
              ),
            ),
          ),
          // ── Caption strip ──
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _Ink.inkDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (memory.eventDate != null)
                  Text(
                    DateFormat('MMM yyyy').format(memory.eventDate!),
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: _Ink.inkLight,
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

// ─────────────────────────────────────────────────────────────
//  Full-screen polaroid detail dialog
// ─────────────────────────────────────────────────────────────
void _showPolaroidDialog(BuildContext context, dynamic memory) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0xCC3D2B1F),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, __, ___) => _PolaroidDetailView(memory: memory),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.elasticOut);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.55, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      );
    },
  );
}

class _PolaroidDetailView extends StatefulWidget {
  const _PolaroidDetailView({required this.memory});
  final dynamic memory;

  @override
  State<_PolaroidDetailView> createState() => _PolaroidDetailViewState();
}

class _PolaroidDetailViewState extends State<_PolaroidDetailView>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.03), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.03, end: -0.03), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.015), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.015, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    // Gentle initial shake to simulate "dropping on table"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shakeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW * 0.82).clamp(260.0, 380.0);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // absorb taps on the card
            child: AnimatedBuilder(
              animation: _shake,
              builder: (_, child) => Transform.rotate(
                angle: _shake.value,
                child: child,
              ),
              child: SizedBox(
                width: cardW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Washi tape across top ──
                    _WashiTape(width: cardW * 0.55),
                    const SizedBox(height: 4),
                    // ── Polaroid body ──
                    Container(
                      decoration: BoxDecoration(
                        color: _Ink.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 40,
                            spreadRadius: 2,
                            offset: const Offset(0, 20),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Photo ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: memory.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: memory.imageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: _Ink.paper,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: _Ink.accent,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: _Ink.paper,
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 56,
                                            color: _Ink.inkLight,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: _Ink.paper,
                                        child: Icon(Icons.photo_outlined,
                                            size: 72, color: _Ink.inkLight),
                                      ),
                              ),
                            ),
                          ),

                          // ── Caption area ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Decorative divider line
                                Container(
                                  height: 1,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _Ink.shadow.withOpacity(0),
                                        _Ink.shadow.withOpacity(0.4),
                                        _Ink.shadow.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),

                                Text(
                                  memory.title,
                                  style: const TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _Ink.inkDark,
                                    height: 1.2,
                                  ),
                                ),

                                if (memory.eventDate != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 11, color: _Ink.inkLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMMM d, yyyy')
                                            .format(memory.eventDate!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: _Ink.inkLight,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                if (memory.description != null &&
                                    (memory.description as String)
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 120),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        memory.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _Ink.inkMid,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // Close button styled as a stamp
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: _Ink.accent, width: 1.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'close',
                                        style: TextStyle(
                                          fontFamily: 'Georgia',
                                          fontStyle: FontStyle.italic,
                                          fontSize: 13,
                                          color: _Ink.accent,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Washi tape decoration
// ─────────────────────────────────────────────────────────────
class _WashiTape extends StatelessWidget {
  const _WashiTape({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 22,
      decoration: BoxDecoration(
        color: _Ink.tape.withOpacity(0.75),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(painter: _WashiPatternPainter()),
    );
  }
}

class _WashiPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;
    const spacing = 10.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + spacing * 0.5, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
//  Film grain painter for app bar
// ─────────────────────────────────────────────────────────────
class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _Ink.shadow.withOpacity(0.06);
    final rng = math.Random(42);
    for (int i = 0; i < 180; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
//  Empty / Error / Loading / NotLoggedIn states
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Blank polaroid illustration
            Container(
              width: 140,
              height: 160,
              decoration: BoxDecoration(
                color: _Ink.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: _Ink.shadow.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(4, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _Ink.paper,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Icon(Icons.add_photo_alternate_outlined,
                            color: _Ink.inkLight.withOpacity(0.6), size: 48),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: _Ink.paper,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No memories yet',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _Ink.inkDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your caregiver will add\nphotos and stories here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: _Ink.inkLight,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: _Ink.accent,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Developing your memories…',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: _Ink.inkLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 64, color: _Ink.inkLight),
            const SizedBox(height: 16),
            Text(
              'Couldn\'t load memories',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _Ink.inkDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _Ink.inkLight),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _Ink.accent,
                side: const BorderSide(color: _Ink.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Ink.cream,
      body: Center(
        child: Text(
          'Please log in to view memories',
          style: TextStyle(color: _Ink.inkMid, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
