import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memocare/providers/game_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mini_games/shape_sorter_game.dart';
import 'mini_games/word_puzzle_game.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens — arcade space theme
// ─────────────────────────────────────────────────────────────
class _G {
  // Backgrounds
  static const bg = Color(0xFF0B0F1A);
  static const surface = Color(0xFF141927);
  static const card = Color(0xFF1C2333);

  // Glow colours per game
  static const amber = Color(0xFFF59E0B);
  static const coral = Color(0xFFFF6B6B);
  static const emerald = Color(0xFF10B981);
  static const sky = Color(0xFF38BDF8);
  static const violet = Color(0xFF8B5CF6);

  static const textPrimary = Color(0xFFF0F4FF);
  static const textMuted = Color(0xFF8896B3);

  static const starColor = Color(0xFFFFFFFF);
}

// ─────────────────────────────────────────────────────────────
//  Star-field painter (background decoration)
// ─────────────────────────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final paint = Paint();
    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.4 + 0.3;
      final opacity = rng.nextDouble() * 0.55 + 0.1;
      paint.color = _G.starColor.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
//  Glow border painter
// ─────────────────────────────────────────────────────────────
class _GlowBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _GlowBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        RRect.fromLTRBR(0, 0, size.width, size.height, Radius.circular(radius));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter old) =>
      old.color != color || old.radius != radius;
}

// ─────────────────────────────────────────────────────────────
//  Game data model
// ─────────────────────────────────────────────────────────────
class _GameInfo {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final String? badge;

  const _GameInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    this.badge,
  });
}

const _games = [
  _GameInfo(
    id: 'memory_match',
    title: 'Memory Match',
    description: 'Flip cards and find matching pairs',
    emoji: '🧠',
    color: _G.amber,
  ),
  _GameInfo(
    id: 'word_puzzle',
    title: 'Word Puzzle',
    description: 'Find words to keep your mind sharp',
    emoji: '💬',
    color: _G.coral,
  ),
  _GameInfo(
    id: 'shape_sorter',
    title: 'Shape Sorter',
    description: 'Sort shapes by colour and type',
    emoji: '🔷',
    color: _G.emerald,
  ),
  _GameInfo(
    id: 'reaction_tap',
    title: 'Reaction Tap',
    description: 'Tap fast when the button turns green',
    emoji: '⚡',
    color: _G.sky,
    // badge: 'New',
  ),
];

