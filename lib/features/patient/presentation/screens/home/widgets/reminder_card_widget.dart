import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memocare/data/models/reminder.dart';
import 'package:memocare/features/patient/presentation/screens/reminders/add_edit_reminder_screen.dart';
import 'package:memocare/features/patient/presentation/screens/reminders/reminder_detail_screen.dart';

class ReminderCard extends ConsumerStatefulWidget {
  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggle,
    this.onDelete,
  });

  @override
  ConsumerState<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends ConsumerState<ReminderCard> {
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

  Future<void> _playAudio() async {
    final url = widget.reminder.voiceAudioUrl;
    final localPath = widget.reminder.localAudioPath;

    if ((url == null || url.isEmpty) &&
        (localPath == null || localPath.isEmpty)) {
      return;
    }

    try {
      setState(() => _isLoadingAudio = true);
      if (localPath != null &&
          localPath.isNotEmpty &&
          await File(localPath).exists()) {
        await _player.setFilePath(localPath);
      } else if (url != null) {
        await _player.setUrl(url);
      }
      await _player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play audio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  Future<void> _stopAudio() async {
    await _player.stop();
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReminderDetailScreen(reminderId: widget.reminder.id),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditReminderScreen(existingReminder: widget.reminder),
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Reminder?'),
        content: const Text(
          'Are you sure you want to remove this reminder? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminder;
    final onToggle = widget.onToggle;
    final double scale = MediaQuery.of(context).size.width / 475.0;
    final isOverdue =
        !reminder.isCompleted && reminder.reminderTime.isBefore(DateTime.now());

    // 4. Resolve Creator Label (Part 3)
    final String? creatorLabel =
        reminder.createdRole == 'caregiver' ? "Caregiver" : null;

    return InkWell(
      onTap: () => _navigateToDetails(context),
      borderRadius: BorderRadius.circular(20 * scale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: reminder.isCompleted
              ? Colors.grey.shade100
              : (isOverdue ? Colors.red.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(20 * scale),
          border: Border.all(
            color: reminder.isCompleted
                ? Colors.grey.shade300
                : (isOverdue ? Colors.red.shade300 : Colors.teal.shade100),
            width: 2,
          ),
          boxShadow: [
            if (!reminder.isCompleted)
              BoxShadow(
                color: (isOverdue ? Colors.red : Colors.teal).withOpacity(0.1),
                blurRadius: 10 * scale,
                offset: Offset(0, 4 * scale),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon / Status Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: reminder.isCompleted
                    ? Colors.grey.shade200
                    : (isOverdue ? Colors.red.shade100 : Colors.teal.shade50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                reminder.isCompleted
                    ? Icons.check
                    : (isOverdue
                        ? Icons.priority_high
                        : Icons.access_time_filled),
                color: reminder.isCompleted
                    ? Colors.grey
                    : (isOverdue ? Colors.red : Colors.teal),
                size: 28 * scale,
              ),
            ),
            SizedBox(width: 16 * scale),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attribution Badge
                  if (creatorLabel != null && creatorLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_add_outlined,
                            size: 8,
                            color: Color(0xFF6C63FF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            creatorLabel,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Title
                  Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18 * scale,
                          color: reminder.isCompleted
                              ? Colors.grey
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          decoration: reminder.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          height: 1.2,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6 * scale),

                  // Time & Voice Indicator (Wrapped to prevent overflow)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8 * scale,
                    runSpacing: 4 * scale,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(reminder.time.toLocal()),
                        style: TextStyle(
                          fontSize: 16 * scale,
                          color: reminder.isCompleted
                              ? Colors.grey
                              : (isOverdue
                                  ? Colors.red.shade700
                                  : Colors.teal.shade700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isOverdue)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6 * scale, vertical: 2 * scale),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4 * scale),
                          ),
                          child: Text(
                            'OVERDUE',
                            style: TextStyle(
                              fontSize: 10 * scale,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      if (reminder.hasVoiceNote)
                        GestureDetector(
                          onTap: () {
                            if (_isPlaying) {
                              _stopAudio();
                            } else {
                              _playAudio();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8 * scale, vertical: 4 * scale),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8 * scale),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isLoadingAudio
                                    ? SizedBox(
                                        width: 14 * scale,
                                        height: 14 * scale,
                                        child: const CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 14 * scale,
                                        color: Colors.deepOrange),
                                // SizedBox(width: 4 * scale),
                                Text(
                                  'Voice Note',
                                  style: TextStyle(
                                    fontSize: 10 * scale,
                                    color: Colors.deepOrange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // SizedBox(width: 12 * scale),

            // Actions Area
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit & Delete (Only if not completed)
                if (!reminder.isCompleted) ...[
                  IconButton(
                    onPressed: () => _navigateToEdit(context),
                    icon: Icon(Icons.edit, color: Colors.teal.shade700),
                    iconSize: 22 * scale,
                    padding: EdgeInsets.all(4 * scale),
                    constraints: const BoxConstraints(),
                  ),
                  if (widget.onDelete != null) ...[
                    // SizedBox(width: 8 * scale),
                    IconButton(
                      onPressed: () => _showDeleteConfirmDialog(context),
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade400),
                      iconSize: 22 * scale,
                      padding: EdgeInsets.all(4 * scale),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                  // SizedBox(width: 12 * scale),
                ],

                // Action Button (Done / Undo)
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(12 * scale),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                        horizontal: 12 * scale, vertical: 8 * scale),
                    decoration: BoxDecoration(
                      color: reminder.isCompleted
                          ? Colors.transparent
                          : (isOverdue ? Colors.red : Colors.teal),
                      borderRadius: BorderRadius.circular(12 * scale),
                      border: Border.all(
                        color: reminder.isCompleted
                            ? Colors.grey
                            : (isOverdue ? Colors.red : Colors.teal),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      reminder.isCompleted ? 'Undo' : 'Done',
                      style: TextStyle(
                        color:
                            reminder.isCompleted ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14 * scale,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
