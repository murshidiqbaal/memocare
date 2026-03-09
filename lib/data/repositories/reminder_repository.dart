import 'package:dementia_care_app/core/services/notification/reminder_notification_service.dart';
import 'package:dementia_care_app/core/services/voice_service.dart';
import 'package:dementia_care_app/data/datasources/local/local_reminder_datasource.dart';
import 'package:dementia_care_app/data/models/reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced ReminderRepository with:
/// - Realtime streams for patient and caregiver
/// - RLS-safe queries for caregiver-patient visibility
/// - Proper error handling
class ReminderRepository {
  final SupabaseClient _supabase;
  final VoiceService _voiceService;
  final ReminderNotificationService _notificationService;
  final LocalReminderDatasource _localDatasource;

  ReminderRepository(
    this._supabase,
    this._voiceService,
    this._notificationService,
    this._localDatasource,
  );

  Future<void> init() async {}

  /// Get reminders for a specific patient (Offline-First)
  Future<List<Reminder>> getReminders(String patientId) async {
    // 1. Return local data immediately if available for ultra-fast startup
    try {
      final local = await _localDatasource.getAllReminders();
      if (local.isNotEmpty) {
        debugPrint(
            'ReminderRepository: Returning ${local.length} reminders from Hive');
        // We still sync in the background
        _syncFromSupabase(patientId).catchError((e) {
          debugPrint('Background sync failed: $e');
          return <Reminder>[];
        });
        return local;
      }
    } catch (e) {
      debugPrint('ReminderRepository: Error reading from Hive: $e');
    }

    // 2. Fetch from remote if Hive was empty or failed
    return await _syncFromSupabase(patientId);
  }

  Future<List<Reminder>> _syncFromSupabase(String patientId) async {
    try {
      final data = await _supabase
          .from('reminders')
          .select()
          .eq('patient_id', patientId)
          .order('reminder_time');

      final reminders = (data as List<dynamic>)
          .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update Hive
      await _localDatasource.saveAllReminders(reminders);
      debugPrint(
          'ReminderRepository: Synced ${reminders.length} reminders from Supabase');
      return reminders;
    } catch (e) {
      debugPrint('ReminderRepository: Supabase fetch failed: $e');
      // If sync fails, we already tried local in getReminders(), so we throw or return empty
      return await _localDatasource.getAllReminders();
    }
  }

  /// Watch patient reminders in realtime
  Stream<List<Reminder>> watchPatientRemindersRealtime(String patientId) {
    return _supabase
        .from('reminders')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('reminder_time')
        .map((data) => data.map((json) => Reminder.fromJson(json)).toList());
  }

  /// Watch reminders for all patients linked to a caregiver
  Stream<List<Reminder>> watchCaregiverPatientReminders(String caregiverId) {
    return _supabase
        .from('reminders')
        .stream(primaryKey: ['id'])
        .eq('caregiver_id', caregiverId)
        .order('reminder_time')
        .map((data) => data.map((json) => Reminder.fromJson(json)).toList());
  }

  /// Add reminder (Offline-First)
  Future<void> addReminder(Reminder reminder) async {
    // 1. Schedule local notification
    await _notificationService.scheduleReminder(reminder);

    // 2. Save locally first
    await _localDatasource.saveReminder(reminder);

    String? voiceUrl = reminder.voiceAudioUrl;
    if (reminder.localAudioPath != null && voiceUrl == null) {
      try {
        voiceUrl = await _voiceService.uploadVoiceNote(
            reminder.localAudioPath!, reminder.id);
      } catch (e) {
        debugPrint('Voice upload failed: $e');
      }
    }

    final updatedReminder = reminder.copyWith(voiceAudioUrl: voiceUrl);

    // 3. Sync to Supabase
    try {
      await _supabase.from('reminders').insert(updatedReminder.toJson());
      // Re-save local with voice URL if it changed
      await _localDatasource.saveReminder(updatedReminder);
      debugPrint('ReminderRepository: Added reminder to Supabase');
    } catch (e) {
      debugPrint('ReminderRepository: Supabase add failed (kept locally): $e');
      // We don't throw here to allow offline mode to feel "working"
      // But we might want to throw if we want the UI to show an error
      rethrow;
    }
  }

  Future<void> createReminderForPatient({
    required Reminder reminder,
  }) async {
    await addReminder(reminder);
  }

  /// Add reminder locally (used by realtime sync)
  Future<void> addReminderLocally(Reminder reminder) async {
    await _localDatasource.saveReminder(reminder);
  }

  /// Update reminder locally (used by realtime sync)
  Future<void> updateReminderLocally(Reminder reminder) async {
    await _localDatasource.saveReminder(reminder);
  }

  /// Delete reminder locally (used by realtime sync)
  Future<void> deleteReminderLocally(String id) async {
    await _localDatasource.deleteReminder(id);
  }

  /// Update reminder (Offline-First)
  Future<void> updateReminder(Reminder reminder) async {
    // 1. Update local notification
    await _notificationService.cancelReminder(reminder);
    if (reminder.status == ReminderStatus.pending) {
      await _notificationService.scheduleReminder(reminder);
    }

    // 2. Save locally first
    await _localDatasource.saveReminder(reminder);

    String? voiceUrl = reminder.voiceAudioUrl;
    if (reminder.localAudioPath != null && voiceUrl == null) {
      try {
        voiceUrl = await _voiceService.uploadVoiceNote(
            reminder.localAudioPath!, reminder.id);
      } catch (e) {
        debugPrint('Voice upload failed: $e');
      }
    }

    final updatedReminder = reminder.copyWith(voiceAudioUrl: voiceUrl);

    // 3. Sync to Supabase
    try {
      await _supabase
          .from('reminders')
          .update(updatedReminder.toJson())
          .eq('id', updatedReminder.id);
      await _localDatasource.saveReminder(updatedReminder);
      debugPrint('ReminderRepository: Updated reminder in Supabase');
    } catch (e) {
      debugPrint(
          'ReminderRepository: Supabase update failed (kept locally): $e');
      rethrow;
    }
  }

  /// Delete reminder (Offline-First)
  Future<void> deleteReminder(String id) async {
    // 1. Cancel notification
    await _notificationService.cancelReminderById(id);

    // 2. Delete locally first
    await _localDatasource.deleteReminder(id);

    // 3. Sync to Supabase
    try {
      await _supabase.from('reminders').delete().eq('id', id);
      debugPrint('ReminderRepository: Deleted reminder from Supabase');
    } catch (e) {
      debugPrint(
          'ReminderRepository: Supabase delete failed (deleted locally): $e');
      rethrow;
    }
  }

  /// Mark reminder as completed
  Future<void> markReminderCompleted(String id) async {
    try {
      final localData = await _localDatasource.getAllReminders();
      final reminder = localData.firstWhere((r) => r.id == id);

      final updated = reminder.copyWith(
        status: ReminderStatus.completed,
        completionHistory: [...reminder.completionHistory, DateTime.now()],
      );
      await updateReminder(updated);
    } catch (e) {
      // If not found in local, try remote
      final response =
          await _supabase.from('reminders').select().eq('id', id).single();
      final reminder = Reminder.fromJson(response);
      final updated = reminder.copyWith(
        status: ReminderStatus.completed,
        completionHistory: [...reminder.completionHistory, DateTime.now()],
      );
      await updateReminder(updated);
    }
  }

  Future<void> markAsDone(String id) async {
    await markReminderCompleted(id);
  }
}
