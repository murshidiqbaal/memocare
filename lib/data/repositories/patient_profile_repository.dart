import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_profile.dart';

class PatientProfileRepository {
  final SupabaseClient _supabase;
  final Box<PatientProfile> _profileBox;

  PatientProfileRepository(this._supabase, this._profileBox);

  /// Get profile with offline-first logic
  Future<PatientProfile?> getProfile(String userId) async {
    // 1. Try local first for instant UI
    final cached = _profileBox.get(userId);

    try {
      // 2. Fetch from both tables
      // A. Get base profile (full_name, phone_number)
      final profileResponse = await _supabase
          .from('profiles')
          .select('full_name, phone_number')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        return cached; // User doesn't exist
      }

      // B. Get patient-specific data
      final patientResponse = await _supabase
          .from('patients')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      // 3. Merge the data
      final Map<String, dynamic> mergedData = {
        'id': userId,
        'full_name': profileResponse['full_name'] ?? 'Patient',
        'phone_number': profileResponse['phone_number'],
      };

      // Add patient-specific fields if they exist
      if (patientResponse != null) {
        mergedData.addAll(patientResponse);
        // Ensure id is preserved
        mergedData['id'] = userId;
      }

      final remoteProfile = PatientProfile.fromJson(mergedData);

      // 4. Cache it
      await _profileBox.put(userId, remoteProfile);
      return remoteProfile;
    } catch (e) {
      // If offline or error, return cached
      print('Profile fetch error: $e');
      return cached;
    }
  }

  /// Update profile with sync logic
  Future<void> updateProfile(PatientProfile profile) async {
    // 1. Save locally first (Optimistic)
    await _profileBox.put(profile.id, profile.copyWith(isSynced: false));

    try {
      // 2. Push to Supabase (Split updates)

      // A. Update 'patients' table with patient-specific fields
      final patientData = {
        'id': profile.id,
        'date_of_birth': profile.dateOfBirth?.toIso8601String(),
        'gender': profile.gender,
        'medical_notes': profile.medicalNotes,
        'emergency_contact_name': profile.emergencyContactName,
        'emergency_contact_phone': profile.emergencyContactPhone,
        'profile_photo_url': profile.profileImageUrl,
      };

      // Remove null values to avoid overwriting with nulls
      patientData.removeWhere((key, value) => value == null);

      // Upsert on patients table
      final patientFuture = _supabase.from('patients').upsert(patientData);

      // B. Update 'profiles' (base) table
      final profileData = {
        'id': profile.id,
        'full_name': profile.fullName,
        'phone_number': profile.phoneNumber,
      };

      final profileFuture =
          _supabase.from('profiles').update(profileData).eq('id', profile.id);

      // Run parallel
      await Future.wait([patientFuture, profileFuture]);

      // 3. Mark as synced
      await _profileBox.put(profile.id, profile.copyWith(isSynced: true));
    } catch (e) {
      // Remain unsynced but local is updated
      print('Profile update error (offline?): $e');
      rethrow; // Re-throw to let UI handle error
    }
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(String userId, File file) async {
    final fileName = 'avatar_$userId.jpg';
    final path = 'avatars/$fileName';

    try {
      await _supabase.storage.from('patient-avatars').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl =
          _supabase.storage.from('patient-avatars').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  /// Sync all unsynced profiles
  Future<void> syncPendingProfiles() async {
    final unsynced = _profileBox.values.where((p) => !p.isSynced).toList();
    for (var profile in unsynced) {
      try {
        await updateProfile(profile);
      } catch (e) {
        debugPrint('Failed to sync profile ${profile.id}: $e');
      }
    }
  }
}
