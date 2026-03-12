import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:memocare/data/models/user/caregiver_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
// import '../../models/user/caregiver_profile.dart';

final caregiverProfileRepositoryProvider =
    Provider<CaregiverProfileRepository>((ref) {
  return CaregiverProfileRepository(Supabase.instance.client);
});

class CaregiverProfileRepository {
  final SupabaseClient _supabase;

  CaregiverProfileRepository(this._supabase);

  Future<Either<Failure, CaregiverProfile>> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .eq('role', 'caregiver')
          .maybeSingle();

      if (response == null) {
        return const Left(ServerFailure('Profile not found'));
      }

      final profile = CaregiverProfile.fromJson(response);

      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, CaregiverProfile>> createProfile(
      CaregiverProfile profile) async {
    try {
      final data = {
        ...profile.toJson(),
        'role': 'caregiver',
      };
      final response =
          await _supabase.from('profiles').insert(data).select().single();

      return Right(CaregiverProfile.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, CaregiverProfile>> updateProfile(
      CaregiverProfile profile) async {
    try {
      final response = await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .eq('role', 'caregiver')
          .select()
          .single();

      return Right(CaregiverProfile.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, String>> uploadProfileImage(
      File imageFile, String userId) async {
    try {
      final filePath = 'profiles/$userId/profile.jpg';

      await _supabase.storage.from('profile-photos').upload(filePath, imageFile,
          fileOptions: const FileOptions(upsert: true));

      final imageUrl =
          _supabase.storage.from('profile-photos').getPublicUrl(filePath);
      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<bool> profileExists(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .eq('role', 'caregiver')
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }
}
