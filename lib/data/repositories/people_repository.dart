import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/voice_service.dart';
import '../models/person.dart';

class PeopleRepository {
  final SupabaseClient _supabase;
  final VoiceService _voiceService;

  PeopleRepository(this._supabase, this._voiceService);

  Future<List<Person>> getPeople(String patientId) async {
    try {
      final data = await _supabase
          .from('people_cards')
          .select()
          .eq('patient_id', patientId);

      final people =
          (data as List).map((json) => Person.fromJson(json)).toList();
      return people;
    } catch (e) {
      print('Fetch people failed: $e');
      return [];
    }
  }

  Future<void> addPerson(Person person) async {
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

    final updatedPerson =
        person.copyWith(voiceAudioUrl: voiceUrl, photoUrl: photoUrl);

    try {
      await _supabase.from('people_cards').insert(updatedPerson.toJson());
    } catch (e) {
      print('Add person failed: $e');
      throw Exception('Database sync failed: $e');
    }
  }

  Future<void> updatePerson(Person person) async {
    String? voiceUrl = person.voiceAudioUrl;
    if (person.localAudioPath != null && voiceUrl == null) {
      voiceUrl = await _voiceService.uploadVoiceNote(
          person.localAudioPath!, person.id);
    }

    String? photoUrl = person.photoUrl;
    if (person.localPhotoPath != null && photoUrl == null) {
      photoUrl = await _uploadPhoto(person.localPhotoPath!, person.id);
    }

    final updatedPerson =
        person.copyWith(voiceAudioUrl: voiceUrl, photoUrl: photoUrl);

    try {
      await _supabase
          .from('people_cards')
          .update(updatedPerson.toJson())
          .eq('id', person.id);
    } catch (e) {
      print('Update person failed: $e');
      throw Exception('Database update failed: $e');
    }
  }

  Future<void> deletePerson(String id) async {
    try {
      await _supabase.from('people_cards').delete().eq('id', id);
    } catch (e) {
      print('Delete person failed: $e');
      throw Exception('Delete failed: $e');
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
}
