import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/voice_service.dart';
import '../models/memory.dart';

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

  /// Exposes the local Hive box for direct cache writes (used by ViewModel)
  Box<Memory> get localBox {
    if (!_isInit) throw StateError('MemoryRepository not initialized');
    return _box;
  }

  List<Memory> getMemories(String patientId) {
    if (!_isInit) return [];
    return _box.values.where((m) => m.patientId == patientId).toList()
      ..sort(
          (a, b) => b.eventDate?.compareTo(a.eventDate ?? DateTime.now()) ?? 0);
  }

  /// Defensive payload builder to prevent Postgres 22P02 (empty string UUIDs)
  Map<String, dynamic> _buildSafePayload(Memory memory) {
    final payload = memory.toJson();

    // 1. Guard against empty ID
    final safeId = memory.id.trim();
    if (safeId.isEmpty)
      throw Exception('Critical Error: Memory ID cannot be blank');
    payload['id'] = safeId;

    // 2. Guard against empty Patient ID (common cause of 22P02)
    final safePatientId = memory.patientId.trim();
    if (safePatientId.isEmpty) {
      throw Exception(
          'Upload blocked: Patient ID is empty. Please ensure you have selected a valid patient.');
    }
    payload['patient_id'] = safePatientId;

    // 3. Optional: Defend any other potential UUID fields like 'created_by' turning "" into null
    // final user = _supabase.auth.currentUser;
    // payload['created_by'] = user?.id;

    return payload;
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
      final safePayload = _buildSafePayload(updatedMemory);
      await _supabase.from('memory_cards').insert(safePayload);
      await _box.put(updatedMemory.id, updatedMemory);
    } catch (e) {
      print('Sync add memory failed: $e');
      await _box.put(
          memory.id,
          memory.copyWith(
              voiceAudioUrl: voiceUrl, imageUrl: photoUrl, isSynced: false));
      // Throw error to propagate to ViewModel -> UI
      throw Exception('Database sync failed: $e');
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
      final safePayload = _buildSafePayload(updatedMemory);
      await _supabase
          .from('memory_cards')
          .update(safePayload)
          .eq('id', safePayload['id']);
      await _box.put(updatedMemory.id, updatedMemory);
    } catch (e) {
      print('Sync update memory failed: $e');
      await _box.put(
          memory.id,
          memory.copyWith(
              voiceAudioUrl: voiceUrl, imageUrl: photoUrl, isSynced: false));
      throw Exception('Database update failed: $e');
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
          .from('memory-photos')
          .upload(name, file, fileOptions: const FileOptions(upsert: true));
      return _supabase.storage.from('memory-photos').getPublicUrl(name);
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
