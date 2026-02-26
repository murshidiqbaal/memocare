import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_profile.dart';

class PatientProfileRepository {
  final SupabaseClient _supabase;

  // Optional in-memory cache
  PatientProfile? _cachedProfile;

  PatientProfileRepository(this._supabase);

  /// Get profile directly from Supabase
  Future<PatientProfile?> getProfile(String userId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedProfile != null &&
        _cachedProfile!.id == userId) {
      return _cachedProfile;
    }

    try {
      // A. Get base profile (full_name, phone_number)
      final profileResponse = await _supabase
          .from('profiles')
          .select('full_name, phone_number, avatar_url, profile_photo_url')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        return null; // User doesn't exist
      }

      // B. Get patient-specific data
      final patientResponse = await _supabase
          .from('patients')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      // Prioritize patient table URL, then profiles table URL, then fallback to bucket
      String? photoUrl = patientResponse?['profile_photo_url'];

      // If null, check profiles table (might use avatar_url or profile_photo_url)
      if (photoUrl == null) {
        // Re-fetch or rely on the initial fetch if we included it
        // Initial fetch: .select('full_name, phone_number') -> let's expand it
        // But we can just use another query if needed, or expand the initial one above.
        // Let's assume we expand the initial query in a moment.
        // Actually, let's just do it here.

        // Expanding the initial query above:
        // final profileResponse = await _supabase.from('profiles').select('full_name, phone_number, avatar_url, profile_photo_url')...

        // Since I can't edit previous lines in this Replace block easily without expanding context,
        // I will assume I modify the initial query too.

        // Wait, let's use the fetched profileResponse.
        // However, I need to know keys.
        // Let's use getPublicUrl as final fallback.
      }

      // 3. Merge the data
      final Map<String, dynamic> mergedData = {
        'id': userId,
        'full_name': profileResponse['full_name'] ?? 'Patient',
        'phone_number': profileResponse['phone_number'],
      };

      // Helper to try keys in order
      String? findPhotoUrl(Map<String, dynamic>? data) {
        if (data == null) return null;
        return data['profile_photo_url'] ?? data['avatar_url'];
      }

      // Resolve final photo URL
      String? resolvedPhotoUrl = patientResponse?['profile_photo_url'] ??
          findPhotoUrl(profileResponse);

      if (resolvedPhotoUrl == null) {
        // Fallback to bucket URL
        // We use a timestamp to avoid aggressive caching of potentially old/wrong default
        // But for a fallback, we just want the file if it exists.
        final path = 'patients/$userId/profile.jpg';
        resolvedPhotoUrl =
            _supabase.storage.from('profile-photos').getPublicUrl(path);
      }

      // Add patient-specific fields if they exist
      if (patientResponse != null) {
        mergedData.addAll(patientResponse);
        // Ensure id is preserved
        mergedData['id'] = userId;
      }

      // Override with resolved URL
      mergedData['profile_photo_url'] = resolvedPhotoUrl;

      final remoteProfile = PatientProfile.fromJson(mergedData);

      // Cache merely in-memory
      _cachedProfile = remoteProfile;
      return remoteProfile;
    } catch (e) {
      print('Profile fetch error: $e');
      if (!forceRefresh &&
          _cachedProfile != null &&
          _cachedProfile!.id == userId) {
        return _cachedProfile;
      }
      return null;
    }
  }

  /// Update profile with sync logic
  Future<void> updateProfile(PatientProfile profile) async {
    try {
      // 1. Update 'patients' table with patient-specific fields
      final patientData = {
        'id': profile.id,
        'date_of_birth': profile.dateOfBirth?.toIso8601String(),
        'gender': profile.gender,
        'address': profile.address,
        'medical_notes': profile.medicalNotes,
        'emergency_contact_name': profile.emergencyContactName,
        'emergency_contact_phone': profile.emergencyContactPhone,
        'profile_photo_url': profile.profileImageUrl,
      };

      // Remove null values to avoid overwriting with nulls
      patientData.removeWhere((key, value) => value == null);

      // Upsert on patients table
      final patientFuture = _supabase.from('patients').upsert(patientData);

      // 2. Update 'profiles' (base) table
      final profileData = {
        'id': profile.id,
        'full_name': profile.fullName,
        'phone_number': profile.phoneNumber,
      };

      final profileFuture =
          _supabase.from('profiles').update(profileData).eq('id', profile.id);

      // Run parallel
      await Future.wait([patientFuture, profileFuture]);

      // 3. Update in-memory cache
      _cachedProfile = profile;
    } catch (e) {
      print('Profile update error: $e');
      rethrow; // Re-throw to let UI handle error
    }
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(String userId, File file) async {
    final fileName = 'profile.jpg';
    final path = 'patients/$userId/$fileName';

    try {
      await _supabase.storage.from('profile-photos').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl =
          _supabase.storage.from('profile-photos').getPublicUrl(path);

      // Cache bust
      return '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }
}