// ─────────────────────────────────────────────────────────────
//  GamesScreen (lobby)
// ─────────────────────────────────────────────────────────────
class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedGame;
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientId = Supabase.instance.client.auth.currentUser?.id;

    if (patientId == null) {
      return const _NotLoggedIn();
    }

    // Route into a selected game
    if (_selectedGame == 'memory_match') {
      return MemoryMatchGame(
        patientId: patientId,
        onExit: () => setState(() {
          _selectedGame = null;
          _staggerCtrl
            ..reset()
            ..forward();
        }),
      );
    } else if (_selectedGame == 'word_puzzle') {
      return WordPuzzleGame(
        patientId: patientId,
        onExit: () => setState(() {
          _selectedGame = null;
          _staggerCtrl
            ..reset()
            ..forward();
        }),
      );
    } else if (_selectedGame == 'shape_sorter') {
      return ShapeSorterGame(
        patientId: patientId,
        onExit: () => setState(() {
          _selectedGame = null;
          _staggerCtrl
            ..reset()
            ..forward();
        }),
      );
    }

    // ── Lobby ──
    return Scaffold(
      backgroundColor: _G.bg,
      body: Stack(
        children: [
          // Starfield
          Positioned.fill(
            child: CustomPaint(painter: _StarfieldPainter()),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _G.violet.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _G.violet.withOpacity(0.35)),
                            ),
                            child: const Text('🎮',
                                style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Brain Games',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _G.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Keep your mind active & sharp',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _G.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Neon accent line
                      Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _G.violet.withOpacity(0),
                              _G.violet.withOpacity(0.7),
                              _G.sky.withOpacity(0.7),
                              _G.sky.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Game list ──
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    itemCount: _games.length,
                    itemBuilder: (context, i) {
                      final delay = i * 0.18;
                      final anim = CurvedAnimation(
                        parent: _staggerCtrl,
                        curve: Interval(
                          delay.clamp(0.0, 0.9),
                          (delay + 0.55).clamp(0.0, 1.0),
                          curve: Curves.easeOutCubic,
                        ),
                      );
                      return AnimatedBuilder(
                        animation: anim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, 40 * (1 - anim.value)),
                          child: Opacity(opacity: anim.value, child: child),
                        ),
                        child: _GameTile(
                          game: _games[i],
                          onTap: () {
                            if (_games[i].id == 'reaction_tap') {
                              context.push('/games/reaction-tap');
                            } else {
                              setState(() => _selectedGame = _games[i].id);
                            }
                          },
                        ),
                      );
                    },
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
//  Individual game tile
// ─────────────────────────────────────────────────────────────
class _GameTile extends StatefulWidget {
  const _GameTile({required this.game, required this.onTap});
  final _GameInfo game;
  final VoidCallback onTap;

  @override
  State<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<_GameTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: GestureDetector(
          onTapDown: (_) => _pressCtrl.forward(),
          onTapUp: (_) {
            _pressCtrl.reverse();
            widget.onTap();
          },
          onTapCancel: () => _pressCtrl.reverse(),
          child: CustomPaint(
            painter: _GlowBorderPainter(color: g.color, radius: 22),
            child: Container(
              decoration: BoxDecoration(
                color: _G.card,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Icon tile
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: g.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: g.color.withOpacity(0.3), width: 1),
                      ),
                      child: Center(
                        child:
                            Text(g.emoji, style: const TextStyle(fontSize: 36)),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                g.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _G.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (g.badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: g.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: g.color.withOpacity(0.45)),
                                  ),
                                  child: Text(
                                    g.badge!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: g.color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            g.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _G.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Arrow
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: g.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: g.color, size: 18),
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
//  MemoryMatchGame — redesigned
// ─────────────────────────────────────────────────────────────
class MemoryMatchGame extends ConsumerStatefulWidget {
  final String patientId;
  final VoidCallback onExit;

  const MemoryMatchGame({
    super.key,
    required this.patientId,
    required this.onExit,
  });

  @override
  ConsumerState<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends ConsumerState<MemoryMatchGame>
    with TickerProviderStateMixin {
  static const int gridSize = 4;
  static const List<String> _emojis = [
    '🌸',
    '⭐',
    '🐶',
    '🌻',
    '☀️',
    '🎵',
    '⚽',
    '🎂',
  ];

  List<MemCard> cards = [];
  int? firstIdx;
  int? secondIdx;
  int matchedPairs = 0;
  int moves = 0;
  late Stopwatch stopwatch;
  Timer? timer;
  bool _gameFinished = false;

  // Per-card flip controllers
  final List<AnimationController> _flipCtrl = [];
  final List<Animation<double>> _flipAnim = [];

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in _flipCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _setupGame() {
    _gameFinished = false;
    stopwatch = Stopwatch()..start();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    final temp = <MemCard>[];
    for (int i = 0; i < _emojis.length; i++) {
      temp.add(MemCard(id: i * 2, emoji: _emojis[i]));
      temp.add(MemCard(id: i * 2 + 1, emoji: _emojis[i]));
    }
    temp.shuffle(Random());
    cards = temp;
    firstIdx = null;
    secondIdx = null;
    matchedPairs = 0;
    moves = 0;

    // Create flip controllers
    for (final c in _flipCtrl) {
      c.dispose();
    }
    _flipCtrl.clear();
    _flipAnim.clear();

    for (int i = 0; i < cards.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      final anim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
      _flipCtrl.add(ctrl);
      _flipAnim.add(anim);
    }
  }

  void _restart() {
    setState(() {
      _setupGame();
    });
  }

  void _onTap(int index) {
    if (cards[index].isMatched || cards[index].isFaceUp) return;
    if (firstIdx != null && secondIdx != null) return;

    _flipCtrl[index].forward();

    setState(() {
      cards[index].isFaceUp = true;

      if (firstIdx == null) {
        firstIdx = index;
      } else {
        secondIdx = index;
        moves++;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    if (firstIdx == null || secondIdx == null) return;

    final a = cards[firstIdx!];
    final b = cards[secondIdx!];

    if (a.emoji == b.emoji) {
      setState(() {
        cards[firstIdx!].isMatched = true;
        cards[secondIdx!].isMatched = true;
        matchedPairs++;
        firstIdx = null;
        secondIdx = null;
      });

      if (matchedPairs == _emojis.length) {
        _onGameComplete();
      }
    } else {
      final fi = firstIdx!;
      final si = secondIdx!;
      firstIdx = null;
      secondIdx = null;

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _flipCtrl[fi].reverse();
        _flipCtrl[si].reverse();
        setState(() {
          cards[fi].isFaceUp = false;
          cards[si].isFaceUp = false;
        });
      });
    }
  }

  Future<void> _onGameComplete() async {
    if (_gameFinished) return;
    _gameFinished = true;
    stopwatch.stop();
    timer?.cancel();

    final score =
        max(0, 1000 - (moves * 10) - (stopwatch.elapsed.inSeconds * 2));

    try {
      await ref.read(gameRepositoryProvider).recordCompletedGame(
            gameId: 'memory_match',
            score: score,
            durationSeconds: stopwatch.elapsed.inSeconds,
            attempts: moves,
          );
    } catch (e) {
      if (kDebugMode) print('Save error: $e');
    }

    if (mounted) _showWinDialog(score);
  }

  void _showWinDialog(int score) {
    final elapsed = stopwatch.elapsed;
    final timeStr =
        '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => _WinDialog(
        score: score,
        moves: moves,
        time: timeStr,
        onPlayAgain: () {
          Navigator.pop(context);
          _restart();
        },
        onExit: () {
          Navigator.pop(context);
          widget.onExit();
        },
      ),
    );
  }

  String get _elapsed {
    final e = stopwatch.elapsed;
    return '${e.inMinutes}:${(e.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _G.bg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StarfieldPainter())),
          SafeArea(
            child: Column(
              children: [
                // ── AppBar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _IconBtn(
                        icon: Icons.arrow_back_rounded,
                        color: _G.amber,
                        onTap: widget.onExit,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Memory Match',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _G.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Spacer(),
                      _IconBtn(
                        icon: Icons.refresh_rounded,
                        color: _G.amber,
                        onTap: _restart,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Stats row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _StatPill(
                          label: 'Moves', value: '$moves', color: _G.amber),
                      const SizedBox(width: 12),
                      _StatPill(label: 'Time', value: _elapsed, color: _G.sky),
                      const SizedBox(width: 12),
                      _StatPill(
                        label: 'Pairs',
                        value: '$matchedPairs / ${_emojis.length}',
                        color: _G.emerald,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Grid ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSize,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, i) => _FlipCard(
                        card: cards[i],
                        anim: _flipAnim[i],
                        onTap: () => _onTap(i),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Flip card widget
// ─────────────────────────────────────────────────────────────
class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.card,
    required this.anim,
    required this.onTap,
  });

  final MemCard card;
  final Animation<double> anim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, __) {
          final angle = anim.value * pi;
          final isShowingFront = angle > pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isShowingFront
                // Front (emoji) — flip back to read correctly
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _CardFace(
                      isFront: true,
                      card: card,
                    ),
                  )
                // Back
                : _CardFace(isFront: false, card: card),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.isFront, required this.card});
  final bool isFront;
  final MemCard card;

  @override
  Widget build(BuildContext context) {
    if (!isFront) {
      // Back of card — star pattern
      return Container(
        decoration: BoxDecoration(
          color: _G.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _G.amber.withOpacity(0.3), width: 1),
        ),
        child: Center(
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: 28,
              color: _G.amber.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    // Front of card
    final glowColor = card.isMatched ? _G.emerald : _G.amber;

    return CustomPaint(
      painter: _GlowBorderPainter(color: glowColor, radius: 14),
      child: Container(
        decoration: BoxDecoration(
          color: card.isMatched ? _G.emerald.withOpacity(0.12) : _G.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            card.emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Win dialog
// ─────────────────────────────────────────────────────────────
class _WinDialog extends StatelessWidget {
  const _WinDialog({
    required this.score,
    required this.moves,
    required this.time,
    required this.onPlayAgain,
    required this.onExit,
  });

  final int score;
  final int moves;
  final String time;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: CustomPaint(
        painter: _GlowBorderPainter(color: _G.amber, radius: 28),
        child: Container(
          decoration: BoxDecoration(
            color: _G.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text(
                'You Did It!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _G.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fantastic memory skills!',
                style: TextStyle(
                  fontSize: 14,
                  color: _G.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              // Stats
              Row(
                children: [
                  _WinStat(label: 'Score', value: '$score', color: _G.amber),
                  const SizedBox(width: 10),
                  _WinStat(label: 'Moves', value: '$moves', color: _G.sky),
                  const SizedBox(width: 10),
                  _WinStat(label: 'Time', value: time, color: _G.emerald),
                ],
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: _DialogBtn(
                      label: 'Exit',
                      onTap: onExit,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogBtn(
                      label: 'Play Again',
                      onTap: onPlayAgain,
                      color: _G.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinStat extends StatelessWidget {
  const _WinStat(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: _G.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  const _DialogBtn({
    required this.label,
    required this.onTap,
    this.color,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : (color ?? _G.amber),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                outlined ? _G.textMuted.withOpacity(0.3) : (color ?? _G.amber),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: outlined ? _G.textMuted : _G.bg,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared small widgets
// ─────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _G.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _G.bg,
      body: Center(
        child: Text(
          'Please log in to play games',
          style: TextStyle(color: _G.textMuted),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MemCard model
// ─────────────────────────────────────────────────────────────
class MemCard {
  final int id;
  final String emoji;
  bool isFaceUp;
  bool isMatched;

  MemCard({
    required this.id,
    required this.emoji,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}
