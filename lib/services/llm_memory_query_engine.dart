import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/reminder.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/people_repository.dart';
import '../data/repositories/reminder_repository.dart';

/// Enhanced AI-powered memory retrieval engine with LLM integration
/// Uses Google Gemini for natural language understanding and context-aware responses
/// Optimized for dementia patients with empathetic, clear communication
class LLMMemoryQueryEngine {
  final ReminderRepository _reminderRepo;
  final PeopleRepository _peopleRepo;
  final MemoryRepository _memoryRepo;
  final SupabaseClient _supabase;
  final String _geminiApiKey;

  late final GenerativeModel _model;
  bool _isInitialized = false;

  LLMMemoryQueryEngine(
    this._reminderRepo,
    this._peopleRepo,
    this._memoryRepo,
    this._supabase,
    this._geminiApiKey,
  ) {
    _initializeModel();
  }

  /// Initialize Gemini model with dementia-care optimized settings
  void _initializeModel() {
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash', // Fast, free tier available
        apiKey: _geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7, // Balanced creativity and consistency
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 200, // Keep responses concise
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
        ],
      );
      _isInitialized = true;
    } catch (e) {
      print('Error initializing Gemini model: $e');
      _isInitialized = false;
    }
  }

  /// Process a patient query with LLM-powered understanding
  Future<String> processQuery(String query, String patientId) async {
    try {
      // Step 1: Gather patient context (memories, reminders, people)
      final context = await _gatherPatientContext(patientId);

      // Step 2: If LLM is available, use it for intelligent response
      if (_isInitialized) {
        return await _generateLLMResponse(query, context);
      } else {
        // Fallback to keyword-based system
        return await _generateKeywordResponse(query, patientId, context);
      }
    } catch (e) {
      print('Memory query error: $e');
      return _getEmpatheticFallback();
    }
  }

  /// Gather comprehensive patient context
  Future<PatientContext> _gatherPatientContext(String patientId) async {
    try {
      // Initialize repositories
      await Future.wait([
        _reminderRepo.init(),
        _peopleRepo.init(),
        _memoryRepo.init(),
      ]);

      // Fetch data in parallel
      final reminders = _reminderRepo.getReminders(patientId);
      final people = _peopleRepo.getPeople(patientId);
      final memories = _memoryRepo.getMemories(patientId);

      // Get today's and upcoming reminders
      final now = DateTime.now();
      final todayReminders = reminders.where((r) {
        return r.remindAt.day == now.day &&
            r.remindAt.month == now.month &&
            r.remindAt.year == now.year &&
            r.status == ReminderStatus.pending;
      }).toList();

      final upcomingReminders = reminders.where((r) {
        return r.remindAt.isAfter(now) && r.status == ReminderStatus.pending;
      }).toList()
        ..sort((a, b) => a.remindAt.compareTo(b.remindAt));

      // Get recent memories (last 7 days)
      final recentMemories = memories.where((m) {
        final daysDiff = now.difference(m.createdAt).inDays;
        return daysDiff <= 7;
      }).toList();

      return PatientContext(
        todayReminders: todayReminders,
        upcomingReminders: upcomingReminders.take(5).toList(),
        people: people,
        recentMemories: recentMemories.take(5).toList(),
      );
    } catch (e) {
      print('Error gathering context: $e');
      return PatientContext();
    }
  }

  /// Generate LLM-powered response with patient context
  Future<String> _generateLLMResponse(
    String query,
    PatientContext context,
  ) async {
    try {
      // Build context-aware prompt
      final prompt = _buildContextPrompt(query, context);

      // Generate response
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();

      if (text != null && text.isNotEmpty) {
        return text;
      } else {
        return _getEmpatheticFallback();
      }
    } catch (e) {
      print('LLM generation error: $e');
      // Fallback to keyword-based response
      return await _generateKeywordResponse(query, '', context);
    }
  }

  /// Build context-aware prompt for Gemini
  String _buildContextPrompt(String query, PatientContext context) {
    final buffer = StringBuffer();

    // System instruction
    buffer.writeln(
        '''You are a caring AI assistant for a dementia patient. Your role is to:
- Answer questions clearly and simply
- Be warm, patient, and reassuring
- Use short sentences (max 2-3 sentences)
- Avoid medical jargon
- Never mention that the patient has dementia
- Focus on positive, helpful information

Patient's question: "$query"

Available information:''');

    // Add today's reminders
    if (context.todayReminders.isNotEmpty) {
      buffer.writeln('\nToday\'s reminders:');
      for (var reminder in context.todayReminders.take(3)) {
        final time = _formatTime(reminder.remindAt);
        buffer.writeln('- ${reminder.title} at $time');
      }
    }

    // Add upcoming events
    if (context.upcomingReminders.isNotEmpty) {
      buffer.writeln('\nUpcoming events:');
      for (var reminder in context.upcomingReminders.take(3)) {
        final date = _formatDate(reminder.remindAt);
        final time = _formatTime(reminder.remindAt);
        buffer.writeln('- ${reminder.title} on $date at $time');
      }
    }

    // Add people information
    if (context.people.isNotEmpty) {
      buffer.writeln('\nImportant people:');
      for (var person in context.people.take(3)) {
        buffer.writeln(
            '- ${person.name} (${person.relationship})${person.description != null ? ': ${person.description}' : ''}');
      }
    }

    // Add recent memories
    if (context.recentMemories.isNotEmpty) {
      buffer.writeln('\nRecent activities:');
      for (var memory in context.recentMemories.take(3)) {
        buffer.writeln('- ${memory.title}');
      }
    }

    buffer.writeln('\nProvide a helpful, warm response (2-3 sentences max):');

    return buffer.toString();
  }

  /// Fallback keyword-based response (when LLM unavailable)
  Future<String> _generateKeywordResponse(
    String query,
    String patientId,
    PatientContext context,
  ) async {
    final lowerQuery = query.toLowerCase();

    // Reminder queries
    if (lowerQuery.contains('medicine') ||
        lowerQuery.contains('medication') ||
        lowerQuery.contains('pill') ||
        lowerQuery.contains('reminder')) {
      if (context.todayReminders.isEmpty) {
        return "You don't have any reminders right now. You're all caught up!";
      }
      final next = context.todayReminders.first;
      final time = _formatTime(next.remindAt);
      return 'Yes, you have ${next.title} at $time today.';
    }

    // Time/schedule queries
    if (lowerQuery.contains('time') || lowerQuery.contains('when')) {
      if (context.upcomingReminders.isNotEmpty) {
        final next = context.upcomingReminders.first;
        final date = _formatDate(next.remindAt);
        final time = _formatTime(next.remindAt);
        return 'Your next event is ${next.title} on $date at $time.';
      }
    }

    // People queries
    if (lowerQuery.contains('who') ||
        lowerQuery.contains('family') ||
        lowerQuery.contains('visit')) {
      if (context.people.isNotEmpty) {
        final person = context.people.first;
        return "${person.name} is your ${person.relationship}. ${person.description ?? 'They care about you very much.'}";
      }
      return 'Your family and friends care about you. They visit regularly.';
    }

    // Past activity queries
    if (lowerQuery.contains('yesterday') || lowerQuery.contains('did i')) {
      if (context.recentMemories.isNotEmpty) {
        final activities =
            context.recentMemories.map((m) => m.title).take(2).join(' and ');
        return 'Recently you enjoyed: $activities. You had a good time!';
      }
      return 'You had a good day and took care of yourself.';
    }

    // General help
    return "I'm here to help you remember things. You can ask me about your schedule, family, or what you did recently.";
  }

  /// Empathetic fallback response
  String _getEmpatheticFallback() {
    return "I'm here to help you. Can you ask me that again in a different way?";
  }

  /// Format time in 12-hour format
  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Format date in friendly format
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'today';
    } else if (date.day == tomorrow.day &&
        date.month == tomorrow.month &&
        date.year == tomorrow.year) {
      return 'tomorrow';
    } else {
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  /// Check if LLM is available
  bool get isLLMAvailable => _isInitialized;
}

/// Patient context data structure
class PatientContext {
  final List<dynamic> todayReminders;
  final List<dynamic> upcomingReminders;
  final List<dynamic> people;
  final List<dynamic> recentMemories;

  PatientContext({
    this.todayReminders = const [],
    this.upcomingReminders = const [],
    this.people = const [],
    this.recentMemories = const [],
  });
}
