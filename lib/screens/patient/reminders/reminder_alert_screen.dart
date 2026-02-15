import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/reminder.dart';
import '../../../../providers/service_providers.dart';
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // We'll track playing state locally using the stream from service
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initAudio();
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
    // Post frame to access ref safely if needed, though initState can read.
    // Better to do logic here.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reminder = _getReminder();
      if (reminder == null) return;

      final audioService = ref.read(voicePlaybackServiceProvider);

      // Listen to player state
      audioService.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      // Determine what to play
      try {
        if (reminder.localAudioPath != null) {
          await audioService.playLocalAudio(reminder.localAudioPath!);
        } else if (reminder.voiceAudioUrl != null) {
          await audioService.playRemoteAudio(reminder.voiceAudioUrl!);
        } else {
          // Play default gentle tone
          // Make sure asset exists or handle error
          try {
            await audioService.playAsset('assets/sounds/gentle_tone.mp3');
          } catch (e) {
            debugPrint('Asset gentle_tone.mp3 not found, skipping tone.');
          }
        }
      } catch (e) {
        debugPrint('Error starting audio: $e');
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Stop audio when leaving screen
    ref.read(voicePlaybackServiceProvider).stop();
    super.dispose();
  }

  Reminder? _getReminder() {
    final reminderState = ref.read(reminderViewModelProvider);
    try {
      return reminderState.reminders
          .firstWhere((r) => r.id == widget.reminderId);
    } catch (_) {
      return null;
    }
  }

  void _onDone() {
    ref.read(voicePlaybackServiceProvider).stop();
    ref.read(reminderViewModelProvider.notifier).markAsDone(widget.reminderId);
    Navigator.pop(context); // Close alert
  }

  void _onSnooze(int minutes) {
    ref.read(voicePlaybackServiceProvider).stop();

    final reminder = _getReminder();
    if (reminder == null) {
      Navigator.pop(context);
      return;
    }

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
    // Watch for changes (e.g. if reminder gets deleted externally)
    final reminderState = ref.watch(reminderViewModelProvider);
    Reminder reminder;
    try {
      reminder = reminderState.reminders.firstWhere(
        (r) => r.id == widget.reminderId,
      );
    } catch (_) {
      return const Scaffold(body: Center(child: Text('Reminder not found')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Icon with Pulse
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

            // Time Message
            Text(
              "It's time for your ${reminder.type == ReminderType.medication ? 'medicine' : 'task'}.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('h:mm a').format(reminder.remindAt),
              style: TextStyle(
                fontSize: 20,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
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

            // Replay Voice Button
            if (reminder.hasVoiceNote)
              TextButton.icon(
                onPressed: () {
                  ref.read(voicePlaybackServiceProvider).replay();
                },
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 48, color: Colors.teal),
                label: Text(_isPlaying ? 'Playing...' : 'Replay Voice Note',
                    style: const TextStyle(fontSize: 20)),
              ),

            const SizedBox(height: 32),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // Mark as Done - BIG button (min 56px height)
                  SizedBox(
                    width: double.infinity,
                    height: 80,
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
                      icon: const Icon(Icons.check_circle, size: 40),
                      label: const Text(
                        'Mark as Done',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Snooze
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: OutlinedButton.icon(
                      onPressed: () => _onSnooze(10), // Snooze 10m
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide(color: Colors.grey.shade400, width: 2),
                      ),
                      icon: const Icon(Icons.snooze, size: 32),
                      label: const Text(
                        'Snooze 10 min',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
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
