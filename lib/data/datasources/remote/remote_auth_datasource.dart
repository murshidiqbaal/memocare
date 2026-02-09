import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user/profile.dart';

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
    // 1. Sign up user
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );

    // Note: Profiles table population often handled by Supabase Postgres Triggers,
    // but we can also insert manually if no trigger exists.
    // The user's schema didn't specify a trigger, just the table creation.
    // So we should probably insert into 'profiles' manually here if the trigger isn't set up.
    // However, usually it's best to use a trigger.
    // For this implementation, I will assume a trigger OR manual insertion.
    // Let's do manual insertion to be safe since I can't create triggers from here easily
    // (though I could advise it). Or just allow the client to insert.

    if (response.user != null) {
      try {
        // Attempt manual profile insertion
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'role': role,
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // If manual insertion fails, it might be because:
        // 1. A Postgres trigger already created the profile (duplicate key error).
        // 2. Network issue.
        // 3. Permission issue.

        // We log this but don't fail the signup completely if the auth user exists.
        // However, if strict profile requirement exists, we might want to Rethrow.
        // For this app, we rethrow so the UI shows an error and the user can try again or contact support.
        // Ideally, we'd check if profile exists first.
        throw Exception('Failed to create user profile: $e');
      }
    }

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
    try {
      final data =
          await _supabase.from('profiles').select().eq('id', userId).single();
      return Profile.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
