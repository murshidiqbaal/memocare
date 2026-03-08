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
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .eq('role', 'caregiver')
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
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .eq('role', 'caregiver')
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      // 2. Automatically create a profile row if missing
      final fullName =
          user.userMetadata?['full_name'] as String? ?? 'Caregiver';
      final response = await _supabase
          .from('profiles')
          .insert({
            'user_id': user.id,
            'full_name': fullName,
            'role': 'caregiver',
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to ensure caregiver profile: $e');
    }
  }

  /// Update or Insert Caregiver Profile using user_id as the unique key
  Future<void> upsertCaregiverProfile(Caregiver caregiver) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = {
        'user_id': user.id,
        'phone_number': caregiver.phone,
        'relationship': caregiver.relationship,
        'notification_enabled': caregiver.notificationEnabled,
        'profile_photo_url': caregiver.profilePhotoUrl,
        'role': 'caregiver',
      };

      // Add ID if it exists (for explicit updates)
      if (caregiver.id != null && caregiver.id!.isNotEmpty) {
        data['id'] = caregiver.id!;
      }

      await _supabase.from('profiles').upsert(
            data,
            onConflict: 'user_id, role',
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

      final filePath = 'caregivers/${user.id}/profile.jpg';

      await _supabase.storage.from('profile-photos').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl =
          _supabase.storage.from('profile-photos').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }
}
