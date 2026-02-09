import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../models/user/profile.dart';
import '../datasources/remote/remote_auth_datasource.dart';

class AuthRepository {
  final RemoteAuthDatasource _remoteDatasource;

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
