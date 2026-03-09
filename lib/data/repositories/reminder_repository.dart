import 'dart:io';

import 'package:dementia_care_app/core/services/notification/reminder_notification_service.dart';
import 'package:dementia_care_app/core/services/voice_service.dart';
import 'package:dementia_care_app/data/datasources/local/local_reminder_datasource.dart';
import 'package:dementia_care_app/data/models/reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced ReminderRepository with:
/// - Realtime streams for patient and caregiver
/// - RLS-safe queries for caregiver-patient visibility
/// - Offline-first voice audio download for offline playback
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

  /// Get reminders for a specific patient
  Future<List<Reminder>> getReminders(String patientId) async {
    // 1. Return local data immediately for ultra-fast startup
    try {
      final localReminders = await _localDatasource.getAllReminders();
      final local =
          localReminders.where((r) => r.patientId == patientId).toList();

      if (local.isNotEmpty) {
        debugPrint(
            'ReminderRepository: Returning ${local.length} reminders from Hive');
        // We still sync in the background
        _syncFromSupabase(patientId).then((reminders) {
          // Sync successful, UI can be updated if listening to stream
        }).catchError((e) {
          debugPrint('Background sync failed: $e');
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

      // Clear local reminders that are no longer on Supabase
      final localData = await _localDatasource.getAllReminders();
      final localPatientReminders =
          localData.where((r) => r.patientId == patientId);
      final remoteIds = reminders.map((r) => r.id).toSet();

      for (final local in localPatientReminders) {
        if (!remoteIds.contains(local.id)) {
          await _localDatasource.deleteReminder(local.id);
        }
      }

      // Download voice audio locally for offline-first playback
      final updatedReminders = await Future.wait(
        reminders.map((r) => _ensureLocalAudio(r)),
      );

      // Update Hive with the final reminders (including localAudioPath)
      await _localDatasource.saveAllReminders(updatedReminders);

      // 4. Schedule local notifications for all future reminders
      await scheduleFutureReminders(updatedReminders);

      debugPrint(
          'ReminderRepository: Synced ${updatedReminders.length} reminders from Supabase');
      return updatedReminders;
    } catch (e) {
      debugPrint('ReminderRepository: Supabase fetch failed: $e');
      // If sync fails, return what we have locally
      final local = (await _localDatasource.getAllReminders())
          .where((r) => r.patientId == patientId)
          .toList();

      // Still try to schedule what we have locally just in case
      await scheduleFutureReminders(local);
      return local;
    }
  }

  /// Helper to schedule all future/pending reminders in the notification system
  Future<void> scheduleFutureReminders(List<Reminder> reminders) async {
    final now = DateTime.now();
    int count = 0;
    for (final r in reminders) {
      // Only schedule if pending and either repeating or in the future
      if (r.status == ReminderStatus.pending) {
        if (r.repeatRule != ReminderFrequency.once ||
            r.reminderTime.isAfter(now)) {
          await _notificationService.scheduleReminder(r);
          count++;
        }
      }
    }
    if (count > 0) {
      debugPrint('ReminderRepository: Scheduled $count notifications');
    }
  }

  /// Downloads the remote voice audio to a local file if not already present.
  /// Returns the reminder with [localAudioPath] set.
  Future<Reminder> _ensureLocalAudio(Reminder reminder) async {
    // Already has a valid local file — no download needed
    if (reminder.localAudioPath != null &&
        reminder.localAudioPath!.isNotEmpty) {
      final file = File(reminder.localAudioPath!);
      if (await file.exists()) return reminder;
    }

    // No remote URL to download from
    if (reminder.voiceAudioUrl == null || reminder.voiceAudioUrl!.isEmpty) {
      return reminder;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/voice_${reminder.id}.m4a';

      final file = File(localPath);
      if (!await file.exists()) {
        debugPrint(
            'ReminderRepository: Downloading voice audio for ${reminder.id}');
        final response = await http.get(Uri.parse(reminder.voiceAudioUrl!));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('ReminderRepository: Saved voice audio to $localPath');
        } else {
          debugPrint(
              'ReminderRepository: Failed to download voice audio (${response.statusCode})');
          return reminder;
        }
      }
      return reminder.copyWith(localAudioPath: localPath);
    } catch (e) {
      debugPrint('ReminderRepository: Voice audio download error: $e');
      return reminder;
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
      // No rethrow to allow offline mode to feel "working"
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
      // No rethrow
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
      // No rethrow
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
