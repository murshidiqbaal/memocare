import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../data/models/reminder.dart';
import 'viewmodels/reminder_viewmodel.dart';

class ReminderAlertScreen extends ConsumerStatefulWidget {
  final String reminderId;

  const ReminderAlertScreen({super.key, required this.reminderId});

  @override
  ConsumerState<ReminderAlertScreen> createState() =>
      _ReminderAlertScreenState();
}

class _ReminderAlertScreenState extends ConsumerState<ReminderAlertScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _initAnimation();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.1).animate(_pulseController);
  }

  Future<void> _initAudio() async {
    _player = AudioPlayer();

    // Auto-play logic
    // We need to fetch reminder details first.
    // However, build() hasn't run yet so we can't watch provider easily here?
    // We can read it.

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reminder = ref
          .read(reminderViewModelProvider)
          .reminders
          .firstWhere((r) => r.id == widget.reminderId,
              orElse: () => Reminder(
                    id: 'error',
                    patientId: 'error',
                    title: 'Error',
                    type: ReminderType.task,
                    remindAt: DateTime.now(),
                    createdAt: DateTime.now(),
                  ));

      if (reminder.id == 'error') return;

      try {
        if (reminder.voiceAudioUrl != null || reminder.localAudioPath != null) {
          // Play Voice
          if (reminder.localAudioPath != null) {
            await _player.setFilePath(reminder.localAudioPath!);
          } else if (reminder.voiceAudioUrl != null) {
            await _player.setUrl(reminder.voiceAudioUrl!);
          }
        } else {
          // Play Gentle Tone
          // Assuming asset exists as per requirement
          try {
            await _player.setAsset('assets/sounds/gentle_tone.mp3');
          } catch (e) {
            debugPrint('Asset gentle_tone.mp3 not found, skipping tone.');
          }
        }
        await _player.play();
        if (mounted) setState(() => _isPlaying = true);

        _player.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
            });
          }
        });
      } catch (e) {
        debugPrint('Audio playback error: $e');
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _stopAudio() async {
    await _player.stop();
  }

  void _onDone() {
    _stopAudio();
    ref.read(reminderViewModelProvider.notifier).markAsDone(widget.reminderId);
    Navigator.pop(context); // Close alert
  }

  void _onSnooze(int minutes) {
    _stopAudio();
    final reminder = ref
        .read(reminderViewModelProvider)
        .reminders
        .firstWhere((r) => r.id == widget.reminderId);

    final updated = reminder.copyWith(
      remindAt: DateTime.now().add(Duration(minutes: minutes)),
      isSnoozed: true,
      snoozeDurationMinutes: minutes,
      lastSnoozedAt: DateTime.now(),
    );

    ref.read(reminderViewModelProvider.notifier).updateReminder(updated);
    Navigator.pop(context); // Close alert
  }

  @override
  Widget build(BuildContext context) {
    final reminderState = ref.watch(reminderViewModelProvider);
    final reminder = reminderState.reminders.firstWhere(
      (r) => r.id == widget.reminderId,
      orElse: () => Reminder(
        id: 'error',
        patientId: 'error',
        title: 'Reminder Error',
        type: ReminderType.task,
        remindAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    if (reminder.id == 'error') {
      return const Scaffold(body: Center(child: Text('Reminder not found')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Icon
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.teal.shade100, width: 2),
                ),
                child: Icon(
                  _getIcon(reminder.type),
                  size: 80,
                  color: Colors.teal,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                reminder.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time
            Text(
              DateFormat('h:mm a').format(reminder.remindAt),
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (reminder.description != null &&
                reminder.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  reminder.description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
              ),

            const Spacer(),

            // Replay Audio Button
            if (reminder.voiceAudioUrl != null ||
                reminder.localAudioPath != null)
              TextButton.icon(
                onPressed: () async {
                  await _player.seek(Duration.zero);
                  await _player.play();
                },
                icon: const Icon(Icons.replay, size: 32),
                label: const Text('Replay Voice Note',
                    style: TextStyle(fontSize: 18)),
              ),

            const SizedBox(height: 32),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // Mark as Done - BIG button
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: ElevatedButton.icon(
                      onPressed: _onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 8,
                      ),
                      icon: const Icon(Icons.check_circle, size: 36),
                      label: const Text(
                        'Mark as Done',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Snooze
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton.icon(
                      onPressed: () => _onSnooze(10), // Snooze 10m
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide(color: Colors.grey.shade400, width: 2),
                      ),
                      icon: const Icon(Icons.snooze, size: 28),
                      label: const Text(
                        'Snooze 10 min',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
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

  IconData _getIcon(ReminderType type) {
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
