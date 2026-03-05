import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/emotional_theme_extension.dart';
import '../../../../providers/game_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a single card tile
// ─────────────────────────────────────────────────────────────────────────────

class _MemCard {
  final int id;
  final IconData icon;
  bool isFaceUp = false;
  bool isMatched = false;

  _MemCard({
    required this.id,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Memory Match Game Screen  (standalone route: /games/memory-match)
// ─────────────────────────────────────────────────────────────────────────────

class MemoryMatchGameScreen extends ConsumerStatefulWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  ConsumerState<MemoryMatchGameScreen> createState() =>
      _MemoryMatchGameScreenState();
}

class _MemoryMatchGameScreenState extends ConsumerState<MemoryMatchGameScreen> {
  // ── Constants ────────────────────────────────────────────────────────────
  static const int _gridCols = 4;
  static const int _maxScore = 1000;

  static const List<IconData> _iconPool = [
    Icons.favorite,
    Icons.star,
    Icons.pets,
    Icons.local_florist,
    Icons.wb_sunny,
    Icons.music_note,
    Icons.sports_soccer,
    Icons.cake,
  ];

  // ── Game state ───────────────────────────────────────────────────────────
  List<_MemCard> _cards = [];
  int? _firstIdx;
  int? _secondIdx;
  int _matchedPairs = 0;
  int _moves = 0;
  bool _isChecking = false; // prevent tapping while animating flip-back
  bool _gameFinished = false;
  bool _isSaving = false;

  late Stopwatch _stopwatch;
  Timer? _ticker;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  // ── Game logic ────────────────────────────────────────────────────────────

  void _startNewGame() {
    _ticker?.cancel();

    final pairs = List<_MemCard>.generate(
          _iconPool.length,
          (i) => _MemCard(id: i * 2, icon: _iconPool[i]),
        ) +
        List<_MemCard>.generate(
          _iconPool.length,
          (i) => _MemCard(id: i * 2 + 1, icon: _iconPool[i]),
        );
    pairs.shuffle(Random());

    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    setState(() {
      _cards = pairs;
      _firstIdx = null;
      _secondIdx = null;
      _matchedPairs = 0;
      _moves = 0;
      _isChecking = false;
      _gameFinished = false;
      _isSaving = false;
    });
  }

  void _onCardTap(int index) {
    final card = _cards[index];
    if (card.isMatched || card.isFaceUp || _isChecking) return;

    setState(() {
      card.isFaceUp = true;

      if (_firstIdx == null) {
        _firstIdx = index;
      } else {
        _secondIdx = index;
        _moves++;
        _isChecking = true;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    final first = _cards[_firstIdx!];
    final second = _cards[_secondIdx!];

    if (first.icon == second.icon) {
      setState(() {
        first.isMatched = true;
        second.isMatched = true;
        _matchedPairs++;
        _firstIdx = null;
        _secondIdx = null;
        _isChecking = false;
      });
      if (_matchedPairs == _iconPool.length) {
        _onGameComplete();
      }
    } else {
      // Flip back after a short delay
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _cards[_firstIdx!].isFaceUp = false;
          _cards[_secondIdx!].isFaceUp = false;
          _firstIdx = null;
          _secondIdx = null;
          _isChecking = false;
        });
      });
    }
  }

  Future<void> _onGameComplete() async {
    if (_gameFinished || _isSaving) return;
    _gameFinished = true;
    _isSaving = true;
    _stopwatch.stop();
    _ticker?.cancel();

    final elapsed = _stopwatch.elapsed.inSeconds;
    final score = max(0, _maxScore - (_moves * 10) - (elapsed * 2));

    final patientId = Supabase.instance.client.auth.currentUser?.id;
    if (patientId == null) {
      if (mounted) _showCompletionDialog(score);
      return;
    }

    try {
      await ref.read(gameRepositoryProvider).recordCompletedGame(
            gameId: 'memory_match',
            score: score,
            durationSeconds: elapsed,
            attempts: _moves,
          );
    } catch (e) {
      if (kDebugMode) print('[MemoryMatch] save error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        _showCompletionDialog(score);
      }
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showCompletionDialog(int score) {
    final emotionalTheme =
        Theme.of(context).extension<EmotionalThemeExtension>()!;
    final elapsed = _stopwatch.elapsed;
    final timeStr =
        '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: emotionalTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: emotionalTheme.primary, size: 32),
            const SizedBox(width: 12),
            Text('Congratulations!',
                style: TextStyle(color: emotionalTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You matched all the pairs!',
              style:
                  TextStyle(fontSize: 16, color: emotionalTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _StatRow(
                label: 'Score',
                value: '$score',
                color: emotionalTheme.primary!),
            _StatRow(label: 'Moves', value: '$_moves', color: Colors.blue),
            _StatRow(label: 'Time', value: timeStr, color: Colors.green),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) context.pop();
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startNewGame();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: emotionalTheme.primary),
            child: const Text(
              'Play Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final emotionalTheme =
        Theme.of(context).extension<EmotionalThemeExtension>()!;
    final elapsed = _stopwatch.elapsed;
    final timeStr =
        '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: emotionalTheme.background,
      appBar: AppBar(
        title: const Text('Memory Match'),
        backgroundColor: emotionalTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Restart',
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats Bar ────────────────────────────────────────────────────
          Container(
            color: emotionalTheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                    label: 'Moves',
                    value: '$_moves',
                    icon: Icons.touch_app,
                    color: emotionalTheme.primary!),
                _StatChip(
                    label: 'Time',
                    value: timeStr,
                    icon: Icons.timer_outlined,
                    color: emotionalTheme.secondary!),
                _StatChip(
                    label: 'Pairs',
                    value: '$_matchedPairs/${_iconPool.length}',
                    icon: Icons.check_circle_outline,
                    color: emotionalTheme.success!),
              ],
            ),
          ),

          // ── Card Grid ────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridCols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _cards.length,
                itemBuilder: (_, i) => _CardTile(
                  card: _cards[i],
                  accentColor: emotionalTheme.primary!,
                  onTap: () => _onCardTap(i),
                ),
              ),
            ),
          ),

          // ── Saving indicator ─────────────────────────────────────────────
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Saving result…',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets (const-friendly, no extra rebuilds)
// ─────────────────────────────────────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.accentColor,
    required this.onTap,
  });

  final _MemCard card;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final revealed = card.isFaceUp || card.isMatched;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: card.isMatched
              ? Colors.green.shade50
              : revealed
                  ? Colors.white
                  : accentColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: card.isMatched
              ? Border.all(color: Colors.green.shade400, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: revealed
              ? Icon(
                  card.icon,
                  size: 36,
                  color: card.isMatched ? Colors.green.shade600 : accentColor,
                )
              : const Icon(
                  Icons.help_outline_rounded,
                  size: 36,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
