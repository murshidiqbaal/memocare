import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:memocare/data/models/reminder.dart';
import '../home/viewmodels/home_viewmodel.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  final String reminderId;

  const AlarmScreen({super.key, required this.reminderId});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAnimation();
    _startAlarm();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startAlarm() async {
    try {
      // Loop the alarm sound - using the raw resource name for Android or asset path
      await _audioPlayer.setAsset('assets/sounds/alarm.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
      _audioPlayer.play();

      // Repeat vibration
      _vibrationTimer =
          Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
        }
      });
    } catch (e) {
      debugPrint('Error playing alarm: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseController.dispose();
    _vibrationTimer?.cancel();
    Vibration.cancel();
    super.dispose();
  }

  void _onConfirm() {
    ref.read(homeViewModelProvider.notifier).toggleReminder(widget.reminderId);
    Navigator.of(context).pop();
  }

  void _onSnooze() {
    final homeState = ref.read(homeViewModelProvider);
    final reminder =
        homeState.reminders.firstWhere((r) => r.id == widget.reminderId);

    final updated = reminder.copyWith(
      reminderTime: DateTime.now().add(const Duration(minutes: 10)),
      isSnoozed: true,
      snoozeDurationMinutes: 10,
      lastSnoozedAt: DateTime.now(),
    );

    ref.read(homeViewModelProvider.notifier).updateReminder(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    Reminder? reminder;
    try {
      reminder =
          homeState.reminders.firstWhere((r) => r.id == widget.reminderId);
    } catch (_) {
      // Fallback if reminder not found
    }

    if (reminder == null) {
      return const Scaffold(body: Center(child: Text('Reminder not found')));
    }

    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'MEDICINE REMINDER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Icon(
                    Icons.medication,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                reminder.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                DateFormat('h:mm a').format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                ),
              ),
              const Spacer(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: ElevatedButton(
                        onPressed: _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: const Text(
                          'CONFIRM',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: _onSnooze,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side:
                              const BorderSide(color: Colors.white54, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'SNOOZE 10 MIN',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
