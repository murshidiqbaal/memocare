import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/emotional_theme_extension.dart';
import '../../../providers/game_providers.dart';
import 'mini_games/shape_sorter_game.dart';
import 'mini_games/word_puzzle_game.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  String? _selectedGame;

  @override
  Widget build(BuildContext context) {
    final patientId = Supabase.instance.client.auth.currentUser?.id;
    final emotionalTheme =
        Theme.of(context).extension<EmotionalThemeExtension>()!;

    if (patientId == null) {
      return Scaffold(
        backgroundColor: emotionalTheme.background,
        appBar: AppBar(
          title: const Text('Brain Games'),
          backgroundColor: emotionalTheme.background,
          elevation: 0,
          foregroundColor: emotionalTheme.textPrimary,
        ),
        body: const Center(child: Text('Please log in to play games')),
      );
    }

    // If a game is selected, show the game screen
    if (_selectedGame == 'memory_match') {
      return MemoryMatchGame(
        patientId: patientId,
        onExit: () => setState(() => _selectedGame = null),
      );
    } else if (_selectedGame == 'word_puzzle') {
      return WordPuzzleGame(
        patientId: patientId,
        onExit: () => setState(() => _selectedGame = null),
      );
    } else if (_selectedGame == 'shape_sorter') {
      return ShapeSorterGame(
        patientId: patientId,
        onExit: () => setState(() => _selectedGame = null),
      );
    }

    // Otherwise show game selection menu
    return Scaffold(
      backgroundColor: emotionalTheme.background,
      appBar: AppBar(
        title: const Text('Brain Games'),
        backgroundColor: emotionalTheme.background,
        elevation: 0,
        foregroundColor: emotionalTheme.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGameCard(
            context,
            title: 'Memory Match',
            description: 'Match pairs of cards to improve memory',
            icon: Icons.grid_on,
            color: emotionalTheme.primary!,
            onTap: () => setState(() => _selectedGame = 'memory_match'),
          ),
          _buildGameCard(
            context,
            title: 'Word Puzzle',
            description: 'Find words to keep your mind sharp',
            icon: Icons.text_fields,
            color: Colors.orange,
            onTap: () => setState(() => _selectedGame = 'word_puzzle'),
          ),
          _buildGameCard(
            context,
            title: 'Shape Sorter',
            description: 'Sort shapes by color and type',
            icon: Icons.category,
            color: Colors.green,
            onTap: () => setState(() => _selectedGame = 'shape_sorter'),
          ),

          // // ─── Divider ───────────────────────────────────────────────────
          // const Padding(
          //   padding: EdgeInsets.symmetric(vertical: 8),
          //   child: Row(
          //     children: [
          //       Expanded(child: Divider()),
          //       Padding(
          //         padding: EdgeInsets.symmetric(horizontal: 12),
          //         child: Text(
          //           'NEW GAMES',
          //           style: TextStyle(
          //             fontSize: 11,
          //             fontWeight: FontWeight.bold,
          //             color: Colors.grey,
          //             letterSpacing: 1.2,
          //           ),
          //         ),
          //       ),
          //       Expanded(child: Divider()),
          //     ],
          //   ),
          // ),

          // // 🃏 Memory Match — standalone route
          // _buildGameCard(
          //   context,
          //   title: 'Memory Match',
          //   description: 'Flip cards and find matching pairs',
          //   icon: Icons.grid_view_rounded,
          //   color: const Color(0xFF7C3AED),
          //   badge: 'New',
          //   onTap: () => context.push('/games/memory-match'),
          // ),

          // ⚡ Reaction Tap — standalone route
          _buildGameCard(
            context,
            title: 'Reaction Tap',
            description: 'Tap as fast as you can when the button turns green',
            icon: Icons.flash_on_rounded,
            color: const Color(0xFF0EA5E9),
            badge: 'New',
            onTap: () => context.push('/games/reaction-tap'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    final emotionalTheme =
        Theme.of(context).extension<EmotionalThemeExtension>()!;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: emotionalTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Memory Match Game Implementation =====

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

class _MemoryMatchGameState extends ConsumerState<MemoryMatchGame> {
  static const int gridSize = 4; // 4x4 grid = 16 cards = 8 pairs
  static const List<IconData> icons = [
    Icons.favorite,
    Icons.star,
    Icons.pets,
    Icons.local_florist,
    Icons.wb_sunny,
    Icons.music_note,
    Icons.sports_soccer,
    Icons.cake,
  ];

  List<GameCard> cards = [];
  int? firstCardIndex;
  int? secondCardIndex;
  int matchedPairs = 0;
  int moves = 0;
  late Stopwatch stopwatch;
  Timer? timer;
  bool _gameFinished = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    _gameFinished = false;
    stopwatch = Stopwatch()..start();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Create pairs of cards
    final List<GameCard> tempCards = [];
    for (int i = 0; i < icons.length; i++) {
      tempCards.add(GameCard(id: i * 2, icon: icons[i]));
      tempCards.add(GameCard(id: i * 2 + 1, icon: icons[i]));
    }

    // Shuffle
    tempCards.shuffle(Random());
    cards = tempCards;
    firstCardIndex = null;
    secondCardIndex = null;
    matchedPairs = 0;
    moves = 0;
  }

  void _onCardTap(int index) {
    if (cards[index].isMatched || cards[index].isFaceUp) return;
    if (firstCardIndex != null && secondCardIndex != null) return;

    setState(() {
      cards[index].isFaceUp = true;

      if (firstCardIndex == null) {
        firstCardIndex = index;
      } else if (secondCardIndex == null) {
        secondCardIndex = index;
        moves++;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    if (firstCardIndex == null || secondCardIndex == null) return;

    final first = cards[firstCardIndex!];
    final second = cards[secondCardIndex!];

    if (first.icon == second.icon) {
      // Match found
      setState(() {
        cards[firstCardIndex!].isMatched = true;
        cards[secondCardIndex!].isMatched = true;
        matchedPairs++;
        firstCardIndex = null;
        secondCardIndex = null;
      });

      // Check if game is complete
      if (matchedPairs == icons.length) {
        _gameComplete();
      }
    } else {
      // No match - flip back after delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            cards[firstCardIndex!].isFaceUp = false;
            cards[secondCardIndex!].isFaceUp = false;
            firstCardIndex = null;
            secondCardIndex = null;
          });
        }
      });
    }
  }

  // Save game session
  Future<void> _gameComplete() async {
    if (_gameFinished) return;
    _gameFinished = true;
    stopwatch.stop();
    timer?.cancel();

    final score =
        max(0, 1000 - (moves * 10) - (stopwatch.elapsed.inSeconds * 2));

    try {
      if (kDebugMode) {
        print('--- MEMORY MATCH GAME TICK ---');
        print('Using auth.uid() automatically in repository.');
      }

      await ref.read(gameRepositoryProvider).recordCompletedGame(
            gameId: 'memory_match',
            score: score,
            durationSeconds: stopwatch.elapsed.inSeconds,
            attempts: moves,
          );

      if (mounted) {
        _showCompletionDialog(score);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save game session: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _gameFinished = false; // Allow retrying if desired.
      }
    }
  }

  void _showCompletionDialog(int score) {
    final emotionalTheme =
        Theme.of(context).extension<EmotionalThemeExtension>()!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
              'You completed the game!',
              style:
                  TextStyle(fontSize: 18, color: emotionalTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Score', score.toString(), emotionalTheme.primary!),
            _buildStatRow('Moves', moves.toString(), Colors.blue),
            _buildStatRow(
              'Time',
              '${stopwatch.elapsed.inMinutes}:${(stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
              Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onExit();
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initializeGame();
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: emotionalTheme.primary),
            child:
                const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emotionalTheme =
        Theme.of(context).extension<EmotionalThemeExtension>()!;
    return Scaffold(
      backgroundColor: emotionalTheme.background,
      appBar: AppBar(
        title: const Text('Memory Match'),
        backgroundColor: emotionalTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onExit,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializeGame();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.all(16),
            color: emotionalTheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                    emotionalTheme, 'Moves', moves.toString(), Icons.touch_app),
                _buildStatChip(
                  emotionalTheme,
                  'Time',
                  '${stopwatch.elapsed.inMinutes}:${(stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                  Icons.timer,
                ),
                _buildStatChip(
                  emotionalTheme,
                  'Pairs',
                  '$matchedPairs/${icons.length}',
                  Icons.check_circle,
                ),
              ],
            ),
          ),
          // Game grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return _buildCard(cards[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(EmotionalThemeExtension emotionalTheme, String label,
      String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: emotionalTheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: emotionalTheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: emotionalTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCard(GameCard card, int index) {
    final emotionalTheme =
        Theme.of(context).extension<EmotionalThemeExtension>()!;
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isFaceUp || card.isMatched
              ? Colors.white
              : emotionalTheme.primary?.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: card.isFaceUp || card.isMatched
            ? Icon(
                card.icon,
                size: 40,
                color: card.isMatched
                    ? emotionalTheme.success
                    : emotionalTheme.primary,
              )
            : const Icon(
                Icons.question_mark,
                size: 40,
                color: Colors.white,
              ),
      ),
    );
  }
}

// ===== Game Card Model =====

class GameCard {
  final int id;
  final IconData icon;
  bool isFaceUp;
  bool isMatched;

  GameCard({
    required this.id,
    required this.icon,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}
