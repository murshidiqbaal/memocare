import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../providers/game_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reaction Tap Game Screen  (standalone route: /games/reaction-tap)
//
// How it works:
//  • Phase 1 – "Get Ready": A random countdown (1.5–4 s) where the button
//    is inactive (grey). Tapping during this phase is penalised (false start).
//  • Phase 2 – "TAP NOW!": The button turns bright teal. The player must tap
//    as quickly as possible. Reaction time in ms is recorded.
//  • Each round result is shown, 5 rounds total.
//  • Final score = MAX(0, 1000 – avgReactionMs).  Saved via gameRepository.
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { idle, waiting, ready, result, finished }

class ReactionTapGameScreen extends ConsumerStatefulWidget {
  const ReactionTapGameScreen({super.key});

  @override
  ConsumerState<ReactionTapGameScreen> createState() =>
      _ReactionTapGameScreenState();
}

class _ReactionTapGameScreenState extends ConsumerState<ReactionTapGameScreen> {
  // ── Constants ─────────────────────────────────────────────────────────────
  static const int _totalRounds = 5;
  static const Color _waitColor = Color(0xFFEF4444); // red – don't tap yet
  static const Color _goColor = Color(0xFF10B981); // teal – tap now!
  static const Color _accentColor = Color(0xFF0EA5E9); // sky blue theme

  // ── State ─────────────────────────────────────────────────────────────────
  _Phase _phase = _Phase.idle;
  int _round = 0;
  final List<int> _reactionTimes = []; // ms per round
  int? _lastReactionMs;
  bool _falseStart = false;
  bool _isSaving = false;
  bool _gameSaved = false;

