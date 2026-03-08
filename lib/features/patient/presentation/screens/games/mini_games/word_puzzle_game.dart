import 'dart:async';
import 'dart:math';

import 'package:dementia_care_app/providers/game_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../../providers/game_providers.dart';

class WordPuzzleGame extends ConsumerStatefulWidget {
  final String patientId;
  final VoidCallback onExit;

  const WordPuzzleGame({
    super.key,
    required this.patientId,
    required this.onExit,
  });

  @override
  ConsumerState<WordPuzzleGame> createState() => _WordPuzzleGameState();
}

class _WordPuzzleGameState extends ConsumerState<WordPuzzleGame> {
  static const List<String> _words = [
    'CAT',
    'DOG',
    'SUN',
    'BIRD',
    'TREE',
    'BOOK',
    'HOME',
    'LOVE',
    'STAR',
    'FISH'
  ];

  String? _currentWord = '';
  List<String> _letters = [];
  List<String> _selectedLetters = [];

  int _score = 0;
  int _roundsCompleted = 0;
  int _moves = 0;
  late Stopwatch _stopwatch;
  Timer? _timer;

  bool _isSuccessAnim = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _score = 0;
    _roundsCompleted = 0;
    _moves = 0;
    _isSaving = false;
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    _loadNextWord();
  }

  void _loadNextWord() {
    final random = Random();
    String nextWord;
    do {
      nextWord = _words[random.nextInt(_words.length)];
    } while (nextWord == _currentWord && _words.length > 1);

    _currentWord = nextWord;

    // Create jumbled letters
    _letters = _currentWord!.split('')..shuffle(random);
    _selectedLetters = [];
    _isSuccessAnim = false;
  }

  void _onLetterTap(String letter, int index) {
    if (_isSuccessAnim || _selectedLetters.length >= _currentWord!.length) {
      return;
    }

    setState(() {
      _selectedLetters.add(letter);
      _letters[index] = ''; // blank out the tapped letter visually
      _moves++;
    });

    if (_selectedLetters.length == _currentWord!.length) {
      _checkWord();
    }
  }

  void _onUndo() {
    if (_isSuccessAnim || _selectedLetters.isEmpty) return;

    setState(() {
      final lastLetter = _selectedLetters.removeLast();
      // Put the letter back in the first empty spot it came from
      final emptyIndex = _letters.indexOf('');
      if (emptyIndex != -1) {
        _letters[emptyIndex] = lastLetter;
      }
    });
  }

  void _checkWord() {
    final formedWord = _selectedLetters.join('');

    if (formedWord == _currentWord) {
      // Success
      setState(() {
        _isSuccessAnim = true;
        _score += 100;
        _roundsCompleted++;
      });

      if (_roundsCompleted >= 5) {
        // 5 rounds per session
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _finishGame();
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _loadNextWord());
        });
      }
    } else {
      // Incorrect - auto undo after short delay
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _letters = _letters
              .map((l) => l == '' ? _selectedLetters.removeAt(0) : l)
              .toList();
          _letters.shuffle();
          _selectedLetters.clear();
        });
      });
    }
  }

  Future<void> _finishGame() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    _stopwatch.stop();
    _timer?.cancel();

    try {
      if (kDebugMode) {
        print('--- WORD PUZZLE GAME COMPLETE ---');
      }

      await ref.read(gameRepositoryProvider).recordCompletedGame(
            gameId: 'word_puzzle',
            score: _score,
            durationSeconds: _stopwatch.elapsed.inSeconds,
            attempts: _moves,
          );

      if (mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save game session: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Text('Amazing Job!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You found all the words!',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Score', _score.toString(), Colors.orange),
            _buildStatRow(
                'Words Finished', _roundsCompleted.toString(), Colors.blue),
            _buildStatRow(
              'Time',
              '${_stopwatch.elapsed.inMinutes}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
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
            child: const Text('Exit', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _startNewGame());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Play Again', style: TextStyle(fontSize: 16)),
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
                  fontSize: 16, fontWeight: FontWeight.bold, color: color),
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
        title: const Text('Word Puzzle'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onExit,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (!_isSaving) {
                setState(() => _startNewGame());
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                    'Round', '$_roundsCompleted/5', Icons.loop, Colors.orange),
                _buildStatChip(
                    'Time',
                    '${_stopwatch.elapsed.inMinutes}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                    Icons.timer,
                    Colors.blue),
                _buildStatChip('Score', '$_score', Icons.star, Colors.green),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Image / Prompt Area (Visual Cue)
          if (_isSuccessAnim)
            const Icon(Icons.check_circle, size: 80, color: Colors.green)
          else
            Icon(Icons.question_mark_rounded,
                size: 80, color: Colors.orange.shade200),

          const SizedBox(height: 32),

          // Drop zone (Building the word)
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_currentWord!.length, (index) {
                final hasLetter = index < _selectedLetters.length;
                final letter = hasLetter ? _selectedLetters[index] : '';
                return _buildTile(letter,
                    isFilled: hasLetter, isSuccess: _isSuccessAnim);
              }),
            ),
          ),

          const SizedBox(height: 16),

          if (_selectedLetters.isNotEmpty && !_isSuccessAnim)
            TextButton.icon(
              onPressed: _onUndo,
              icon: const Icon(Icons.undo, color: Colors.orange),
              label: const Text('Undo',
                  style: TextStyle(color: Colors.orange, fontSize: 18)),
            ),

          const Spacer(flex: 1),

          // Pick zone (Available letters)
          Container(
            padding: const EdgeInsets.all(50),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ]),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: List.generate(_letters.length, (index) {
                final letter = _letters[index];
                if (letter.isEmpty) {
                  return const SizedBox(
                      width: 70, height: 70); // Empty space marker
                }
                return GestureDetector(
                  onTap: () => _onLetterTap(letter, index),
                  child: _buildTile(letter, isSelectable: true),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTile(String letter,
      {bool isFilled = false,
      bool isSelectable = false,
      bool isSuccess = false}) {
    Color bgColor = Colors.white;
    Color textColor = Colors.orange;
    Color borderColor = Colors.orange.shade200;

    if (isSuccess) {
      bgColor = Colors.green;
      textColor = Colors.white;
      borderColor = Colors.green.shade700;
    } else if (isSelectable) {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade300;
    } else if (isFilled) {
      bgColor = Colors.orange;
      textColor = Colors.white;
      borderColor = Colors.orange.shade700;
    }

    return Container(
      width: 70,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isSelectable || isFilled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
