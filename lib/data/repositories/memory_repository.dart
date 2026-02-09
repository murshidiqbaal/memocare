import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/memory.dart';
import '../../services/voice_service.dart';

class MemoryRepository {
  final SupabaseClient _supabase;
  final VoiceService _voiceService;
  late Box<Memory> _box;
  bool _isInit = false;

  MemoryRepository(this._supabase, this._voiceService);

  Future<void> init() async {
    if (_isInit) return;
    _box = await Hive.openBox<Memory>('memories');
    _isInit = true;
  }

  List<Memory> getMemories(String patientId) {
    if (!_isInit) return [];
    return _box.values.where((m) => m.patientId == patientId).toList()
      ..sort(
          (a, b) => b.eventDate?.compareTo(a.eventDate ?? DateTime.now()) ?? 0);
  }

  Future<void> addMemory(Memory memory) async {
    await _box.put(memory.id, memory.copyWith(isSynced: false));

    // Upload voice if needed
    String? voiceUrl = memory.voiceAudioUrl;
    if (memory.localAudioPath != null && voiceUrl == null) {
      voiceUrl = await _voiceService.uploadVoiceNote(
          memory.localAudioPath!, memory.id);
    }

    // Upload Photo if needed
    String? photoUrl = memory.imageUrl;
    if (memory.localPhotoPath != null && photoUrl == null) {
      photoUrl = await _uploadImage(memory.localPhotoPath!, memory.id);
    }

    final updatedMemory = memory.copyWith(
        voiceAudioUrl: voiceUrl, imageUrl: photoUrl, isSynced: true);

    try {
      await _supabase.from('memory_cards').insert(updatedMemory.toJson());
      await _box.put(updatedMemory.id, updatedMemory);
    } catch (e) {
      print('Sync add memory failed: $e');
      await _box.put(
          memory.id,
          memory.copyWith(
              voiceAudioUrl: voiceUrl, imageUrl: photoUrl, isSynced: false));
    }
  }

  Future<void> updateMemory(Memory memory) async {
    await _box.put(memory.id, memory.copyWith(isSynced: false));

    String? voiceUrl = memory.voiceAudioUrl;
    if (memory.localAudioPath != null && voiceUrl == null) {
      voiceUrl = await _voiceService.uploadVoiceNote(
          memory.localAudioPath!, memory.id);
    }

    String? photoUrl = memory.imageUrl;
    if (memory.localPhotoPath != null && photoUrl == null) {
      photoUrl = await _uploadImage(memory.localPhotoPath!, memory.id);
    }

    final updatedMemory = memory.copyWith(
        voiceAudioUrl: voiceUrl, imageUrl: photoUrl, isSynced: true);

    try {
      await _supabase
          .from('memory_cards')
          .update(updatedMemory.toJson())
          .eq('id', memory.id);
      await _box.put(updatedMemory.id, updatedMemory);
    } catch (e) {
      print('Sync update memory failed: $e');
      await _box.put(
          memory.id,
          memory.copyWith(
              voiceAudioUrl: voiceUrl, imageUrl: photoUrl, isSynced: false));
    }
  }

  Future<void> deleteMemory(String id) async {
    await _box.delete(id);
    try {
      await _supabase.from('memory_cards').delete().eq('id', id);
    } catch (e) {
      print('Sync delete memory failed: $e');
    }
  }

  Future<String?> _uploadImage(String path, String id) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final ext = path.split('.').last;
      final name = '${id}_memory.$ext';
      await _supabase.storage
          .from('memory_photos')
          .upload(name, file, fileOptions: const FileOptions(upsert: true));
      return _supabase.storage.from('memory_photos').getPublicUrl(name);
    } catch (e) {
      print('Memory image upload failed: $e');
      return null;
    }
  }

  Future<void> syncMemories(String patientId) async {
    await init();
    // Push local
    final unsynced = _box.values.where((m) => !m.isSynced);
    for (var m in unsynced) {
      // Retry uploads
      await updateMemory(m);
    }

    // Pull remote
    try {
      final data = await _supabase
          .from('memory_cards')
          .select()
          .eq('patient_id', patientId);
      for (var map in data) {
        final remote = Memory.fromJson(map);
        await _box.put(remote.id, remote.copyWith(isSynced: true));
      }
    } catch (e) {
      print('Sync pull memories failed: $e');
    }
  }
}
