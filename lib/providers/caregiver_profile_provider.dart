import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/caregiver.dart';
import '../data/repositories/caregiver_repository.dart';

/// Provider for the Caregiver Repository
final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  return CaregiverRepository(Supabase.instance.client);
});

/// Async Provider for the Caregiver Profile
final caregiverProfileProvider =
    StateNotifierProvider<CaregiverProfileNotifier, AsyncValue<Caregiver?>>(
        (ref) {
  return CaregiverProfileNotifier(ref.read(caregiverRepositoryProvider));
});

class CaregiverProfileNotifier extends StateNotifier<AsyncValue<Caregiver?>> {
  final CaregiverRepository _repository;

  CaregiverProfileNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getMyCaregiverProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> upsertProfile(Caregiver caregiver) async {
    try {
      // Optimistic upate if profile already exists
      if (state.hasValue && state.value != null) {
        state = AsyncValue.data(
            caregiver.copyWith(fullName: state.value!.fullName));
      }

      await _repository.upsertCaregiverProfile(caregiver);
      await loadProfile(); // Refresh from server to get joined full_name etc.
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> uploadPhoto(File file) async {
    try {
      final url = await _repository.uploadProfilePhoto(file);
      return url;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    final updated = currentProfile.copyWith(notificationEnabled: enabled);
    await upsertProfile(updated);
  }
}
