import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:memocare/core/services/voice/voice_storage_service.dart';
import 'package:memocare/data/datasources/local/local_reminder_datasource.dart';
import 'package:memocare/data/models/reminder.dart';
import 'package:memocare/services/reminder_notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enhanced ReminderRepository with:
/// - Realtime streams for patient and caregiver
/// - RLS-safe queries for caregiver-patient visibility
/// - Offline-first voice audio download for offline playback
/// - Proper error handling and FK-safe Supabase inserts
class ReminderRepository {
  final SupabaseClient _supabase;
  final VoiceStorageService _voiceService;
  final ReminderNotificationService _notificationService;
  final LocalReminderDatasource _localDatasource;

  ReminderRepository(
    this._supabase,
    this._voiceService,
    this._notificationService,
    this._localDatasource,
  );

  Future<void> init() async {}

  // ---------------------------------------------------------------------------
  // PRIVATE: Build a Supabase-safe JSON map.
  //
  Map<String, dynamic> _toSupabaseJson(Reminder r) {
    return {
      'id': r.id,
      'patient_id': r.patientId,
      'caregiver_id': r.caregiverId,
      'title': r.title,
      'description': r.description,
      'reminder_time': r.reminderTime.toUtc().toIso8601String(),
      'repeat_rule': r.repeatRule.name,
      'completion_status': r.status.name,
      'created_by': r.createdBy,
      'created_role': r.createdRole,
      'voice_audio_url': r.voiceAudioUrl,
      'alarm_enabled': r.alarmEnabled,
      'notification_enabled': true,
      'notification_id': r.notificationId,
    };
  }

  // ---------------------------------------------------------------------------
  // PRIVATE: Validate FK IDs before any Supabase insert / update.
  //
  // Throws a descriptive [Exception] if either ID looks like an auth.users UUID
  // that was accidentally passed instead of the internal table primary key.
  // ---------------------------------------------------------------------------
  Future<void> _validateFkIds(Reminder reminder) async {
    // --- Validate caregiver_id → caregiver_profiles.id -----------------------
    if (reminder.caregiverId.isEmpty) {
      throw Exception(
          '[ReminderRepository] caregiverId is empty — cannot insert reminder.');
    }

    final caregiverRow = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('id', reminder.caregiverId)
        .maybeSingle();

    if (caregiverRow == null) {
      // Attempt to detect the common mistake: auth UUID used instead of profile UUID.
      final authUser = _supabase.auth.currentUser;
      final hint = authUser?.id == reminder.caregiverId
          ? ' (You passed auth.users.id — use caregiver_profiles.id instead!)'
          : '';
      throw Exception(
          '[ReminderRepository] FK violation — caregiver_id "${reminder.caregiverId}" '
          'not found in caregiver_profiles.$hint');
    }

    // --- Validate patient_id → patients.id ------------------------------------
    if (reminder.patientId.isEmpty) {
      throw Exception(
          '[ReminderRepository] patientId is empty — cannot insert reminder.');
    }

    final patientRow = await _supabase
        .from('patients')
        .select('id')
        .eq('id', reminder.patientId)
        .maybeSingle();

    if (patientRow == null) {
      throw Exception(
          '[ReminderRepository] FK violation — patient_id "${reminder.patientId}" '
          'not found in patients table.');
    }

    debugPrint(
        '[ReminderRepository] FK pre-check passed: caregiver=${reminder.caregiverId}, patient=${reminder.patientId}');
  }

