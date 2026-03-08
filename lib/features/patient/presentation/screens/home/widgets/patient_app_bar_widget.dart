import 'package:dementia_care_app/features/auth/providers/auth_provider.dart';
import 'package:dementia_care_app/features/patient/presentation/screens/profile/viewmodels/patient_profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../../providers/auth_provider.dart';
// import '../../../patient/profile/viewmodels/patient_profile_viewmodel.dart';

class PatientAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const PatientAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final profileAsync = ref.watch(userProfileProvider);

    // Watch the patient's own profile from the `patients` table for photo URL
    final patientProfileAsync = ref.watch(patientProfileProvider(null));

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(24 * scale)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ── Profile Photo ──────────────────────────────────────────────
            patientProfileAsync.when(
              data: (patient) => _ProfileAvatar(
                photoUrl: patient?.profileImageUrl,
                userId: Supabase.instance.client.auth.currentUser?.id,
                scale: scale,
              ),
              loading: () => _ProfileAvatar(
                photoUrl: null,
                userId: Supabase.instance.client.auth.currentUser?.id,
                scale: scale,
              ),
              error: (_, __) => _ProfileAvatar(
                photoUrl: null,
                userId: null,
                scale: scale,
              ),
            ),
            SizedBox(width: 16 * scale),

            // ── Greeting + Date ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  profileAsync.when(
                    data: (profile) => Text(
                      "Hello, ${profile?.fullName ?? 'Patient'} 👋",
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: (Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.fontSize ??
                                        24) *
                                    scale,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => const Text('Hello...'),
                    error: (_, __) => const Text('Hello, Patient'),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                          fontSize: (Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.fontSize ??
                                  16) *
                              scale,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90);
}

/// Resolves the profile photo from:
/// 1. `profile_photo_url` column in `patients` table  (passed as [photoUrl])
/// 2. Supabase Storage public URL: profile-photos/patients/{uid}/profile.jpg
/// 3. Icon fallback when neither is available
class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? userId;
  final double scale;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.userId,
    required this.scale,
  });

  /// Returns the resolved photo URL: DB value first, bucket fallback second.
  String? _resolvedUrl() {
    if (photoUrl != null && photoUrl!.isNotEmpty) return photoUrl;

    if (userId != null && userId!.isNotEmpty) {
      // Build public URL for the well-known storage path
      try {
        return Supabase.instance.client.storage
            .from('profile-photos')
            .getPublicUrl('patients/$userId/profile.jpg');
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl();

    return CircleAvatar(
      radius: 28 * scale,
      backgroundColor: Colors.teal.shade50,
      // Use NetworkImage when we have a URL; show icon child otherwise
      backgroundImage: url != null ? NetworkImage(url) : null,
      // Icon is the child and only renders when backgroundImage is null
      child: url == null
          ? Icon(Icons.person, size: 32 * scale, color: Colors.teal)
          : null,
    );
  }
}
