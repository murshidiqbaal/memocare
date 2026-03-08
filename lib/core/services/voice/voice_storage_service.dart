import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles uploading/deleting voice note files in Supabase Storage.
/// Bucket name: `voice-notes`  (create it in Supabase dashboard → Storage)
class VoiceStorageService {
  final SupabaseClient _client;
  static const _bucket = 'voice-notes';

  VoiceStorageService(this._client);

  /// Upload a local .m4a file and return its public URL.
  /// [reminderId] is used to namespace the file path.
  Future<String?> uploadVoiceNote({
    required String localPath,
    required String reminderId,
    required String userId,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        debugPrint('VoiceStorageService: file not found at $localPath');
        return null;
      }

      // e.g.  user_abc/reminder_xyz_1720000000.m4a
      final storagePath =
          '$userId/reminder_${reminderId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _client.storage.from(_bucket).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(contentType: 'audio/mp4'),
          );

      final publicUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);
      debugPrint('VoiceStorageService: uploaded → $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('VoiceStorageService upload error: $e');
      return null;
    }
  }

  /// Delete a previously uploaded file using its public URL.
  Future<void> deleteByUrl(String publicUrl) async {
    try {
      // Extract storage path from the public URL
      // URL format: .../storage/v1/object/public/<bucket>/<path>
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_bucket);
      if (bucketIndex == -1) return;

      final storagePath = segments.sublist(bucketIndex + 1).join('/');
      await _client.storage.from(_bucket).remove([storagePath]);
      debugPrint('VoiceStorageService: deleted $storagePath');
    } catch (e) {
      debugPrint('VoiceStorageService delete error: $e');
    }
  }
}
