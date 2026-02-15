import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';

class PatientAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const PatientAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

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
            // Profile Photo
            CircleAvatar(
              radius: 28 * scale,
              backgroundColor: Colors.teal.shade50,
              backgroundImage: const AssetImage(
                  'assets/images/placeholders/profile_placeholder.png'), // Mock
              child: Icon(Icons.person, size: 32 * scale, color: Colors.teal),
            ),
            SizedBox(width: 16 * scale),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ... existing text implementation logic using theme or scaled custom style?
                  // Theme text is okay, but user said 'all font size'.
                  // I'll stick to theme but maybe scale fontSize if I was setting it explicitly.
                  // Here it uses theme.headlineSmall.
                  // I'll keep theme usage as it respects system text scale factor somewhat.
                  // But I'll ensure layout around it scales.
                  profileAsync.when(
                    data: (profile) => Text(
                      "Hello, ${profile?.fullName ?? 'Patient'} 👋",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize:
                            (theme.textTheme.headlineSmall?.fontSize ?? 24) *
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize:
                          (theme.textTheme.bodyLarge?.fontSize ?? 16) * scale,
                    ),
                  ),
                ],
              ),
            ),

            // Notification Bell
            Container(
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                iconSize: 24 * scale,
                icon: Icon(Icons.notifications_outlined,
                    color: Colors.teal.shade700, size: 24 * scale),
                tooltip: 'Notifications',
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
