import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/profile_photo_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/caregiver_profile_provider.dart';
import '../providers/service_providers.dart';
import '../screens/patient/profile/viewmodels/patient_profile_viewmodel.dart';
import '../services/image_picker_service.dart'; // Added import

// Provider for Image Picker
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

// Provider for Profile Photo Repo
final profilePhotoRepositoryProvider = Provider<ProfilePhotoRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProfilePhotoRepository(supabase);
});

// Async Notifier for handling uploads
final profilePhotoUploadProvider =
    AsyncNotifierProvider<ProfilePhotoUploadNotifier, void>(
        ProfilePhotoUploadNotifier.new);

class ProfilePhotoUploadNotifier extends AsyncNotifier<void> {
  late final ProfilePhotoRepository _repository;
  late final ImagePickerService _picker;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(profilePhotoRepositoryProvider);
    _picker = ref.watch(imagePickerServiceProvider);
  }

  /// Upload flow: Pick Image -> Upload -> Refresh Provider
  Future<void> pickAndUpload() async {
    state = const AsyncLoading(); // Setloading

    try {
      final file = await _picker.pickImage();
      if (file == null) {
        state = const AsyncData(null); // Cancelled
        return;
      }

      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final profile = await ref.read(userProfileProvider.future);
      if (profile == null) throw Exception('Profile not loaded');

      final role = profile.role; // 'patient' or 'caregiver'

      // Upload (result stored in DB, we only need to invalidate providers)
      await _repository.uploadProfilePhoto(
        userId: user.id,
        file: file,
        role: role,
      );

      // Update UI by invalidating profile providers
      if (role == 'patient') {
        ref.invalidate(patientProfileProvider);
      } else if (role == 'caregiver') {
        ref.invalidate(caregiverProfileProvider);
      }

      // Success
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
