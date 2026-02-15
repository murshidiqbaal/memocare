import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver.dart';

class CaregiverRepository {
  final SupabaseClient _supabase;

  CaregiverRepository(this._supabase);

  /// Fetch Current Caregiver Profile
  Future<Caregiver?> getMyCaregiverProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Cannot join auth.users directly.
      // Removed 'profiles:user_id(full_name)' as it causes PGRST200
      // Update table name to 'caregiver_profiles'
      final data = await _supabase
          .from('caregiver_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) return null;

      // Optionally fetch name from user metadata if needed
      final fullName = user.userMetadata?['full_name'] as String?;

      final Map<String, dynamic> mergedData = {
        ...data,
        'fullName': fullName, // Inject manual name fetch
      };

      return Caregiver.fromJson(mergedData);
    } catch (e) {
      throw Exception('Failed to fetch caregiver profile: $e');
    }
  }

  /// Update or Insert Caregiver Profile
  Future<void> upsertCaregiverProfile(Caregiver caregiver) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = {
        'user_id': user.id,
        'phone': caregiver.phone,
        'relationship': caregiver.relationship,
        'notification_enabled': caregiver.notificationEnabled,
        'profile_photo_url': caregiver.profilePhotoUrl,
      };

      // Perform upsert on caregiver_profiles table based on user_id
      await _supabase.from('caregiver_profiles').upsert(
            data,
            onConflict: 'user_id',
          );
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  /// Upload Profile Photo to Supabase Storage
  Future<String> uploadProfilePhoto(File file) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final fileExt = file.path.split('.').last;
      final fileName =
          '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'caregiver-avatars/$fileName';

      await _supabase.storage.from('caregiver-avatars').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl =
          _supabase.storage.from('caregiver-avatars').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }
}
