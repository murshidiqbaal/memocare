import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePhotoRepository {
  final SupabaseClient _supabase;

  ProfilePhotoRepository(this._supabase);

  /// Uploads a profile photo for a user based on their role.
  ///
  /// Returns the public URL of the uploaded image.
  Future<String> uploadProfilePhoto({
    required String userId,
    required File file,
    required String role, // 'patient' or 'caregiver'
  }) async {
    try {
      // 1. Determine folder path
      // Bucket: profile-photos
      // Folder paths:
      // Patient: patients/{userId}/profile.jpg
      // Caregiver: caregivers/{userId}/profile.jpg

      final folder = role == 'patient' ? 'patients' : 'caregivers';

      // Standardize path to profile.jpg within the ID folder
      final path = '$folder/$userId/profile.jpg';

      // 2. Upload to Storage
      await _supabase.storage.from('profile-photos').upload(
            path,
            file,
            fileOptions: const FileOptions(
              upsert: true, // Overwrite existing
              contentType: 'image/jpeg',
            ),
          );

      // 3. Get Public URL using SDK
      final publicUrl =
          _supabase.storage.from('profile-photos').getPublicUrl(path);

      // 4. Update Database based on role
      if (role == 'patient') {
        // Update patients table
        await _supabase.from('patients').upsert({
          'id': userId,
          'profile_photo_url': publicUrl,
        });
      } else if (role == 'caregiver') {
        // Update profiles table
        await _supabase
            .from('profiles')
            .update({
              'profile_photo_url': publicUrl,
            })
            .eq('user_id', userId)
            .eq('role', 'caregiver');
      }

      // Return with timestamp to bust cache in UI immediately
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }
}
