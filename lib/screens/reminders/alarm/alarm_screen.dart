// lib/features/patient/presentation/screens/alarm/alarm_screen.dart

import 'package:memocare/core/utils/vibrate.dart';
import 'package:memocare/data/models/reminder.dart';
import 'package:memocare/providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../../features/patient/presentation/screens/home/viewmodels/home_viewmodel.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  final String reminderId;
  const AlarmScreen({super.key, required this.reminderId});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _startAlarm();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.1).animate(_pulseController);
  }

  Future<void> _startAlarm() async {
    // ── Audio ────────────────────────────────────────────────────────────────
    try {
      // Loop the audio continuously
      await _audioPlayer.setAsset('assets/sounds/gentle_tone.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
      _audioPlayer.play();
    } catch (e) {
      debugPrint('[AlarmScreen] audio error: $e');
    }

    // ── Vibration — uses VibrationHelper, no raw Vibration calls ─────────────
    // Pattern: 0 ms pause → 600 ms vibrate → 400 ms pause → 600 ms vibrate
    await VibrationHelper.startRepeating(
      pattern: const [0, 600, 400, 600],
    );
  }

  Future<void> _stopAlarm() async {
    await _audioPlayer.stop();
    await VibrationHelper.cancel();
  }

  @override
  void dispose() {
    _stopAlarm();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Reminder? _getReminder() {
    final state = ref.read(homeViewModelProvider);
    try {
      return state.reminders.firstWhere((r) => r.id == widget.reminderId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onConfirm() async {
    await _stopAlarm();
    final repo = ref.read(reminderRepositoryProvider);
    await repo.markReminderCompleted(widget.reminderId);
    ref.read(homeViewModelProvider.notifier).toggleReminder(widget.reminderId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _onSnooze(int minutes) async {
    await _stopAlarm();
    final reminder = _getReminder();
    if (reminder == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final updated = reminder.copyWith(
      reminderTime: DateTime.now().add(Duration(minutes: minutes)),
      isSnoozed: true,
      snoozeDurationMinutes: minutes,
      lastSnoozedAt: DateTime.now(),
    );

    final repo = ref.read(reminderRepositoryProvider);
    await repo.updateReminder(updated);
    ref.read(homeViewModelProvider.notifier).updateReminder(updated);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);

    Reminder reminder;
    try {
      reminder =
          homeState.reminders.firstWhere((r) => r.id == widget.reminderId);
    } catch (_) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Reminder not found',
              style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Pulsing icon
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _iconForType(reminder.type),
                  size: 100,
                  color: Colors.red.shade900,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                reminder.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Type label
            Text(
              'TIME FOR ${reminder.type.name.toUpperCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: Colors.red.shade100,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 16),

            // Time
            Text(
              DateFormat('h:mm a').format(reminder.reminderTime),
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // ── Confirm ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: ElevatedButton.icon(
                      onPressed: _onConfirm,
                      icon: const Icon(Icons.check_circle, size: 40),
                      label: const Text(
                        'CONFIRM',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade900,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Snooze ───────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: OutlinedButton.icon(
                      onPressed: () => _onSnooze(10),
                      icon: const Icon(Icons.snooze, size: 32),
                      label: const Text(
                        'SNOOZE (10 MIN)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
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

  IconData _iconForType(ReminderType type) {
    switch (type) {
      case ReminderType.medication:
        return Icons.medication;
      case ReminderType.appointment:
        return Icons.calendar_today;
      case ReminderType.task:
        return Icons.task_alt;
    }
  }
}
