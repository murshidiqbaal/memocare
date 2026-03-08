import 'dart:io';

import 'package:dementia_care_app/models/user/patient_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientProfileRepository {
  final SupabaseClient _supabase;

  PatientProfile? _cachedProfile;

  PatientProfileRepository(this._supabase);

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<PatientProfile?> getProfile(String userId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedProfile != null &&
        _cachedProfile!.id == userId) {
      return _cachedProfile;
    }

    try {
      // Base auth profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('full_name, phone_number, avatar_url, profile_photo_url')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) return null;

      // Patient-specific data (all columns)
      final patientResponse = await _supabase
          .from('patients')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      // Merge: patient table wins over profiles table
      final Map<String, dynamic> merged = {
        'id': userId, // Temporary placeholder if patient record doesn't exist
        'user_id': userId,
        'full_name': patientResponse?['full_name'] ??
            profileResponse['full_name'] ??
            'Patient',
        'phone_number':
            patientResponse?['phone'] ?? profileResponse['phone_number'],
        'profile_photo_url': patientResponse?['profile_photo_url'] ??
            profileResponse['profile_photo_url'] ??
            profileResponse['avatar_url'],
      };

      if (patientResponse != null) {
        merged.addAll(patientResponse);
        // Keep the database PK as 'id' and authenticated ID as 'user_id'
      }

      final profile = PatientProfile.fromJson(merged);
      _cachedProfile = profile;
      return profile;
    } catch (e) {
      print('PatientProfileRepository.getProfile error: $e');
      if (_cachedProfile?.id == userId) return _cachedProfile;
      return null;
    }
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  Future<void> updateProfile(PatientProfile profile) async {
    try {
      final now = DateTime.now().toIso8601String();

      // ── patients table ────────────────────────────────────────────────────
      final patientData = <String, dynamic>{
        'id': profile.id,

        // Personal
        'full_name': profile.fullName,
        'phone': profile.phoneNumber,
        'date_of_birth': profile.dateOfBirth?.toIso8601String(),
        'gender': profile.gender,
        'address': profile.address,
        'profile_photo_url': profile.profileImageUrl,

        // Emergency & Medical
        'emergency_contact_name': profile.emergencyContactName,
        'emergency_contact_phone': profile.emergencyContactPhone,
        'medical_notes': profile.medicalNotes,

        // Hobbies & Interests
        'hobbies': profile.hobbies, // stored as jsonb / text[]
        'favourite_pastime': profile.favouritePastime,
        'indoor_outdoor_pref': profile.indoorOutdoorPref,

        // Favourite Things
        'favourite_food': profile.favouriteFood,
        'favourite_drink': profile.favouriteDrink,
        'favourite_music': profile.favouriteMusic,
        'favourite_show': profile.favouriteShow,
        'favourite_place': profile.favouritePlace,

        // Daily Routine
        'wake_up_time': profile.wakeUpTime,
        'bed_time': profile.bedTime,
        'nap_time': profile.napTime,
        'meal_preferences': profile.mealPreferences,
        'exercise_routine': profile.exerciseRoutine,
        'religious_practices': profile.religiousPractices,

        // Language & Communication
        'preferred_language': profile.preferredLanguage,
        'communication_style': profile.communicationStyle,
        'triggers': profile.triggers,
        'calming_strategies': profile.calmingStrategies,
        'important_people': profile.importantPeople,

        // Meta
        'created_at': profile.createdAt?.toIso8601String() ?? now,
        'updated_at': now,
      };

      // Remove nulls so we don't accidentally wipe existing columns
      patientData.removeWhere((_, v) => v == null);

      // ── profiles table (base auth row) ────────────────────────────────────
      final profileData = <String, dynamic>{
        'id': profile.userId ?? profile.id, // Auth id
        'full_name': profile.fullName,
        'phone_number': profile.phoneNumber,
      };
      profileData.removeWhere((_, v) => v == null);

      // ── patients table logic ──────────────────────────────────────────────
      final existingPatient = await _supabase
          .from('patients')
          .select('id')
          .eq('user_id', profile.userId ?? profile.id)
          .maybeSingle();

      if (existingPatient != null) {
        // UPDATE existing
        await _supabase
            .from('patients')
            .update(patientData)
            .eq('user_id', profile.userId ?? profile.id);
      } else {
        // INSERT new
        // Ensure user_id is set and remove manual id to let DB generate it
        patientData['user_id'] = profile.userId ?? profile.id;
        patientData.remove('id');
        await _supabase.from('patients').insert(patientData);
      }

      await _supabase
          .from('profiles')
          .update(profileData)
          .eq('id', profile.userId ?? profile.id);

      _cachedProfile = profile;
    } catch (e) {
      print('PatientProfileRepository.updateProfile error: $e');
      rethrow;
    }
  }

  // ── IMAGE ─────────────────────────────────────────────────────────────────

  Future<String?> uploadProfileImage(String userId, File file) async {
    final path = 'patients/$userId/profile.jpg';
    try {
      await _supabase.storage.from('profile-photos').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _supabase.storage.from('profile-photos').getPublicUrl(path);
      // Cache-bust so the UI picks up the new image immediately
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('PatientProfileRepository.uploadProfileImage error: $e');
      return null;
    }
  }

  void clearCache() => _cachedProfile = null;
}
