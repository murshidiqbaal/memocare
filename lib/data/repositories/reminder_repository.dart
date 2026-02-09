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
    // Adapters are registered in main.dart usually, but we can check here
    // However, Hive initialization is async and best done at app start.
    // Assuming generated adapters are registered.
    _box = await Hive.openBox<Reminder>('reminders');
    _isInit = true;
  }

  List<Reminder> getReminders(String patientId) {
    if (!_isInit) return [];
    return _box.values.where((r) => r.patientId == patientId).toList()
      ..sort((a, b) => a.remindAt.compareTo(b.remindAt));
  }

  Future<void> addReminder(Reminder reminder) async {
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
    await _box.delete(id);
    try {
      await _supabase.from('reminders').delete().eq('id', id);
    } catch (e) {
      print('Sync error deleting reminder: $e');
      // Store in a "pending_deletions" box if strictly robust offline delete needed
    }
  }

  Future<void> markAsDone(String id) async {
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
        // Local might have newer unsynced changes?
        // Strategy: "Server Wins" for conflict or "Last Write Wins" based on timestamps.
        // For now, simpler: Accept server state as truth for sync pass.
        await _box.put(
            remoteReminder.id, remoteReminder.copyWith(isSynced: true));
      }
    } catch (e) {
      print('Sync fetch failed: $e');
    }
  }
}
