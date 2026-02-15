import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceService {
  final SupabaseClient _supabase;

  VoiceService(this._supabase);

  /// Uploads a voice note to Supabase Storage and returns the public URL.
  /// Returns null if upload fails.
  Future<String?> uploadVoiceNote(String filePath, String reminderId) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Voice note file not found at: $filePath');
        return null;
      }

      final fileExt = filePath.split('.').last;
      final fileName = '${reminderId}_voice.$fileExt';
      // Using reminderId_voice to avoid folders if possible, or use folders based on preference.
      // User asked for "bucket voice-reminders".
      // Let's use a flat structure or patientId folder?
      // The instruction didn't specify folder structure. Flat is safer for now.

      try {
        await _supabase.storage.from('voice_reminders').upload(fileName, file,
            fileOptions: const FileOptions(upsert: true));
      } catch (uploadError) {
        print('Upload API error: $uploadError');
        // If it fails, maybe check if we need to create bucket?
        // We assume bucket exists.
        return null;
      }

      // Get public URL
      final publicUrl =
          _supabase.storage.from('voice_reminders').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error processing voice note upload: $e');
      return null;
    }
  }

  /// Deletes a voice note from Supabase Storage
  Future<void> deleteVoiceNote(String url) async {
    try {
      // Extract file name from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      // Usually path ends with bucket/filename
      // e.g. .../storage/v1/object/public/voice_reminders/filename.m4a
      final fileName = pathSegments.last;

      await _supabase.storage.from('voice_reminders').remove([fileName]);
    } catch (e) {
      print('Error deleting voice note: $e');
    }
  }
}
