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

      // Using a fixed name 'profile.jpg' to simplify overwrite updates
      // Alternatively, use timestamp but requires deleting old one.
      // Based on prompt: "patients/{userId}/profile.jpg"
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

      // 3. Get Public URL
      final publicUrl =
          _supabase.storage.from('profile-photos').getPublicUrl(path);

      // Add timestamp tobust cache immediately for UI
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueUrl = '$publicUrl?t=$timestamp';

      // 4. Update Database based on role
      if (role == 'patient') {
        // Update patients table
        await _supabase.from('patients').upsert({
          'id': userId,
          'profile_photo_url': uniqueUrl,
        });
      } else if (role == 'caregiver') {
        // Update caregiver_profiles table (using role-based check)
        // Ensure table name is correct. In `caregiver_repository`, it was 'caregiver_profiles'.
        // Assuming unique constraint on user_id.
        await _supabase.from('caregiver_profiles').upsert({
          'user_id': userId, // Depending on schema, might be ID or user_id
          'profile_photo_url': uniqueUrl,
        }, onConflict: 'user_id'); // If using user_id as unique key

        // Wait, normally `id` is PK? caregiver_profiles likely has `user_id`.
        // Let's verify schema from `caregiver_repository` access:
        // .eq('user_id', user.id) -> yes.
      }

      return uniqueUrl;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }
}
