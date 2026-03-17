import 'dart:async';

import 'package:memocare/data/models/user/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../models/user/profile.dart';

class RemoteAuthDatasource {
  final SupabaseClient _supabase;

  RemoteAuthDatasource(this._supabase);

  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
  }) async {
    // Sign up user with email and password. Profile creation is handled in AuthRepository.
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'fullName': fullName,
        'role': role,
      },
    );

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Profile?> getProfile(String userId) async {
    debugPrint('[Auth] fetching profile for userId=$userId');

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        debugPrint('[Auth] profile found in profiles table: $data');
        return Profile.fromJson(data);
      }
    } catch (e) {
      debugPrint(
          '[Auth] error fetching from profiles table (may not exist): $e');
    }

    // Fallback: Check user metadata (vital for immediate signup redirection)
    final user = _supabase.auth.currentUser;
    if (user != null && user.id == userId) {
      final role = user.userMetadata?['role'] ?? user.appMetadata['role'];
      final fullName =
          user.userMetadata?['fullName'] ?? user.userMetadata?['full_name'];

      if (role != null) {
        debugPrint('[Auth] falling back to metadata for role: $role');
        return Profile(
          id: userId,
          email: user.email ?? '',
          role: role.toString(),
          fullName: fullName?.toString() ?? 'User',
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        );
      }
    }

    debugPrint('[Auth] no profile found in table or metadata');
    return null;
  }

  Future<void> createProfile({
    required String userId,
    required String fullName,
    required String role,
    required String email,
  }) async {
    debugPrint(
        '[Auth] creating/updating profile in profiles for userId=$userId with role=$role');
    await _supabase.from('profiles').upsert({
      'user_id': userId,
      'full_name': fullName,
      'role': role,
      'email': email,
    }, onConflict: 'user_id');
  }

  Future<void> createProfileLegacy({
    required String userId,
    required String fullName,
    required String table,
  }) async {
    debugPrint(
        '[Auth] creating/updating legacy extension in $table for userId=$userId');
    await _supabase.from(table).upsert({
      'user_id': userId,
      'full_name': fullName,
    }, onConflict: 'user_id');
  }

  // ─── Biometric Enrollment ───

  Future<void> enableBiometricEnrollment({
    required String userId,
    required String deviceId,
  }) async {
    debugPrint('[Auth] Enabling biometric enrollment for userId=$userId on deviceId=$deviceId');
    await _supabase.from('biometric_enrollment').upsert({
      'user_id': userId,
      'device_id': deviceId,
      'enabled': true,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,device_id');
  }

  Future<Map<String, dynamic>?> getBiometricEnrollment(String deviceId) async {
    debugPrint('[Auth] Fetching biometric enrollment for deviceId=$deviceId');
    return await _supabase
        .from('biometric_enrollment')
        .select()
        .eq('device_id', deviceId)
        .eq('enabled', true)
        .maybeSingle();
  }
}
