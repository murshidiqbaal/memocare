import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
// import '../../core/security/secure_storage_service.dart';
import '../../models/user/profile.dart';
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

  Future<Either<Failure, void>> signIn(
      {required String email, required String password}) async {
    try {
      await _remoteDatasource.signIn(email: email, password: password);

      // After successful login, if biometric was previously enabled,
      // update the saved session tokens to ensure next biometric login works.
      // final isEnabled = await _storage.isBiometricEnabled();
      // if (isEnabled) {
      //   final session = _remoteDatasource.currentSession;
      //   if (session != null) {
      //     await _storage.saveSession(
      //       accessToken: session.accessToken,
      //       refreshToken: session.refreshToken ?? '',
      //     );
      //   }
      // }

      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> signUp(
      {required String email,
      required String password,
      required String role,
      required String fullName}) async {
    try {
      await _remoteDatasource.signUp(
          email: email, password: password, role: role, fullName: fullName);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
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
