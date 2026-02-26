import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/reminder.dart';
import '../../../../providers/auth_provider.dart';
import 'viewmodels/reminder_viewmodel.dart';

class VoiceReminderScreen extends ConsumerStatefulWidget {
  const VoiceReminderScreen({super.key});

  @override
  ConsumerState<VoiceReminderScreen> createState() =>
      _VoiceReminderScreenState();
}

class _VoiceReminderScreenState extends ConsumerState<VoiceReminderScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  // Parsed Data
  String _parsedTitle = '';
  DateTime? _parsedTime;
  ReminderFrequency _parsedFrequency = ReminderFrequency.once;
  ReminderType _parsedType = ReminderType.task;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// Initialize speech recognition service
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  /// Start listening
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
      _lastWords = '';
    });
  }

  /// Stop listening manually
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    // _parseIntent is called in listener when final result?
    // Usually speech_to_text calls final result automatically?
    // If stopped manually, we might not get final result callback with `finalResult: true`.
    // We should parse current `_lastWords`.
    if (_lastWords.isNotEmpty) {
      _parseIntent(_lastWords);
    }
  }

  /// Callback when speech is detected
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult) {
      _stopListening();
      _parseIntent(result.recognizedWords);
    }
  }

  /// Simple heuristic parser
  void _parseIntent(String text) {
    String lowerText = text.toLowerCase();

    // Frequency
    if (lowerText.contains('daily') || lowerText.contains('every day')) {
      _parsedFrequency = ReminderFrequency.daily;
    } else if (lowerText.contains('weekly') ||
        lowerText.contains('every week')) {
      _parsedFrequency = ReminderFrequency.weekly;
    } else {
      _parsedFrequency = ReminderFrequency.once;
    }

    // Type
    if (lowerText.contains('pill') ||
        lowerText.contains('med') ||
        lowerText.contains('drug') ||
        lowerText.contains('take')) {
      _parsedType = ReminderType.medication;
    } else if (lowerText.contains('doctor') ||
        lowerText.contains('appointment') ||
        lowerText.contains('visit')) {
      _parsedType = ReminderType.appointment;
    } else {
      _parsedType = ReminderType.task;
    }

    // Time (Simple regex for "8 pm", "10:30 am")
    // This is a basic parser. A production app would use a stronger NLP library.
    DateTime now = DateTime.now();
    DateTime time = now.add(const Duration(hours: 1)); // Default 1 hour later

    final strictTimeRegex = RegExp(r'(\d{1,2})(:(\d{2}))?\s*(am|pm)');
    final match = strictTimeRegex.firstMatch(lowerText);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      String period = match.group(4)!;

      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      time = DateTime(now.year, now.month, now.day, hour, minute);

      // If time has passed today, schedule for tomorrow
      if (time.isBefore(now)) {
        time = time.add(const Duration(days: 1));
      }
    }

    // Title parsing
    // ... (logic from before)
    final cleanTitle = text
        .trim(); // Just use full text for title simplicity in demo or remove parsed parts?
    // Using full text is often better than aggressive stripping for fallbacks.

    setState(() {
      _parsedTitle = cleanTitle.isEmpty ? 'New Reminder' : cleanTitle;
      _parsedTitle = _parsedTitle[0].toUpperCase() + _parsedTitle.substring(1);
      _parsedTime = time;
    });
  }

  void _confirmAndSave() {
    if (_parsedTitle.isEmpty) return;

    final userId = ref.read(currentUserProvider)?.id ?? 'offline_user';

    final reminder = Reminder(
      id: const Uuid().v4(),
      title: _parsedTitle,
      reminderTime: _parsedTime ?? DateTime.now(),
      createdAt: DateTime.now(),
      repeatRule: _parsedFrequency,
      type: _parsedType,
      patientId: userId,
      status: ReminderStatus.pending,
      caregiverId: userId,
    );

    ref.read(reminderViewModelProvider.notifier).addReminder(reminder);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reminder set!')));
  }

  @override
  Widget build(BuildContext context) {
    // ... UI same as before ...
    // Reuse the UI logic
    final bool hasParsed = _parsedTitle.isNotEmpty && !_isListening;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Voice Reminder'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Instructions
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _isListening
                  ? 'Listening...'
                  : 'Tap the microphone and say something like:\n\n"Take medicine at 8 PM daily"',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  color: _isListening ? Colors.teal : Colors.grey.shade600),
            ),
          ),

          const Spacer(),

          // Microphone Button
          GestureDetector(
            onTap: _isListening
                ? _stopListening
                : (_speechEnabled ? _startListening : null),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  color: _isListening ? Colors.redAccent : Colors.teal,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.redAccent : Colors.teal)
                          .withOpacity(0.3),
                      spreadRadius: 10,
                      blurRadius: 20,
                    )
                  ]),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),

          if (!_speechEnabled)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Microphone not available',
                  style: TextStyle(color: Colors.red)),
            ),

          const SizedBox(height: 32),

          // Live Transcript
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _lastWords,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ),

          const Spacer(),

          // Confirmation Card
          if (hasParsed)
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                children: [
                  const Text('Create this reminder?',
                      style: TextStyle(color: Colors.teal)),
                  const SizedBox(height: 8),
                  Text(
                    _parsedTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _parsedTime != null
                        ? "at ${_parsedTime!.hour > 12 ? _parsedTime!.hour - 12 : _parsedTime!.hour}:${_parsedTime!.minute.toString().padLeft(2, '0')} ${_parsedTime!.hour >= 12 ? 'PM' : 'AM'}"
                        : 'No time detected',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    _parsedFrequency.toString().split('.').last.toUpperCase(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    _parsedType.name.toUpperCase(),
                    style: TextStyle(
                        color: Colors.teal.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Clear to try again
                          setState(() {
                            _lastWords = '';
                            _parsedTitle = '';
                          });
                        },
                        child: const Text('Retry'),
                      ),
                      ElevatedButton(
                        onPressed: _confirmAndSave,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white),
                        child: const Text('Confirm'),
                      ),
                    ],
                  )
                ],
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
