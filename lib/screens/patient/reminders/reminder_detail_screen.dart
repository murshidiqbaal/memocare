import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart'; // Strict playback requirement

import '../../../../data/models/reminder.dart';
import '../home/viewmodels/home_viewmodel.dart';

class ReminderDetailScreen extends ConsumerStatefulWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  ConsumerState<ReminderDetailScreen> createState() =>
      _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends ConsumerState<ReminderDetailScreen> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _player.seek(Duration.zero);
            _player.pause();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String? url, String? localPath) async {
    if ((url == null || url.isEmpty) &&
        (localPath == null || localPath.isEmpty)) {
      return;
    }

    try {
      setState(() => _isLoadingAudio = true);
      if (localPath != null && localPath.isNotEmpty) {
        await _player.setFilePath(localPath);
      } else if (url != null) {
        await _player.setUrl(url);
      }
      await _player.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play audio: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  Future<void> _stopAudio() async {
    await _player.stop();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Single Source of Truth
    final homeState = ref.watch(homeViewModelProvider);

    // Find reminder in the global list
    final reminder = homeState.reminders.firstWhere(
      (r) => r.id == widget.reminderId,
      orElse: () => Reminder(
        id: 'error',
        caregiverId: '', patientId: 'error',
        title: 'Reminder Not Found',
        type: ReminderType.task,
        reminderTime: DateTime.now(),
        createdAt: DateTime.now(),
      ), // Fallback
    );

    if (reminder.id == 'error') {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Reminder not found')),
      );
    }

    final isDone = reminder.status == ReminderStatus.completed;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reminder Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDone ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isDone ? 'COMPLETED' : 'PENDING',
                style: TextStyle(
                  color: isDone ? Colors.green.shade800 : Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              reminder.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Time & Repeat
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  DateFormat('h:mm a  •  EEEE, d MMM')
                      .format(reminder.reminderTime),
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.repeat, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Repeats: ${reminder.repeatRule.name.toUpperCase()}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            if (reminder.description != null &&
                reminder.description!.isNotEmpty) ...[
              const Text(
                'NOTES',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                reminder.description!,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],

            // Voice Note
            if (reminder.voiceAudioUrl != null ||
                reminder.localAudioPath != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.record_voice_over,
                          color: Colors.teal),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caregiver Voice Note',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                              fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text('Tap to listen',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Spacer(),
                    if (_isLoadingAudio)
                      const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      IconButton(
                        onPressed: () {
                          if (_isPlaying) {
                            _stopAudio();
                          } else {
                            _playAudio(reminder.voiceAudioUrl,
                                reminder.localAudioPath);
                          }
                        },
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 48,
                          color: Colors.teal,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Actions
            if (!isDone)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Use toggleReminder to mark done
                    ref
                        .read(homeViewModelProvider.notifier)
                        .toggleReminder(reminder.id);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text(
                    'Mark as Done',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (!isDone) const SizedBox(height: 16),

            // Snooze
            if (!isDone)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Snooze Logic - just 10 mins for now as requested in minimal scope
                    // Update reminderTime to now + 10 mins
                    // Call updateReminder
                    final updated = reminder.copyWith(
                      reminderTime: DateTime.now().add(const Duration(minutes: 10)),
                      isSnoozed: true,
                      snoozeDurationMinutes: 10,
                      lastSnoozedAt: DateTime.now(),
                    );
                    ref
                        .read(homeViewModelProvider.notifier)
                        .updateReminder(updated);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Snoozed for 10 minutes')),
                    );
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: Colors.grey.shade400)),
                  icon: const Icon(Icons.snooze, color: Colors.grey),
                  label: Text(
                    'Snooze 10 Minutes',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),
                ),
              ),

            if (isDone)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.task_alt, size: 64, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Completed at ${reminder.completionHistory.isNotEmpty ? DateFormat('h:mm a').format(reminder.completionHistory.last) : ''}',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
