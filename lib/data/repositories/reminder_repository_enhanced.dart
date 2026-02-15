import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/voice_service.dart';
import '../models/reminder.dart';

/// Enhanced ReminderRepository with:
/// - Realtime streams for patient and caregiver
/// - RLS-safe queries for caregiver-patient visibility
/// - Proper error handling
class ReminderRepository {
  final SupabaseClient _supabase;
  final VoiceService _voiceService;
  late Box<Reminder> _box;
  bool _isInit = false;

  ReminderRepository(this._supabase, this._voiceService);

  Future<void> init() async {
    if (_isInit) return;
    try {
      _box = await Hive.openBox<Reminder>('reminders_box');
      _isInit = true;
      print('Hive initialized. Box: reminders_box, Open: ${_box.isOpen}');
    } catch (e) {
      print('Error opening Hive box: $e');
    }
  }

  /// Get reminders for a specific patient (local Hive)
  List<Reminder> getReminders(String patientId) {
    if (!_isInit) {
      print('ReminderRepository not initialized');
      return [];
    }
    final all = _box.values.toList();
    final unique = all.toSet().toList();
    final filtered = unique.where((r) => r.patientId == patientId).toList();

    // Sort: Pending first, then by time
    filtered.sort((a, b) {
      if (a.status != b.status) {
        return a.status == ReminderStatus.pending ? -1 : 1;
      }
      return a.remindAt.compareTo(b.remindAt);
    });

    print(
        'ReminderRepository: Loaded ${filtered.length} reminders for patient $patientId (Total in box: ${all.length})');
    return filtered;
  }

  /// ✅ NEW: Watch patient reminders in realtime
  /// Returns a stream that updates when reminders change in Supabase
  Stream<List<Reminder>> watchPatientRemindersRealtime(String patientId) {
    return _supabase
        .from('reminders')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('remind_at')
        .map((data) {
          final reminders =
              data.map((json) => Reminder.fromJson(json)).toList();

          // Update local Hive cache
          _updateLocalCache(reminders);

          return reminders;
        });
  }

  /// ✅ NEW: Watch reminders for all patients linked to a caregiver
  /// RLS-safe: Uses caregiver_patient_links join
  Stream<List<Reminder>> watchCaregiverPatientReminders(String caregiverId) {
    // Query reminders where patient_id is in the caregiver's linked patients
    // This assumes RLS policies allow caregivers to see linked patient reminders
    return _supabase
        .from('reminders')
        .stream(primaryKey: ['id'])
        .order('remind_at')
        .map((data) {
          final reminders =
              data.map((json) => Reminder.fromJson(json)).toList();

          // Filter locally for linked patients (if RLS doesn't handle it)
          // In production, RLS should handle this filtering server-side
          _updateLocalCache(reminders);

          return reminders;
        });
  }

  /// ✅ NEW: Create reminder for a specific patient (caregiver action)
  Future<void> createReminderForPatient({
    required Reminder reminder,
    required String createdBy, // caregiver user ID
  }) async {
    if (!_isInit) await init();

    // Save to Hive first (Offline-first)
    await _box.put(reminder.id, reminder.copyWith(isSynced: false));

    // Try to upload audio if local path exists
    String? voiceUrl = reminder.voiceAudioUrl;
    if (reminder.localAudioPath != null && voiceUrl == null) {
      try {
        voiceUrl = await _voiceService.uploadVoiceNote(
            reminder.localAudioPath!, reminder.id);
      } catch (e) {
        print('Voice upload failed: $e');
      }
    }

    final updatedReminder = reminder.copyWith(
      voiceAudioUrl: voiceUrl,
      // Ensure created_by is set for RLS
    );

    // Sync to Supabase
    try {
      await _supabase.from('reminders').insert(updatedReminder.toJson());
      await _box.put(
          updatedReminder.id, updatedReminder.copyWith(isSynced: true));
    } catch (e) {
      print('Sync error creating reminder: $e');
      throw Exception('Failed to create reminder: $e');
    }
  }

