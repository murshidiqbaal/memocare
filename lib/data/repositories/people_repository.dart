import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/voice_service.dart';
import '../models/person.dart';

class PeopleRepository {
  final SupabaseClient _supabase;
  final VoiceService _voiceService;
  late Box<Person> _box;
  bool _isInit = false;

  PeopleRepository(this._supabase, this._voiceService);

  Future<void> init() async {
    if (_isInit) return;
    _box = await Hive.openBox<Person>('people');
    _isInit = true;
  }

  List<Person> getPeople(String patientId) {
    if (!_isInit) return [];
    return _box.values.where((p) => p.patientId == patientId).toList();
  }

  Future<void> addPerson(Person person) async {
    await _box.put(person.id, person.copyWith(isSynced: false));

    // Upload voice if needed
    String? voiceUrl = person.voiceAudioUrl;
    if (person.localAudioPath != null && voiceUrl == null) {
      voiceUrl = await _voiceService.uploadVoiceNote(
          person.localAudioPath!, person.id);
    }

    // Upload Photo if needed (basic implementation)
    String? photoUrl = person.photoUrl;
    if (person.localPhotoPath != null && photoUrl == null) {
      photoUrl = await _uploadPhoto(person.localPhotoPath!, person.id);
    }

    final updatedPerson = person.copyWith(
        voiceAudioUrl: voiceUrl, photoUrl: photoUrl, isSynced: true);

    try {
      await _supabase.from('people_cards').insert(updatedPerson.toJson());
      await _box.put(updatedPerson.id, updatedPerson);
    } catch (e) {
      print('Sync add person failed: $e');
      // Revert sync status locally
      await _box.put(
          person.id,
          person.copyWith(
              voiceAudioUrl: voiceUrl, photoUrl: photoUrl, isSynced: false));
    }
  }

  Future<void> updatePerson(Person person) async {
    // Similar logic to addPerson, handling updates
    await _box.put(person.id, person.copyWith(isSynced: false));

    String? voiceUrl = person.voiceAudioUrl;
    if (person.localAudioPath != null && voiceUrl == null) {
      voiceUrl = await _voiceService.uploadVoiceNote(
          person.localAudioPath!, person.id);
    }

    String? photoUrl = person.photoUrl;
    if (person.localPhotoPath != null) {
      // If local path exists, always try to upload if we don't have a URL matching it?
      // Or assume if local path provided during edit, it's new.
      // For simplicity, if photoUrl is null or different?
      // We'll trust the caller to clear photoUrl if replacing.
      if (photoUrl == null) {
        photoUrl = await _uploadPhoto(person.localPhotoPath!, person.id);
      }
    }

    final updatedPerson = person.copyWith(
        voiceAudioUrl: voiceUrl, photoUrl: photoUrl, isSynced: true);

    try {
      await _supabase
          .from('people_cards')
          .update(updatedPerson.toJson())
          .eq('id', person.id);
      await _box.put(updatedPerson.id, updatedPerson);
    } catch (e) {
      print('Sync update person failed: $e');
      await _box.put(
          person.id,
          person.copyWith(
              voiceAudioUrl: voiceUrl, photoUrl: photoUrl, isSynced: false));
    }
  }

  Future<void> deletePerson(String id) async {
    await _box.delete(id);
    try {
      await _supabase.from('people_cards').delete().eq('id', id);
    } catch (e) {
      print('Sync delete person failed: $e');
    }
  }

  Future<String?> _uploadPhoto(String path, String id) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final ext = path.split('.').last;
      final name = '${id}_photo.$ext';
      await _supabase.storage
          .from('people_photos')
          .upload(name, file, fileOptions: const FileOptions(upsert: true));
      return _supabase.storage.from('people_photos').getPublicUrl(name);
    } catch (e) {
      print('Photo upload failed: $e');
      return null;
    }
  }

  Future<void> syncPeople(String patientId) async {
    await init();
    // Push local
    final unsynced = _box.values.where((p) => !p.isSynced);
    for (var p in unsynced) {
      // Retry uploads if needed
      await updatePerson(p);
    }

    // Pull remote
    try {
      final data = await _supabase
          .from('people_cards')
          .select()
          .eq('patient_id', patientId);
      for (var map in data) {
        final remote = Person.fromJson(map);
        await _box.put(remote.id, remote.copyWith(isSynced: true));
      }
    } catch (e) {
      print('Sync pull people failed: $e');
    }
  }
}
