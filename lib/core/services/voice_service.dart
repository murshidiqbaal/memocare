import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceService {
  final SupabaseClient _supabase;

  VoiceService(this._supabase);

  /// Uploads a voice note to Supabase Storage and returns the public URL.
  /// Includes retry logic for better reliability.
  Future<String?> uploadVoiceNote(String filePath, String reminderId,
      {int maxRetries = 3}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      print('Voice note file not found at: $filePath');
      return null;
    }

    final fileExt = filePath.split('.').last;
    final fileName = '${reminderId}_voice.$fileExt';

    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        await _supabase.storage.from('voice_reminders').upload(
              fileName,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

        // Get public URL
        return _supabase.storage.from('voice_reminders').getPublicUrl(fileName);
      } catch (e) {
        attempt++;
        print('Upload attempt $attempt failed: $e');
        if (attempt >= maxRetries) {
          print('Max retries reached for voice note upload.');
          return null;
        }
        // Wait a bit before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return null;
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
