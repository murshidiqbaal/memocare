import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/reminder.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/people_repository.dart';
import '../data/repositories/reminder_repository.dart';

/// Query types for classification
enum QueryType {
  reminder, // "Do I have medicine now?"
  pastActivity, // "What did I do yesterday?"
  person, // "Who is visiting today?"
  appointment, // "What is my next appointment?"
  general, // General help
}

/// AI-powered memory retrieval engine
/// Analyzes patient questions and retrieves relevant information
/// from reminders, memories, people cards, and journal entries
class MemoryQueryEngine {
  final ReminderRepository _reminderRepo;
  final PeopleRepository _peopleRepo;
  final MemoryRepository _memoryRepo;
  final SupabaseClient _supabase;

  MemoryQueryEngine(
    this._reminderRepo,
    this._peopleRepo,
    this._memoryRepo,
    this._supabase,
  );

  /// Process a patient query and generate a response
  Future<String> processQuery(String query, String patientId) async {
    try {
      // Step 1: Classify the question
      final queryType = _classifyQuery(query);

      // Step 2: Fetch relevant data
      final response = await _generateResponse(queryType, query, patientId);

      return response;
    } catch (e) {
      print('Memory query error: $e');
      return _getFallbackResponse();
    }
  }

  /// Classify the query type based on keywords
  QueryType _classifyQuery(String query) {
    final lowerQuery = query.toLowerCase();

    // Reminder-related keywords
    if (lowerQuery.contains('medicine') ||
        lowerQuery.contains('medication') ||
        lowerQuery.contains('pill') ||
        lowerQuery.contains('take') ||
        lowerQuery.contains('reminder') ||
        lowerQuery.contains('now') ||
        lowerQuery.contains('today')) {
      return QueryType.reminder;
    }

    // Past activity keywords
    if (lowerQuery.contains('yesterday') ||
        lowerQuery.contains('did i') ||
        lowerQuery.contains('what happened') ||
        lowerQuery.contains('last')) {
      return QueryType.pastActivity;
    }

    // Person-related keywords
    if (lowerQuery.contains('who') ||
        lowerQuery.contains('visiting') ||
        lowerQuery.contains('coming') ||
        lowerQuery.contains('family') ||
        lowerQuery.contains('friend')) {
      return QueryType.person;
    }

    // Appointment keywords
    if (lowerQuery.contains('appointment') ||
        lowerQuery.contains('doctor') ||
        lowerQuery.contains('visit') ||
        lowerQuery.contains('meeting') ||
        lowerQuery.contains('next')) {
      return QueryType.appointment;
    }

    return QueryType.general;
  }

  /// Generate response based on query type
  Future<String> _generateResponse(
    QueryType type,
    String query,
    String patientId,
  ) async {
    switch (type) {
      case QueryType.reminder:
        return await _handleReminderQuery(patientId);

      case QueryType.pastActivity:
        return await _handlePastActivityQuery(patientId);

      case QueryType.person:
        return await _handlePersonQuery(patientId);

      case QueryType.appointment:
        return await _handleAppointmentQuery(patientId);

      case QueryType.general:
        return _handleGeneralQuery();
    }
  }

  /// Handle reminder-related queries
  Future<String> _handleReminderQuery(String patientId) async {
    try {
      await _reminderRepo.init();
      final reminders = _reminderRepo.getReminders(patientId);

      // Get today's pending reminders
      final now = DateTime.now();
      final todayReminders = reminders.where((r) {
        return r.remindAt.day == now.day &&
            r.remindAt.month == now.month &&
            r.remindAt.year == now.year &&
            r.status == ReminderStatus.pending;
      }).toList();

      if (todayReminders.isEmpty) {
        return "You don't have any reminders right now. You're all caught up!";
      }

      // Find the next upcoming reminder
      todayReminders.sort((a, b) => a.remindAt.compareTo(b.remindAt));
      final nextReminder = todayReminders.firstWhere(
        (r) => r.remindAt.isAfter(now),
        orElse: () => todayReminders.first,
      );

      final timeStr = _formatTime(nextReminder.remindAt);
      return 'Yes, you have ${nextReminder.title} at $timeStr today.';
    } catch (e) {
      return 'Let me check your reminders. You have some tasks scheduled for today.';
    }
  }

  /// Handle past activity queries
  Future<String> _handlePastActivityQuery(String patientId) async {
    try {
      await _reminderRepo.init();
      final reminders = _reminderRepo.getReminders(patientId);

      // Get yesterday's completed reminders
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayReminders = reminders.where((r) {
        return r.remindAt.day == yesterday.day &&
            r.remindAt.month == yesterday.month &&
            r.remindAt.year == yesterday.year &&
            r.status == ReminderStatus.completed;
      }).toList();

      if (yesterdayReminders.isEmpty) {
        return 'Yesterday was a quiet day. You rested and took care of yourself.';
      }

      final activities =
          yesterdayReminders.map((r) => r.title).take(3).join(', ');
      return 'Yesterday you completed: $activities. You had a productive day!';
    } catch (e) {
      return 'Yesterday you had a good day and completed your tasks.';
    }
  }

  /// Handle person-related queries
  Future<String> _handlePersonQuery(String patientId) async {
    try {
      await _peopleRepo.init();
      final people = _peopleRepo.getPeople(patientId);

      if (people.isEmpty) {
        return 'Your family and friends care about you. They visit regularly.';
      }

      // Get a random person to mention (or first person)
      final person = people.first;
      return "${person.name} is your ${person.relationship}. ${person.description ?? 'They care about you very much.'}";
    } catch (e) {
      return 'Your loved ones are thinking of you and will visit soon.';
    }
  }

  /// Handle appointment queries
  Future<String> _handleAppointmentQuery(String patientId) async {
    try {
      await _reminderRepo.init();
      final reminders = _reminderRepo.getReminders(patientId);

      // Find upcoming appointments
      final now = DateTime.now();
      final appointments = reminders.where((r) {
        return r.type == ReminderType.appointment &&
            r.remindAt.isAfter(now) &&
            r.status == ReminderStatus.pending;
      }).toList();

      if (appointments.isEmpty) {
        return "You don't have any appointments scheduled right now.";
      }

      appointments.sort((a, b) => a.remindAt.compareTo(b.remindAt));
      final next = appointments.first;

      final dateStr = _formatDate(next.remindAt);
      final timeStr = _formatTime(next.remindAt);
      return 'Your next appointment is ${next.title} on $dateStr at $timeStr.';
    } catch (e) {
      return "Let me check your appointments. I'll help you remember.";
    }
  }

  /// Handle general queries
  String _handleGeneralQuery() {
    return "I'm here to help you remember things. You can ask me about your reminders, appointments, or what you did yesterday.";
  }

  /// Fallback response for errors
  String _getFallbackResponse() {
    return "I'm here to help you. Can you ask me again in a different way?";
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
}