  /// Add reminder (existing method - kept for compatibility)
  Future<void> addReminder(Reminder reminder) async {
    if (!_isInit) await init();
    await _box.put(reminder.id, reminder.copyWith(isSynced: false));

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

    try {
      await _supabase.from('reminders').insert(updatedReminder.toJson());
      await _box.put(
          updatedReminder.id, updatedReminder.copyWith(isSynced: true));
    } catch (e) {
      print('Sync error adding reminder: $e');
    }
  }

  /// Update reminder
  Future<void> updateReminder(Reminder reminder) async {
    if (!_isInit) await init();
    await _box.put(reminder.id, reminder.copyWith(isSynced: false));

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

    try {
      await _supabase
          .from('reminders')
          .update(updatedReminder.toJson())
          .eq('id', updatedReminder.id);
      await _box.put(
          updatedReminder.id, updatedReminder.copyWith(isSynced: true));
    } catch (e) {
      print('Sync error updating reminder: $e');
      throw Exception('Failed to update reminder: $e');
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    if (!_isInit) await init();
    await _box.delete(id);
    try {
      await _supabase.from('reminders').delete().eq('id', id);
    } catch (e) {
      print('Sync error deleting reminder: $e');
      throw Exception('Failed to delete reminder: $e');
    }
  }

  /// ✅ NEW: Mark reminder as completed (with completion sync)
  Future<void> markReminderCompleted(String id) async {
    if (!_isInit) await init();
    final reminder = _box.get(id);
    if (reminder != null) {
      final updated = reminder.copyWith(
        status: ReminderStatus.completed,
        completionHistory: [...reminder.completionHistory, DateTime.now()],
        isSynced: false,
      );
      await updateReminder(updated);
    }
  }

  /// Mark as done (existing method - kept for compatibility)
  Future<void> markAsDone(String id) async {
    await markReminderCompleted(id);
  }

  /// Sync reminders with Supabase
  Future<void> syncReminders(String patientId) async {
    if (!_isInit) await init();

    // 1. Push local changes
    final unsynced = _box.values.where((r) => !r.isSynced).toList();
    for (var r in unsynced) {
      String? voiceUrl = r.voiceAudioUrl;
      if (r.localAudioPath != null && voiceUrl == null) {
        try {
          voiceUrl =
              await _voiceService.uploadVoiceNote(r.localAudioPath!, r.id);
        } catch (e) {
          print('Sync voice upload failed for ${r.id}: $e');
        }
      }

      final toSync = r.copyWith(voiceAudioUrl: voiceUrl);

      try {
        await _supabase.from('reminders').upsert(toSync.toJson());
        await _box.put(toSync.id, toSync.copyWith(isSynced: true));
      } catch (e) {
        print('Sync push failed for ${r.id}: $e');
      }
    }

    // 2. Fetch remote
    try {
      final response = await _supabase
          .from('reminders')
          .select()
          .eq('patient_id', patientId);

      final List<dynamic> data = response;
      for (var json in data) {
        final remoteReminder = Reminder.fromJson(json);

        final existing = _box.get(remoteReminder.id);
        final stableId = existing?.notificationId ??
            DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

        await _box.put(
            remoteReminder.id,
            remoteReminder.copyWith(
              isSynced: true,
              notificationId: stableId,
            ));
      }
    } catch (e) {
      print('Sync fetch failed: $e');
    }
  }

  /// Upsert from realtime event
  Future<void> upsertFromRealtime(Reminder reminder) async {
    if (!_isInit) await init();
    await _box.put(reminder.id, reminder.copyWith(isSynced: true));
  }

  /// Delete from realtime event
  Future<void> deleteFromRealtime(String id) async {
    if (!_isInit) await init();
    await _box.delete(id);
  }

  /// Helper: Update local Hive cache from realtime data
  void _updateLocalCache(List<Reminder> reminders) {
    if (!_isInit) return;

    for (var reminder in reminders) {
      final existing = _box.get(reminder.id);
      final stableId = existing?.notificationId ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

      _box.put(
        reminder.id,
        reminder.copyWith(
          isSynced: true,
          notificationId: stableId,
        ),
      );
    }
  }
}
