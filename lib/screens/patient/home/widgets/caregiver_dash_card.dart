import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/connection_providers.dart';

class CaregiverDashCard extends ConsumerWidget {
  const CaregiverDashCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caregivers = ref.watch(linkedCaregiversProvider);
    final scale = MediaQuery.of(context).size.width / 375.0;

    return caregivers.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        // Primary caregiver is the first one
        final caregiver = list.first;

        return GestureDetector(
          onTap: () {
            // Can navigate to caregiver detail or call
            if (caregiver.phone != null) {
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
                Hero(
                  tag: 'caregiver_avatar_${caregiver.id}',
                  child: Container(
                    width: 60 * scale,
                    height: 60 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.teal.shade200, width: 2),
                      image: caregiver.profilePhotoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(caregiver.profilePhotoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: caregiver.profilePhotoUrl == null
                        ? Icon(Icons.person,
                            size: 30 * scale, color: Colors.teal.shade400)
                        : null,
                  ),
                ),
                SizedBox(width: 16 * scale),
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
                      if (caregiver.relationship != null) ...[
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
                if (caregiver.phone != null)
                  Container(
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
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox
          .shrink(), // Don't show anything while loading to avoid jump
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _call(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
