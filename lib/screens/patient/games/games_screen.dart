import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/game_session.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/game_providers.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  String? _selectedGame;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final patientId = user?.id;

    if (patientId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Brain Games'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
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
    }

    // Otherwise show game selection menu
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Brain Games'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGameCard(
            context,
            title: 'Memory Match',
            description: 'Match pairs of cards to improve memory',
            icon: Icons.grid_on,
            color: Colors.purple,
            onTap: () => setState(() => _selectedGame = 'memory_match'),
          ),
          _buildGameCard(
            context,
            title: 'Word Puzzle',
            description: 'Find words to keep your mind sharp',
            icon: Icons.text_fields,
            color: Colors.orange,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon!')),
              );
            },
          ),
          _buildGameCard(
            context,
            title: 'Shape Sorter',
            description: 'Sort shapes by color and type',
            icon: Icons.category,
            color: Colors.green,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon!')),
              );
            },
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
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _gameComplete() {
    stopwatch.stop();
    timer?.cancel();

    // Calculate score (higher is better)
    // Score = 1000 - (moves * 10) - (seconds * 2)
    final score =
        max(0, 1000 - (moves * 10) - (stopwatch.elapsed.inSeconds * 2));

    // Save game session
    final session = GameSession(
      id: const Uuid().v4(),
      patientId: widget.patientId,
      gameType: 'memory_match',
      score: score,
      durationSeconds: stopwatch.elapsed.inSeconds,
      completedAt: DateTime.now(),
      createdAt: DateTime.now(),
      isSynced: false,
    );

    ref
        .read(gameSessionsProvider(widget.patientId).notifier)
        .saveSession(session);

    // Show completion dialog
    _showCompletionDialog(score);
  }

  void _showCompletionDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Text('Congratulations!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You completed the game!',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Score', score.toString(), Colors.purple),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Play Again'),
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
              color: color.withOpacity(0.2),
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Memory Match'),
        backgroundColor: Colors.purple,
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
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Moves', moves.toString(), Icons.touch_app),
                _buildStatChip(
                  'Time',
                  '${stopwatch.elapsed.inMinutes}:${(stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                  Icons.timer,
                ),
                _buildStatChip(
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

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildCard(GameCard card, int index) {
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isFaceUp || card.isMatched
              ? Colors.white
              : Colors.purple.shade400,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: card.isFaceUp || card.isMatched
            ? Icon(
                card.icon,
                size: 40,
                color: card.isMatched ? Colors.green : Colors.purple,
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
