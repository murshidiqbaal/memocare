import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Drop-in widget used in AddEditReminderScreen.
/// Handles recording → local preview → delete.
/// Returns the saved local file path via [onRecordingComplete].
class VoiceRecorderWidget extends StatefulWidget {
  final void Function(String path) onRecordingComplete;
  final VoidCallback onDelete;
  final String? existingAudioPath;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    required this.onDelete,
    this.existingAudioPath,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _localPath; // Current recorded / existing path
  Duration _recordDuration = Duration.zero;

  // Tick every second while recording
  late final _ticker =
      Stream<int>.periodic(const Duration(seconds: 1), (t) => t + 1)
          .asBroadcastStream();

  @override
  void initState() {
    super.initState();
    _localPath = widget.existingAudioPath;

    _player.playerStateStream.listen((s) {
      if (mounted) {
        setState(() {
          _isPlaying = s.playing;
          if (s.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _player.seek(Duration.zero);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  // ── Recording ──────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showError('Microphone permission is required.');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/voice_reminder_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath);

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });

    // Track duration
    _ticker.take(300).listen(
      (t) {
        if (_isRecording && mounted) {
          setState(() => _recordDuration = Duration(seconds: t));
        }
      },
    );
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return;

    setState(() {
      _isRecording = false;
      _localPath = path;
    });

    widget.onRecordingComplete(path);
  }

  // ── Playback ───────────────────────────────────────────────────────────────

  Future<void> _togglePlay() async {
    if (_localPath == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.setFilePath(_localPath!);
      await _player.play();
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _deleteRecording() async {
    await _player.stop();
    if (_localPath != null) {
      final file = File(_localPath!);
      if (await file.exists()) await file.delete();
    }
    setState(() {
      _localPath = null;
      _recordDuration = Duration.zero;
    });
    widget.onDelete();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.mic, color: Colors.teal.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Voice Note',
                style: TextStyle(
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_localPath == null && !_isRecording) ...[
            // ── No recording yet ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startRecording,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: BorderSide(color: Colors.teal.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.mic_none),
                label:
                    const Text('Tap to Record', style: TextStyle(fontSize: 16)),
              ),
            ),
          ] else if (_isRecording) ...[
            // ── Currently recording ───────────────────────────────────────────
            Row(
              children: [
                // Pulsing red dot
                _PulsingDot(),
                const SizedBox(width: 12),
                Text(
                  'Recording  ${_formatDuration(_recordDuration)}',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _stopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
          ] else ...[
            // ── Recording exists ──────────────────────────────────────────────
            Row(
              children: [
                // Play / Pause
                IconButton(
                  onPressed: _togglePlay,
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 44,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice note recorded',
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Playback progress bar
                      StreamBuilder<Duration?>(
                        stream: _player.positionStream,
                        builder: (context, snap) {
                          final position = snap.data ?? Duration.zero;
                          final total =
                              _player.duration ?? const Duration(seconds: 1);
                          final progress =
                              (position.inMilliseconds / total.inMilliseconds)
                                  .clamp(0.0, 1.0);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.teal.shade100,
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDuration(position)} / ${_formatDuration(_player.duration ?? Duration.zero)}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.teal.shade600),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Re-record
                IconButton(
                  tooltip: 'Re-record',
                  onPressed: () async {
                    await _player.stop();
                    await _startRecording();
                  },
                  icon: Icon(Icons.refresh, color: Colors.teal.shade600),
                ),
                // Delete
                IconButton(
                  tooltip: 'Delete recording',
                  onPressed: _deleteRecording,
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Simple pulsing red dot for recording indicator
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  late final Animation<double> _anim =
      Tween(begin: 0.4, end: 1.0).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: const CircleAvatar(radius: 6, backgroundColor: Colors.red),
    );
  }
}
