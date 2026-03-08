import 'package:dartz/dartz.dart';
import 'package:dementia_care_app/data/models/user/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
// import '../../core/security/secure_storage_service.dart';
// import '../../models/user/profile.dart';
import '../datasources/remote/remote_auth_datasource.dart';

class AuthRepository {
  final RemoteAuthDatasource _remoteDatasource;
  // final SecureStorageService _storage;

  AuthRepository(this._remoteDatasource);

  Stream<AuthState> get authStateChanges => _remoteDatasource.authStateChanges;
  User? get currentUser => _remoteDatasource.currentUser;

  Future<Either<Failure, Profile?>> getProfile(String userId) async {
    try {
      final profile = await _remoteDatasource.getProfile(userId);
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[Auth] Attempting login for $email');
      final response = await _remoteDatasource.signIn(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return Left(const AuthFailure('Login failed: User is null.'));
      }

      debugPrint('[Auth] Login successful for ${user.id}');
      return Right(user);
    } on AuthException catch (e) {
      debugPrint('[Auth] login fails: ${e.message}');
      return Left(AuthFailure(e.message));
    } catch (e) {
      debugPrint('[Auth] Unexpected Login Error: $e');
      return Left(AuthFailure('An unexpected error occurred: $e'));
    }
  }

  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
  }) async {
    // 1. Validate Role
    final normalizedRole = role.toLowerCase().trim();
    if (normalizedRole != 'patient' && normalizedRole != 'caregiver') {
      return Left(AuthFailure(
          'Invalid role: $role. Must be "patient" or "caregiver".'));
    }

    try {
      debugPrint('[Auth] Starting signup for $email with role $normalizedRole');

      // 2. Auth Signup
      final response = await _remoteDatasource.signUp(
        email: email,
        password: password,
        role: normalizedRole,
        fullName: fullName,
      );

      final user = response.user;
      if (user == null) {
        return Left(const AuthFailure('Signup failed: User was not created.'));
      }

      // 3. Profiles Table Injection (Source of Truth)
      try {
        await _remoteDatasource.createProfile(
          userId: user.id,
          fullName: fullName,
          role: normalizedRole,
          email: email,
        );

        // 4. Role-specific extension (NOT needed if no separate tables exist)
        // await _remoteDatasource.createProfileLegacy(...);
      } catch (e) {
        debugPrint('[Auth] Profile creation failed: $e');
        return Left(
            AuthFailure('Auth success, but profile creation failed: $e'));
      }

      debugPrint(
          '[Auth] Signup and profile creation successful for ${user.id}');
      return Right(user);
    } on AuthException catch (e) {
      debugPrint('[Auth] Supabase Auth Exception: ${e.message}');
      return Left(AuthFailure(e.message));
    } on PostgrestException catch (e) {
      debugPrint('[Auth] Supabase Database Exception: ${e.message}');
      return Left(ServerFailure('Database error: ${e.message}'));
    } catch (e) {
      debugPrint('[Auth] Unexpected Signup Error: $e');
      return Left(AuthFailure('An unexpected error occurred: $e'));
    }
  }

  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDatasource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
