import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../patient/settings/caregiver_access_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              profileAsync.when(
                data: (profile) => Column(
                  children: [
                    Text(
                      profile?.fullName ?? 'User',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(profile?.role.toUpperCase() ?? 'GUEST'),
                      backgroundColor: Colors.teal.shade50,
                      labelStyle: TextStyle(color: Colors.teal.shade800),
                    ),
                    if (profile?.role == 'patient') ...[
                      const SizedBox(height: 32),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.security, color: Colors.blue),
                        ),
                        title: const Text('Caregiver Access'),
                        subtitle: const Text('generate invite code'),
                        trailing: const Icon(Icons.chevron_right),
                        tileColor: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          // Navigate to Caregiver Access
                          // Since we didn't add it to routes yet, we can push MaterialPageRoute for now
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const CaregiverAccessScreen()));
                        },
                      ),
                    ],
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error loading profile: $e'),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    // Router redirect will handle the rest, or we can force it
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
