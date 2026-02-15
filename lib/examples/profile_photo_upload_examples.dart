// ============================================================================
// PROFILE PHOTO UPLOAD - QUICK REFERENCE GUIDE
// ============================================================================

// ----------------------------------------------------------------------------
// 1. USING THE EDITABLE AVATAR WIDGET
// ----------------------------------------------------------------------------

import 'package:dementia_care_app/providers/auth_provider.dart';
import 'package:dementia_care_app/providers/caregiver_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_photo_provider.dart';
import '../screens/patient/profile/viewmodels/patient_profile_viewmodel.dart';
import '../widgets/editable_avatar.dart';

class MyProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(profilePhotoUploadProvider);
    final isUploading = uploadState is AsyncLoading;

    return EditableAvatar(
      profilePhotoUrl: 'https://example.com/photo.jpg', // or null
      isUploading: isUploading,
      radius: 70, // Customize size
      onTap: () async {
        await ref.read(profilePhotoUploadProvider.notifier).pickAndUpload();
      },
    );
  }
}

// ----------------------------------------------------------------------------
// 2. MANUAL UPLOAD (Without EditableAvatar)
// ----------------------------------------------------------------------------

Future<void> uploadPhoto(WidgetRef ref) async {
  // Option A: Use the provider (recommended)
  await ref.read(profilePhotoUploadProvider.notifier).pickAndUpload();

  // Option B: Manual control
  final picker = ref.read(imagePickerServiceProvider);
  final file = await picker.pickImage();

  if (file != null) {
    final repo = ref.read(profilePhotoRepositoryProvider);
    final user = ref.read(currentUserProvider);
    final profile = await ref.read(userProfileProvider.future);

    final url = await repo.uploadProfilePhoto(
      userId: user!.id,
      file: file,
      role: profile!.role, // 'patient' or 'caregiver'
    );

    // Manually invalidate to refresh
    if (profile.role == 'patient') {
      ref.invalidate(patientProfileProvider);
    } else {
      ref.invalidate(caregiverProfileProvider);
    }
  }
}

// ----------------------------------------------------------------------------
// 3. LISTENING TO UPLOAD STATE
// ----------------------------------------------------------------------------

class UploadStatusWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(profilePhotoUploadProvider);

    return uploadState.when(
      data: (_) => Text('Ready'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

// ----------------------------------------------------------------------------
// 4. CUSTOM UPLOAD BUTTON
// ----------------------------------------------------------------------------

Widget buildCustomUploadButton(BuildContext context, WidgetRef ref) {
  return ElevatedButton(
    onPressed: () async {
      final notifier = ref.read(profilePhotoUploadProvider.notifier);
      await notifier.pickAndUpload();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo uploaded!')),
      );
    },
    child: Text('Upload Photo'),
  );
}

// ----------------------------------------------------------------------------
// 5. STORAGE STRUCTURE REFERENCE
// ----------------------------------------------------------------------------

/*
Supabase Storage Bucket: profile-photos

Folder Structure:
├── patients/
│   ├── {userId1}/
│   │   └── profile.jpg
│   ├── {userId2}/
│   │   └── profile.jpg
│   └── ...
└── caregivers/
    ├── {userId1}/
    │   └── profile.jpg
    ├── {userId2}/
    │   └── profile.jpg
    └── ...

Database Updates:
- Patient: patients.profile_photo_url
- Caregiver: caregiver_profiles.profile_photo_url
*/

// ----------------------------------------------------------------------------
// 6. ERROR HANDLING EXAMPLE
// ----------------------------------------------------------------------------

Future<void> uploadWithErrorHandling(
    WidgetRef ref, BuildContext context) async {
  try {
    await ref.read(profilePhotoUploadProvider.notifier).pickAndUpload();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Photo uploaded successfully!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ----------------------------------------------------------------------------
// 7. PROVIDER DEPENDENCIES
// ----------------------------------------------------------------------------

/*
Available Providers:

1. imagePickerServiceProvider
   - Type: Provider<ImagePickerService>
   - Usage: Image selection

2. profilePhotoRepositoryProvider
   - Type: Provider<ProfilePhotoRepository>
   - Usage: Upload to Supabase

3. profilePhotoUploadProvider
   - Type: AsyncNotifierProvider<ProfilePhotoUploadNotifier, void>
   - Usage: Complete upload flow with auto-refresh

4. patientProfileProvider
   - Type: StateNotifierProvider<PatientProfileViewModel, AsyncValue<PatientProfile?>>
   - Auto-invalidated after patient upload

5. caregiverProfileProvider
   - Type: StateNotifierProvider<CaregiverProfileNotifier, AsyncValue<Caregiver?>>
   - Auto-invalidated after caregiver upload
*/