  // Internal
  Timer? _waitTimer;
  Stopwatch? _reactionStopwatch;
  final Random _rng = Random();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _waitTimer?.cancel();
    _reactionStopwatch?.stop();
    super.dispose();
  }

  // ── Game logic ────────────────────────────────────────────────────────────

  void _startRound() {
    _waitTimer?.cancel();
    _falseStart = false;
    _lastReactionMs = null;

    setState(() => _phase = _Phase.waiting);

    // Random delay between 1.5 and 4 seconds
    final delayMs = 1500 + _rng.nextInt(2500);
    _waitTimer = Timer(Duration(milliseconds: delayMs), _showTarget);
  }

  void _showTarget() {
    if (!mounted) return;
    _reactionStopwatch = Stopwatch()..start();
    setState(() => _phase = _Phase.ready);
  }

  void _onTap() {
    switch (_phase) {
      case _Phase.idle:
      case _Phase.result:
        // "Start" or "Next Round"
        _round++;
        _startRound();

      case _Phase.waiting:
        // False start! Penalise
        _waitTimer?.cancel();
        setState(() {
          _falseStart = true;
          _phase = _Phase.result;
          _lastReactionMs = null;
          // Add a large penalty value
          _reactionTimes.add(1500);
        });
        _checkFinished();

      case _Phase.ready:
        _reactionStopwatch?.stop();
        final ms = _reactionStopwatch?.elapsedMilliseconds ?? 999;
        setState(() {
          _lastReactionMs = ms;
          _reactionTimes.add(ms);
          _phase = _Phase.result;
        });
        _checkFinished();

      case _Phase.finished:
        break; // handled by save/exit buttons
    }
  }

  void _checkFinished() {
    if (_reactionTimes.length >= _totalRounds) {
      setState(() => _phase = _Phase.finished);
      _saveResult();
    }
  }

  int get _avgMs {
    if (_reactionTimes.isEmpty) return 0;
    return (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length)
        .round();
  }

  int get _finalScore => max(0, 1000 - _avgMs);

  Future<void> _saveResult() async {
    if (_gameSaved || _isSaving) return;
    _isSaving = true;

    final patientId = Supabase.instance.client.auth.currentUser?.id;
    if (patientId == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      await ref.read(gameRepositoryProvider).recordCompletedGame(
            gameId: 'reaction_tap',
            score: _finalScore,
            durationSeconds: _totalRounds * 2, // approx session length
            attempts: _totalRounds,
          );
      _gameSaved = true;
    } catch (e) {
      if (kDebugMode) print('[ReactionTap] save error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetGame() {
    _waitTimer?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _round = 0;
      _reactionTimes.clear();
      _lastReactionMs = null;
      _falseStart = false;
      _isSaving = false;
      _gameSaved = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF), // light sky tint
      appBar: AppBar(
        title: const Text('Reaction Tap'),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _waitTimer?.cancel();
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Restart',
            onPressed: _resetGame,
          ),
        ],
      ),
      body: SafeArea(
        child: _phase == _Phase.finished
            ? _buildResultsPanel()
            : _buildGamePanel(),
      ),
    );
  }

  // ── Panels ────────────────────────────────────────────────────────────────

  Widget _buildGamePanel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Round indicator
          _RoundIndicator(
            current: _phase == _Phase.idle ? 0 : _round,
            total: _totalRounds,
            accentColor: _accentColor,
          ),

          const SizedBox(height: 32),

          // Instruction card
          _InstructionCard(
            phase: _phase,
            lastReactionMs: _lastReactionMs,
            falseStart: _falseStart,
            accentColor: _accentColor,
          ),

          const Spacer(),

          // The big tap button
          _TapButton(
            phase: _phase,
            onTap: _onTap,
            waitColor: _waitColor,
            goColor: _goColor,
            accentColor: _accentColor,
          ),

          const Spacer(),

          // Round history
          if (_reactionTimes.isNotEmpty)
            _RoundHistory(
              reactionTimes: _reactionTimes,
              accentColor: _accentColor,
            ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trophy
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade300, width: 3),
              ),
              child:
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 56),
            ),
          ),
          const SizedBox(height: 20),

          // Headline
          Center(
            child: Text(
              'Game Complete!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Your average reaction time',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ),

          const SizedBox(height: 24),

          // Big avg time card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor, _accentColor.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '$_avgMs ms',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _reactionLabel(_avgMs),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Score chip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Final Score',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  '$_finalScore',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Per-round breakdown
          _RoundHistory(
              reactionTimes: _reactionTimes, accentColor: _accentColor),

          const SizedBox(height: 24),

          if (_isSaving)
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Exit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Play Again',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _reactionLabel(int ms) {
    if (ms < 200) return '⚡ Lightning Fast!';
    if (ms < 300) return '🏆 Excellent!';
    if (ms < 450) return '👍 Good Job!';
    if (ms < 650) return '🙂 Keep Practising';
    return '💪 You Can Do It!';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RoundIndicator extends StatelessWidget {
  const _RoundIndicator({
    required this.current,
    required this.total,
    required this.accentColor,
  });
  final int current;
  final int total;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final done = i < current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: done ? 28 : 20,
              height: 8,
              decoration: BoxDecoration(
                color: done ? accentColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          current == 0 ? 'Tap to begin' : 'Round $current of $total',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.phase,
    required this.lastReactionMs,
    required this.falseStart,
    required this.accentColor,
  });
  final _Phase phase;
  final int? lastReactionMs;
  final bool falseStart;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (phase) {
      _Phase.idle => (
          'Tap the button below to start!',
          const Color(0xFFE0F2FE),
          accentColor
        ),
      _Phase.waiting => (
          'Wait for Green…',
          const Color(0xFFFEF2F2),
          const Color(0xFFEF4444)
        ),
      _Phase.ready => (
          'TAP NOW!',
          const Color(0xFFD1FAE5),
          const Color(0xFF059669)
        ),
      _Phase.result when falseStart => (
          '⚠ Too early! Penalty added.',
          const Color(0xFFFFF7ED),
          const Color(0xFFF97316)
        ),
      _Phase.result => (
          '✅ $lastReactionMs ms — tap to continue',
          const Color(0xFFD1FAE5),
          const Color(0xFF059669)
        ),
      _Phase.finished => (
          'All rounds complete!',
          const Color(0xFFE0F2FE),
          accentColor
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

class _TapButton extends StatelessWidget {
  const _TapButton({
    required this.phase,
    required this.onTap,
    required this.waitColor,
    required this.goColor,
    required this.accentColor,
  });
  final _Phase phase;
  final VoidCallback onTap;
  final Color waitColor;
  final Color goColor;
  final Color accentColor;

  Color get _buttonColor => switch (phase) {
        _Phase.waiting => waitColor,
        _Phase.ready => goColor,
        _ => accentColor,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: _buttonColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _buttonColor.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                phase == _Phase.ready
                    ? Icons.touch_app_rounded
                    : phase == _Phase.waiting
                        ? Icons.hourglass_top_rounded
                        : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 8),
              Text(
                phase == _Phase.ready
                    ? 'TAP!'
                    : phase == _Phase.waiting
                        ? 'Wait…'
                        : phase == _Phase.idle
                            ? 'Start'
                            : 'Next',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundHistory extends StatelessWidget {
  const _RoundHistory({
    required this.reactionTimes,
    required this.accentColor,
  });
  final List<int> reactionTimes;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Round History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(reactionTimes.length, (i) {
            final ms = reactionTimes[i];
            final isPenalty = ms >= 1500;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    'R${i + 1}',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (ms / 1500).clamp(0.05, 1.0),
                      backgroundColor: Colors.grey.shade100,
                      color: isPenalty ? Colors.orange : accentColor,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isPenalty ? 'Early!' : '${ms}ms',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isPenalty ? Colors.orange : accentColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
