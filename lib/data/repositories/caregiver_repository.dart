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

      final data = await _supabase
          .from('caregiver_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) return null;

      final fullName = user.userMetadata?['full_name'] as String?;

      final Map<String, dynamic> mergedData = {
        ...data,
        'fullName': fullName,
      };

      return Caregiver.fromJson(mergedData);
    } catch (e) {
      throw Exception('Failed to fetch caregiver profile: $e');
    }
  }

  /// Ensures a caregiver profile row exists for the current user.
  /// This is crucial for avoiding FK errors when linking patients.
  Future<String> ensureProfileExists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 1. Check for existing profile by user_id
      final existing = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      // 2. Automatically create a profile row if missing
      final fullName =
          user.userMetadata?['full_name'] as String? ?? 'Caregiver';
      final response = await _supabase
          .from('caregiver_profiles')
          .insert({
            'user_id': user.id,
            'full_name': fullName,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to ensure caregiver profile: $e');
    }
  }

  /// Update or Insert Caregiver Profile
  Future<void> upsertCaregiverProfile(Caregiver caregiver) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Get existing id or create one
      final profileId = await ensureProfileExists();

      final data = {
        'id': profileId,
        'user_id': user.id,
        'phone': caregiver.phone,
        'relationship': caregiver.relationship,
        'notification_enabled': caregiver.notificationEnabled,
        'profile_photo_url': caregiver.profilePhotoUrl,
      };

      await _supabase.from('caregiver_profiles').upsert(
            data,
            onConflict: 'id',
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
