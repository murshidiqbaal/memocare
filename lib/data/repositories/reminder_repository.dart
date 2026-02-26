import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/notification/reminder_notification_service.dart';
import '../../services/voice_service.dart';
import '../models/reminder.dart';

/// Enhanced ReminderRepository with:
/// - Realtime streams for patient and caregiver
/// - RLS-safe queries for caregiver-patient visibility
/// - Proper error handling
class ReminderRepository {
  final SupabaseClient _supabase;
  final VoiceService _voiceService;
  final ReminderNotificationService _notificationService;

  ReminderRepository(
      this._supabase, this._voiceService, this._notificationService);

  Future<void> init() async {}

  /// Get reminders for a specific patient
  Future<List<Reminder>> getReminders(String patientId) async {
    try {
      final data = await _supabase
          .from('reminders')
          .select()
          .eq('patient_id', patientId)
          .order('reminder_time');

      return (data as List<dynamic>)
          .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('ReminderRepository: Error fetching reminders: $e');
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  /// Watch patient reminders in realtime
  /// Returns a stream that updates when reminders change in Supabase
  Stream<List<Reminder>> watchPatientRemindersRealtime(String patientId) {
    return _supabase
        .from('reminders')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('reminder_time')
        .map((data) => data.map((json) => Reminder.fromJson(json)).toList());
  }

  /// Watch reminders for all patients linked to a caregiver
  /// RLS-safe: Uses caregiver_patient_links join or policy
  Stream<List<Reminder>> watchCaregiverPatientReminders(String caregiverId) {
    return _supabase
        .from('reminders')
        .stream(primaryKey: ['id'])
        .eq('caregiver_id', caregiverId)
        .order('reminder_time')
        .map((data) => data.map((json) => Reminder.fromJson(json)).toList());
  }

  /// Add reminder
  Future<void> addReminder(Reminder reminder) async {
    // 1. Schedule Notification (local only for now, if patient is adding, though usually Caregiver adds)
    await _notificationService.scheduleReminder(reminder);

    String? voiceUrl = reminder.voiceAudioUrl;
    if (reminder.localAudioPath != null && voiceUrl == null) {
      try {
        voiceUrl = await _voiceService.uploadVoiceNote(
            reminder.localAudioPath!, reminder.id);
      } catch (e) {
        print('Voice upload failed: $e');
      }
    }

    final updatedReminder = reminder.copyWith(voiceAudioUrl: voiceUrl);

    // 2. Sync to Supabase
    try {
      await _supabase.from('reminders').insert(updatedReminder.toJson());
    } catch (e) {
      print('Sync error adding reminder: $e');
      throw Exception('Failed to create reminder: $e');
    }
  }

  Future<void> createReminderForPatient({
    required Reminder reminder,
  }) async {
    await addReminder(reminder);
  }

  /// Update reminder
  Future<void> updateReminder(Reminder reminder) async {
    // 1. Clear previous notification, and schedule new one
    await _notificationService.cancelReminder(reminder);
    if (reminder.status == ReminderStatus.pending) {
      await _notificationService.scheduleReminder(reminder);
    }

    String? voiceUrl = reminder.voiceAudioUrl;
    if (reminder.localAudioPath != null && voiceUrl == null) {
      try {
        voiceUrl = await _voiceService.uploadVoiceNote(
            reminder.localAudioPath!, reminder.id);
      } catch (e) {
        print('Voice upload failed: $e');
      }
    }

    final updatedReminder = reminder.copyWith(voiceAudioUrl: voiceUrl);

    // 2. Sync to Supabase
    try {
      await _supabase
          .from('reminders')
          .update(updatedReminder.toJson())
          .eq('id', updatedReminder.id);
    } catch (e) {
      print('Sync error updating reminder: $e');
      throw Exception('Failed to update reminder: $e');
    }
  }

  /// Snooze reminder
  Future<void> snoozeReminder(String id, int minutes) async {
    try {
      final response =
          await _supabase.from('reminders').select().eq('id', id).single();
      final reminder = Reminder.fromJson(response);

      final updated = reminder.copyWith(
        isSnoozed: true,
        snoozeDurationMinutes: minutes,
        lastSnoozedAt: DateTime.now(),
        // For UI, we advance the reminderTime visually
        reminderTime: reminder.reminderTime.add(Duration(minutes: minutes)),
      );
      await updateReminder(updated);
    } catch (e) {
      print('Error snoozing reminder: $e');
      throw Exception('Failed to snooze reminder: $e');
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    await _notificationService.cancelReminderById(id);

    try {
      await _supabase.from('reminders').delete().eq('id', id);
    } catch (e) {
      print('Sync error deleting reminder: $e');
      throw Exception('Failed to delete reminder: $e');
    }
  }

  /// Mark reminder as completed
  Future<void> markReminderCompleted(String id) async {
    try {
      final response =
          await _supabase.from('reminders').select().eq('id', id).single();

      final reminder = Reminder.fromJson(response);
      final updated = reminder.copyWith(
        status: ReminderStatus.completed,
        completionHistory: [...reminder.completionHistory, DateTime.now()],
      );
      await updateReminder(updated);
    } catch (e) {
      print('Error marking reminder completed: $e');
      throw Exception('Failed to complete reminder: $e');
    }
  }

  /// Mark as done
  Future<void> markAsDone(String id) async {
    await markReminderCompleted(id);
  }
}