  /// Get reminders for a specific patient
  Future<List<Reminder>> getReminders(String patientId) async {
    // 1. Return local data immediately for ultra-fast startup
    try {
      final localReminders = await _localDatasource.getAllReminders();
      final local =
          localReminders.where((r) => r.patientId == patientId).toList();

      if (local.isNotEmpty) {
        debugPrint(
            '[ReminderRepository] Returning ${local.length} reminders from Hive');
        // Fix 4: Also schedule notifications from Hive so reminders still fire offline
        await scheduleFutureReminders(local);
        // We still sync in the background
        _syncFromSupabase(patientId).catchError((Object e) {
          debugPrint('[ReminderRepository] Background sync failed: $e');
          return <Reminder>[];
        });
        return local;
      }
    } catch (e) {
      debugPrint('[ReminderRepository] Error reading from Hive: $e');
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

      // Schedule local notifications for all future reminders
      await scheduleFutureReminders(updatedReminders);

      debugPrint(
          '[ReminderRepository] Synced ${updatedReminders.length} reminders from Supabase');
      return updatedReminders;
    } catch (e) {
      debugPrint('[ReminderRepository] Supabase fetch failed: $e');
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
  /// Fix 1: Only schedule reminders that are pending AND have a future reminderTime.
  Future<void> scheduleFutureReminders(List<Reminder> reminders) async {
    int count = 0;
    for (final r in reminders) {
      // Only schedule if still pending and time is in the future (or repeating)
      if (r.status == ReminderStatus.pending &&
          (r.repeatRule != ReminderFrequency.once ||
              r.reminderTime.isAfter(DateTime.now()))) {
        await _notificationService.scheduleReminder(r);
        count++;
      }
    }
    if (count > 0) {
      debugPrint('[ReminderRepository] Scheduled $count notifications');
    }
  }

  /// Fix 2: Reschedule all reminders after app restart by reading from Hive.
  /// Call this from main.dart during init.
  Future<void> rescheduleAllReminders() async {
    try {
      final reminders = await _localDatasource.getAllReminders();

      final now = DateTime.now();

      for (final reminder in reminders) {
        if (reminder.status == ReminderStatus.pending &&
            reminder.reminderTime.isAfter(now)) {
          await _notificationService.scheduleReminder(reminder);
        }
      }

      debugPrint(
          '[ReminderRepository] Rescheduled ${reminders.length} reminders from Hive');
    } catch (e) {
      debugPrint('[ReminderRepository] Failed to reschedule reminders: $e');
    }
  }

  /// Downloads the remote voice audio to a local file if not already present.
  /// Fix 5: Uses Supabase Storage download for Supabase-hosted voice notes.
  Future<Reminder> _ensureLocalAudio(Reminder reminder) async {
    if (reminder.localAudioPath != null &&
        reminder.localAudioPath!.isNotEmpty) {
      final file = File(reminder.localAudioPath!);
      if (await file.exists()) return reminder;
    }

    if (reminder.voiceAudioUrl == null || reminder.voiceAudioUrl!.isEmpty) {
      return reminder;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/voice_${reminder.id}.m4a';

      final file = File(localPath);
      if (!await file.exists()) {
        debugPrint(
            '[ReminderRepository] Downloading voice audio for ${reminder.id}');

        // Fix 5: Prefer Supabase Storage download for reliability
        final url = reminder.voiceAudioUrl!;
        Uint8List? bytes;

        if (url.contains('supabase') || url.contains('voice-notes')) {
          // Extract file path from the Supabase public URL
          // e.g: https://<project>.supabase.co/storage/v1/object/public/voice-notes/<path>
          final uri = Uri.parse(url);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexOf('voice-notes');
          if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
            bytes =
                await _supabase.storage.from('voice-notes').download(filePath);
          }
        }

        // Fallback to http if Supabase download was not applicable
        bytes ??= (await http.get(Uri.parse(url))).bodyBytes;

        await file.writeAsBytes(bytes);
        debugPrint('[ReminderRepository] Saved voice audio to $localPath');
      }
      return reminder.copyWith(localAudioPath: localPath);
    } catch (e) {
      debugPrint('[ReminderRepository] Voice audio download error: $e');
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

    // 2. Save locally first (always works offline)
    await _localDatasource.saveReminder(reminder);

    String? voiceUrl = reminder.voiceAudioUrl;
    if (reminder.localAudioPath != null && voiceUrl == null) {
      try {
        final authUid = _supabase.auth.currentUser?.id;
        if (authUid != null) {
          voiceUrl = await _voiceService.uploadVoiceNote(
            localPath: reminder.localAudioPath!,
            reminderId: reminder.id,
            userId: authUid,
          );
        }
      } catch (e) {
        debugPrint('[ReminderRepository] Voice upload failed: $e');
      }
    }

    final updatedReminder = reminder.copyWith(voiceAudioUrl: voiceUrl);

    // 3. Validate FK IDs before attempting Supabase insert
    // This catches wrong-ID mistakes early with a clear error message.
    try {
      await _validateFkIds(updatedReminder);
    } catch (e) {
      debugPrint('[ReminderRepository] FK pre-check failed: $e');
      // Reminder is already saved locally — fail gracefully
      return;
    }

    // 4. Sync to Supabase using the FK-safe JSON helper
    try {
      final authUid = _supabase.auth.currentUser?.id;
      final data = _toSupabaseJson(updatedReminder);
      debugPrint('[ReminderRepository] Attempting Supabase Insert:\n'
          '  Auth UID: $authUid\n'
          '  caregiver_id: ${data['caregiver_id']}\n'
          '  patient_id: ${data['patient_id']}\n'
          '  created_by: ${data['created_by']}\n'
          '  created_role: ${data['created_role']}\n'
          '  reminder_time: ${data['reminder_time']}');

      await _supabase.from('reminders').insert(data);

      // Re-save local with voice URL if it changed
      await _localDatasource.saveReminder(updatedReminder);
      debugPrint('[ReminderRepository] Added reminder to Supabase ✅');
    } on PostgrestException catch (e) {
      debugPrint('[ReminderRepository] Supabase insert failed ❌\n'
          '  Code: ${e.code}\n'
          '  Message: ${e.message}\n'
          '  Details: ${e.details}\n'
          '  Hint: ${e.hint}');
      rethrow;
    } catch (e) {
      debugPrint('[ReminderRepository] Unexpected insert error: $e');
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
        final authUid = _supabase.auth.currentUser?.id;
        if (authUid != null) {
          voiceUrl = await _voiceService.uploadVoiceNote(
            localPath: reminder.localAudioPath!,
            reminderId: reminder.id,
            userId: authUid,
          );
        }
      } catch (e) {
        debugPrint('[ReminderRepository] Voice upload failed: $e');
      }
    }

    final updatedReminder = reminder.copyWith(voiceAudioUrl: voiceUrl);

    // 3. Sync to Supabase using the FK-safe JSON helper
    try {
      final authUid = _supabase.auth.currentUser?.id;
      final data = _toSupabaseJson(updatedReminder);
      debugPrint('[ReminderRepository] Attempting Supabase Update:\n'
          '  Auth UID: $authUid\n'
          '  Reminder ID: ${updatedReminder.id}\n'
          '  caregiver_id: ${data['caregiver_id']}\n'
          '  patient_id: ${data['patient_id']}\n'
          '  created_by: ${data['created_by']}\n'
          '  created_role: ${data['created_role']}');

      await _supabase
          .from('reminders')
          .update(data)
          .eq('id', updatedReminder.id);

      await _localDatasource.saveReminder(updatedReminder);
      debugPrint('[ReminderRepository] Updated reminder in Supabase ✅');
    } on PostgrestException catch (e) {
      debugPrint('[ReminderRepository] Supabase update failed ❌\n'
          '  Code: ${e.code}\n'
          '  Message: ${e.message}\n'
          '  Details: ${e.details}');
      rethrow;
    } catch (e) {
      debugPrint('[ReminderRepository] Unexpected update error: $e');
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
      debugPrint('[ReminderRepository] Deleted reminder from Supabase ✅');
    } catch (e) {
      debugPrint(
          '[ReminderRepository] Supabase delete failed (deleted locally): $e');
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
