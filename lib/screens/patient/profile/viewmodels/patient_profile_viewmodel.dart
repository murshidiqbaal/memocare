import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/patient_profile.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/service_providers.dart';

class PatientProfileViewModel
    extends StateNotifier<AsyncValue<PatientProfile?>> {
  final Ref _ref;
  final String? _targetPatientId;

  PatientProfileViewModel(this._ref, [this._targetPatientId])
      : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = _ref.read(currentUserProvider);
    final profileId = _targetPatientId ?? user?.id;

    if (profileId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(patientProfileRepositoryProvider);
      final profile = await repository.getProfile(profileId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(PatientProfile profile) async {
    try {
      final repository = _ref.read(patientProfileRepositoryProvider);
      await repository.updateProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfileImage(File file) async {
    final currentProfile = state.valueOrNull;
    if (currentProfile == null) return;

    try {
      final repository = _ref.read(patientProfileRepositoryProvider);
      final imageUrl =
          await repository.uploadProfileImage(currentProfile.id, file);

      if (imageUrl != null) {
        final updatedProfile =
            currentProfile.copyWith(profileImageUrl: imageUrl);
        await updateProfile(updatedProfile);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the logged-in patient's profile
final patientProfileProvider =
    StateNotifierProvider<PatientProfileViewModel, AsyncValue<PatientProfile?>>(
        (ref) {
  return PatientProfileViewModel(ref);
});

/// Family/Caregiver targeted patient profile provider
final patientMonitoringProvider = StateNotifierProvider.family<
    PatientProfileViewModel,
    AsyncValue<PatientProfile?>,
    String>((ref, patientId) {
  return PatientProfileViewModel(ref, patientId);
});
