import 'package:dementia_care_app/data/models/reminder.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/reminders/add_edit_reminder_screen.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/reminders/reminder_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

class ReminderCard extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onToggle;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggle,
  });

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
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
      if (localPath != null && localPath.isNotEmpty) {
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

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminder;
    final onToggle = widget.onToggle;
    // 1. Calculate Scale Factor based on reference width (e.g. 475 mobile width)
    final double scale = MediaQuery.of(context).size.width / 475.0;

    return InkWell(
      onTap: () => _navigateToDetails(context),
      borderRadius: BorderRadius.circular(20 * scale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: reminder.isCompleted ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20 * scale),
          border: Border.all(
            color: reminder.isCompleted
                ? Colors.grey.shade300
                : Colors.teal.shade100,
            width: 2,
          ),
          boxShadow: [
            if (!reminder.isCompleted)
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
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
                    : Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                reminder.isCompleted ? Icons.check : Icons.access_time_filled,
                color: reminder.isCompleted ? Colors.grey : Colors.teal,
                size: 28 * scale,
              ),
            ),
            SizedBox(width: 16 * scale),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caregiver Badge
                  if (reminder.caregiverId.isNotEmpty &&
                      reminder.caregiverId != reminder.patientId)
                    Container(
                      margin: EdgeInsets.only(bottom: 6 * scale),
                      padding: EdgeInsets.symmetric(
                          horizontal: 8 * scale, vertical: 4 * scale),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(6 * scale),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volunteer_activism,
                              size: 12 * scale, color: Colors.indigo.shade700),
                          SizedBox(width: 4 * scale),
                          Text(
                            'Added by Caregiver',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

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
                              : Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
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
                                SizedBox(width: 4 * scale),
                                Text(
                                  'Voice Note',
                                  style: TextStyle(
                                    fontSize: 12 * scale,
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

            SizedBox(width: 8 * scale),

            // Edit Button (Only if not completed)
            if (!reminder.isCompleted)
              IconButton(
                onPressed: () => _navigateToEdit(context),
                icon: Icon(Icons.edit, color: Colors.teal.shade700),
                iconSize: 24 * scale,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

            SizedBox(width: 8 * scale),

            // Action Button
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16 * scale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                    horizontal: 16 * scale, vertical: 10 * scale),
                decoration: BoxDecoration(
                  color:
                      reminder.isCompleted ? Colors.transparent : Colors.teal,
                  borderRadius: BorderRadius.circular(16 * scale),
                  border: Border.all(
                    color: reminder.isCompleted ? Colors.grey : Colors.teal,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  reminder.isCompleted ? 'Undo' : 'Done',
                  style: TextStyle(
                    color: reminder.isCompleted ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15 * scale,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
