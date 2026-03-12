import 'dart:async';

import 'package:memocare/providers/game_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../../providers/game_providers.dart';

enum ShapeType { circle, square, triangle, star }

enum ShapeColor { red, blue, green, purple }

class ShapeItem {
  final int id;
  final ShapeType type;
  final ShapeColor color;
  bool isMatched;

  ShapeItem({
    required this.id,
    required this.type,
    required this.color,
    this.isMatched = false,
  });
}

class ShapeSorterGame extends ConsumerStatefulWidget {
  final String patientId;
  final VoidCallback onExit;

  const ShapeSorterGame({
    super.key,
    required this.patientId,
    required this.onExit,
  });

  @override
  ConsumerState<ShapeSorterGame> createState() => _ShapeSorterGameState();
}

class _ShapeSorterGameState extends ConsumerState<ShapeSorterGame> {
  final List<ShapeItem> _shapes = [];
  final List<ShapeType> _baskets = [
    ShapeType.circle,
    ShapeType.square,
    ShapeType.triangle,
    ShapeType.star
  ];

  int _score = 0;
  int _matchedCount = 0;
  int _moves = 0;
  late Stopwatch _stopwatch;
  Timer? _timer;
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
    _matchedCount = 0;
    _moves = 0;
    _isSaving = false;
    _shapes.clear();

    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Generate 8 shapes (2 of each type, randomized colors)
    final colors = ShapeColor.values;
    int idCounter = 0;

    for (var type in _baskets) {
      _shapes.add(ShapeItem(
          id: idCounter++,
          type: type,
          color: (colors.toList()..shuffle()).first));
      _shapes.add(ShapeItem(
          id: idCounter++,
          type: type,
          color: (colors.toList()..shuffle()).first));
    }

    _shapes.shuffle();
  }

  Color _getColor(ShapeColor color) {
    switch (color) {
      case ShapeColor.red:
        return Colors.red.shade400;
      case ShapeColor.blue:
        return Colors.blue.shade400;
      case ShapeColor.green:
        return Colors.green.shade400;
      case ShapeColor.purple:
        return Colors.purple.shade400;
    }
  }

  IconData _getIconData(ShapeType type) {
    switch (type) {
      case ShapeType.circle:
        return Icons.circle;
      case ShapeType.square:
        return Icons
            .crop_square_sharp; // Using crop_square visually acts as a filled square depending on rendering, but square is standard
      case ShapeType.triangle:
        return Icons.change_history;
      case ShapeType.star:
        return Icons.star;
    }
  }

  Widget _buildShapeWidget(ShapeType type, Color color, double size) {
    IconData iconData = _getIconData(type);

    // Custom fallbacks for filled vs outlined since Material icons can be tricky for basic filled geometry
    if (type == ShapeType.square) {
      return Container(
        width: size * 0.8,
        height: size * 0.8,
        color: color,
      );
    } else if (type == ShapeType.triangle) {
      // Temporary simpler stand-in for triangle: using icon
      return Icon(Icons.warning, size: size, color: color);
    }

    return Icon(iconData, size: size, color: color);
  }

  void _handleDrop(ShapeItem droppedShape, ShapeType targetBasket) {
    if (droppedShape.isMatched) return;

    setState(() {
      _moves++;
      if (droppedShape.type == targetBasket) {
        droppedShape.isMatched = true;
        _score += 100;
        _matchedCount++;

        if (_matchedCount == _shapes.length) {
          _gameComplete();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not quite. Try another basket!'),
            duration: Duration(milliseconds: 1000),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  Future<void> _gameComplete() async {
    if (_isSaving) return;
    _isSaving = true;
    _stopwatch.stop();
    _timer?.cancel();

    try {
      if (kDebugMode) {
        print('--- SHAPE SORTER GAME COMPLETE ---');
      }

      await ref.read(gameRepositoryProvider).recordCompletedGame(
            gameId: 'shape_sorter',
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
            Text('Perfect Sorting!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You sorted all the shapes correctly.',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Score', _score.toString(), Colors.green),
            _buildStatRow('Moves', _moves.toString(), Colors.blue),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Shape Sorter'),
        backgroundColor: Colors.green.shade600,
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
                    'Moves', '$_moves', Icons.touch_app, Colors.blue),
                _buildStatChip(
                    'Time',
                    '${_stopwatch.elapsed.inMinutes}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                    Icons.timer,
                    Colors.orange),
                _buildStatChip('Sorted', '$_matchedCount/${_shapes.length}',
                    Icons.check_circle, Colors.green),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Baskets (Drag Targets)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _baskets.map((basketType) {
                      return DragTarget<ShapeItem>(
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                                color: candidateData.isNotEmpty
                                    ? Colors.green.shade100
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: candidateData.isNotEmpty
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]),
                            child: Center(
                              child: Opacity(
                                opacity: 0.3,
                                child: _buildShapeWidget(
                                    basketType, Colors.grey.shade600, 40),
                              ),
                            ),
                          );
                        },
                        onAcceptWithDetails: (details) {
                          _handleDrop(details.data, basketType);
                        },
                      );
                    }).toList(),
                  ),

                  const Spacer(),

                  // Unsorted Shapes
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _shapes.map((shape) {
                      if (shape.isMatched) {
                        return const SizedBox(
                            width: 70,
                            height: 70); // Placeholder to maintain layout
                      }

                      return Draggable<ShapeItem>(
                        data: shape,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _buildShapeWidget(
                              shape.type, _getColor(shape.color), 80),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _buildShapeWidget(
                              shape.type, _getColor(shape.color), 70),
                        ),
                        child: _buildShapeWidget(
                            shape.type, _getColor(shape.color), 70),
                      );
                    }).toList(),
                  ),

                  const Spacer(),
                ],
              ),
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
}
