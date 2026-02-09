import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/repositories/caregiver_profile_repository.dart';
import '../../../../models/user/caregiver_profile.dart';
import '../../../../providers/auth_provider.dart';

// Manual provider definition to avoid build_runner dependency
final caregiverProfileViewModelProvider = StateNotifierProvider<
    CaregiverProfileViewModel, AsyncValue<CaregiverProfile?>>((ref) {
  return CaregiverProfileViewModel(ref);
});

class CaregiverProfileViewModel
    extends StateNotifier<AsyncValue<CaregiverProfile?>> {
  final Ref ref;

  CaregiverProfileViewModel(this.ref) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();

    final repository = ref.read(caregiverProfileRepositoryProvider);
    final result = await repository.getProfile(user.id);

    result.fold(
      (failure) {
        // If profile not found, return null so UI shows form
        // Assuming failure message contains "Profile not found" or similar based on repo logic
        if (failure.toString().contains('Profile not found')) {
          state = const AsyncValue.data(null);
        } else {
          state = AsyncValue.error(failure.message, StackTrace.current);
        }
      },
      (profile) {
        state = AsyncValue.data(profile);
      },
    );
  }

  Future<void> saveProfile({
    required String fullName,
    required String phoneNumber,
    required String relationship,
    required bool notificationsEnabled,
    File? newPhoto,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Keep current state to revert or use ID
    final currentProfile = state.value;

    // Set loading
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(caregiverProfileRepositoryProvider);

      String? photoUrl = currentProfile?.photoUrl;

      // 1. Upload photo if changed
      if (newPhoto != null) {
        final uploadResult =
            await repository.uploadProfileImage(newPhoto, user.id);
        uploadResult.fold(
          (l) => throw Exception('Failed to upload image: ${l.message}'),
          (url) => photoUrl = url,
        );
      }

      // 2. Prepare Profile Object
      final profileToSave = CaregiverProfile(
        id: currentProfile?.id ?? const Uuid().v4(),
        userId: user.id,
        fullName: fullName,
        phoneNumber: phoneNumber,
        relationship: relationship,
        notificationsEnabled: notificationsEnabled,
        photoUrl: photoUrl,
        linkedPatientIds: currentProfile?.linkedPatientIds ?? [],
      );

      // 3. Update or Create
      final result = currentProfile != null
          ? await repository.updateProfile(profileToSave)
          : await repository.createProfile(profileToSave);

      result.fold(
        (l) => state = AsyncValue.error(l.message, StackTrace.current),
        (updatedProfile) {
          state = AsyncValue.data(updatedProfile);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
