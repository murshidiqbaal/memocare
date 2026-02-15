import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/voice_service.dart';
import '../models/reminder.dart';

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

  List<Reminder> getReminders(String patientId) {
    if (!_isInit) {
      print('ReminderRepository not initialized');
      return [];
    }
    final all = _box.values.toList();
    final unique = all.toSet().toList(); // Dedup just in case
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

  Future<void> addReminder(Reminder reminder) async {
    if (!_isInit) await init();
    // Save to Hive first (Offline-first)
    await _box.put(reminder.id, reminder.copyWith(isSynced: false));

    // Try to upload audio if local path exists and needs upload
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

    // Try to sync immediately
    try {
      await _supabase.from('reminders').insert(updatedReminder.toJson());
      await _box.put(
          updatedReminder.id, updatedReminder.copyWith(isSynced: true));
    } catch (e) {
      // Ignore error, will sync later
      print('Sync error adding reminder: $e');
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    if (!_isInit) await init();
    await _box.put(reminder.id, reminder.copyWith(isSynced: false));

    // Try to upload audio if changed
    String? voiceUrl = reminder.voiceAudioUrl;
    if (reminder.localAudioPath != null) {
      // Logic to detect if upload needed?
      // For now, if voiceUrl is null but local path exists, upload.
      if (voiceUrl == null) {
        try {
          voiceUrl = await _voiceService.uploadVoiceNote(
              reminder.localAudioPath!, reminder.id);
        } catch (e) {
          print('Voice upload failed: $e');
        }
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
    }
  }

  Future<void> deleteReminder(String id) async {
    if (!_isInit) await init();
    await _box.delete(id);
    try {
      await _supabase.from('reminders').delete().eq('id', id);
    } catch (e) {
      print('Sync error deleting reminder: $e');
      // Store in a "pending_deletions" box if strictly robust offline delete needed
    }
  }

  Future<void> markAsDone(String id) async {
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

  Future<void> syncReminders(String patientId) async {
    if (!_isInit) await init();

    // 1. Push local changes
    final unsynced = _box.values.where((r) => !r.isSynced).toList();
    for (var r in unsynced) {
      // Logic to sync voice upload if needed
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
        // Checking if exists to decide upsert? Upsert defaults to insert/update based on PK.
        // Assuming Supabase 'reminders' table has 'id' as primary key.
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

        // Preserve local notification ID or generate new
        final existing = _box.get(remoteReminder.id);
        final stableId = existing?.notificationId ??
            DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

        // Strategy: "Server Wins" for conflict or "Last Write Wins" based on timestamps.
        // For now, simpler: Accept server state as truth for sync pass but keep stable ID.
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
}
