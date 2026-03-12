import 'package:memocare/providers/connection_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class CaregiverDashCard extends ConsumerWidget {
  const CaregiverDashCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the linked caregivers provider - automatically refetches on changes
    final caregivers = ref.watch(linkedCaregiversProvider);
    final scale = MediaQuery.of(context).size.width / 375.0;

    return caregivers.when(
      // ✅ DATA STATE: Display caregiver(s)
      data: (list) {
        if (list.isEmpty) {
          // No caregivers linked yet
          return _buildEmptyState(scale);
        }

        // Display primary caregiver (first in list)
        final caregiver = list.first;
        return _buildCaregiverCard(caregiver, scale);
      },

      // ⏳ LOADING STATE: Show spinner
      loading: () => _buildLoadingState(scale),

      // ❌ ERROR STATE: Show error with retry
      error: (err, stackTrace) => _buildErrorState(err, scale, ref),
    );
  }

  /// Empty state when no caregivers are linked
  Widget _buildEmptyState(double scale) {
    return Container(
      margin: EdgeInsets.only(bottom: 24 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 14 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_search_outlined,
            color: Colors.grey.shade400,
            size: 28 * scale,
          ),
          SizedBox(width: 12 * scale),
          Text(
            'No caregiver linked yet',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14 * scale,
            ),
          ),
        ],
      ),
    );
  }

  /// Loading state with spinner
  Widget _buildLoadingState(double scale) {
    return Container(
      margin: EdgeInsets.only(bottom: 24 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SizedBox(
        height: 72 * scale,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  /// Error state with retry button
  Widget _buildErrorState(
    Object error,
    double scale,
    WidgetRef ref,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 24 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 24 * scale,
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load caregiver',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12 * scale,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          GestureDetector(
            onTap: () {
              // Retry by invalidating the provider
              ref.refresh(linkedCaregiversProvider);
            },
            child: Container(
              padding: EdgeInsets.all(8 * scale),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.refresh,
                color: Colors.red.shade700,
                size: 20 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Main caregiver card UI
  Widget _buildCaregiverCard(dynamic caregiver, double scale) {
    return GestureDetector(
      onTap: () {
        // Initiate call if phone number is available
        if (caregiver.phone != null && caregiver.phone!.isNotEmpty) {
          _call(caregiver.phone!);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 24 * scale),
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.teal.shade100, width: 1.5),
        ),
        child: Row(
          children: [
            // Profile Avatar with Hero animation
            Hero(
              tag: 'caregiver_avatar_${caregiver.id}',
              child: Container(
                width: 60 * scale,
                height: 60 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.teal.shade200, width: 2),
                  image: caregiver.profilePhotoUrl != null &&
                          caregiver.profilePhotoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(caregiver.profilePhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: caregiver.profilePhotoUrl == null ||
                        caregiver.profilePhotoUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 30 * scale,
                        color: Colors.teal.shade400,
                      )
                    : null,
              ),
            ),

            SizedBox(width: 16 * scale),

            // Caregiver info (name, relationship)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Caregiver',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    caregiver.fullName ?? 'Unknown Caregiver',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (caregiver.relationship != null &&
                      caregiver.relationship!.isNotEmpty) ...[
                    SizedBox(height: 2 * scale),
                    Text(
                      caregiver.relationship!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14 * scale,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Call button (if phone available)
            if (caregiver.phone != null && caregiver.phone!.isNotEmpty)
              GestureDetector(
                onTap: () => _call(caregiver.phone!),
                child: Container(
                  padding: EdgeInsets.all(10 * scale),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: Colors.green.shade700,
                    size: 24 * scale,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Launch phone call
  Future<void> _call(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Fallback: show snackbar if can't launch
        debugPrint('Could not launch phone call: $phoneNumber');
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
    }
  }
}
