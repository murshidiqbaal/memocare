import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/voice_service.dart';
import '../models/memory.dart';

class MemoryRepository {
  final SupabaseClient _supabase;
  final VoiceService _voiceService;

  MemoryRepository(this._supabase, this._voiceService);

  /// Defensive payload builder to prevent Postgres 22P02 (empty string UUIDs)
  Map<String, dynamic> _buildSafePayload(Memory memory) {
    final payload = memory.toJson();

    // 1. Guard against empty ID
    final safeId = memory.id.trim();
    if (safeId.isEmpty) {
      throw Exception('Critical Error: Memory ID cannot be blank');
    }
    payload['id'] = safeId;

    // 2. Guard against empty Patient ID (common cause of 22P02)
    final safePatientId = memory.patientId.trim();
    if (safePatientId.isEmpty) {
      throw Exception(
          'Upload blocked: Patient ID is empty. Please ensure you have selected a valid patient.');
    }
    payload['patient_id'] = safePatientId;

    return payload;
  }

  Future<List<Memory>> getMemories(String patientId) async {
    try {
      final data = await _supabase
          .from('memory_cards')
          .select()
          .eq('patient_id', patientId)
          .order('event_date', ascending: false);

      return (data as List)
          .map((m) => Memory.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Fetch memories failed: $e');
      return [];
    }
  }

  Future<void> addMemory(Memory memory) async {
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

    final updatedMemory =
        memory.copyWith(voiceAudioUrl: voiceUrl, imageUrl: photoUrl);

    try {
      final safePayload = _buildSafePayload(updatedMemory);
      await _supabase.from('memory_cards').insert(safePayload);
    } catch (e) {
      print('Add memory failed: $e');
      throw Exception('Database sync failed: $e');
    }
  }

  Future<void> updateMemory(Memory memory) async {
    String? voiceUrl = memory.voiceAudioUrl;
    if (memory.localAudioPath != null && voiceUrl == null) {
      voiceUrl = await _voiceService.uploadVoiceNote(
          memory.localAudioPath!, memory.id);
    }

    String? photoUrl = memory.imageUrl;
    if (memory.localPhotoPath != null && photoUrl == null) {
      photoUrl = await _uploadImage(memory.localPhotoPath!, memory.id);
    }

    final updatedMemory =
        memory.copyWith(voiceAudioUrl: voiceUrl, imageUrl: photoUrl);

    try {
      final safePayload = _buildSafePayload(updatedMemory);
      await _supabase
          .from('memory_cards')
          .update(safePayload)
          .eq('id', safePayload['id']);
    } catch (e) {
      print('Update memory failed: $e');
      throw Exception('Database update failed: $e');
    }
  }

  Future<void> deleteMemory(Memory memory) async {
    try {
      // 1. Delete associated images and audio from storage
      if (memory.imageUrl != null) {
        try {
          final uri = Uri.parse(memory.imageUrl!);
          final fileName = uri.pathSegments.last;
          await _supabase.storage.from('memory-photos').remove([fileName]);
        } catch (e) {
          print('Failed to delete photo from storage: $e');
        }
      }

      if (memory.voiceAudioUrl != null) {
        try {
          final uri = Uri.parse(memory.voiceAudioUrl!);
          final fileName = uri.pathSegments.last;
          await _supabase.storage.from('voice-notes').remove([fileName]);
        } catch (e) {
          print('Failed to delete voice note from storage: $e');
        }
      }

      // 2. Delete memory metadata from database
      await _supabase.from('memory_cards').delete().eq('id', memory.id);
    } catch (e) {
      print('Delete memory failed: $e');
      throw Exception('Failed to delete memory: $e');
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
}
