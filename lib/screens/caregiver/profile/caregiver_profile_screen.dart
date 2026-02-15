import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/caregiver.dart';
import '../../../data/models/patient.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/caregiver_patients_provider.dart';
import '../../../providers/caregiver_profile_provider.dart';
import '../patients/caregiver_patients_screen.dart';
import 'edit_caregiver_profile_screen.dart';

class CaregiverProfileScreen extends ConsumerWidget {
  const CaregiverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(caregiverProfileProvider);
    final patientsAsync = ref.watch(connectedPatientsStreamProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final profile = profileAsync.valueOrNull;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditCaregiverProfileScreen(existingProfile: profile),
                ),
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (caregiver) {
          if (caregiver == null) {
            return _buildEmptyProfile(context);
          }
          return _buildProfileContent(
              context, ref, caregiver, patientsAsync, userProfile?.fullName);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyProfile(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No profile found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditCaregiverProfileScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    Caregiver caregiver,
    AsyncValue<List<Patient>> patientsAsync,
    String? authFullName,
  ) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24 * scale),
      child: Column(
        children: [
          // Profile Photo
          Hero(
            tag: 'caregiver_avatar',
            child: Container(
              width: 140 * scale,
              height: 140 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.shade50,
                border: Border.all(color: Colors.teal.shade200, width: 4),
                image: caregiver.profilePhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(caregiver.profilePhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: caregiver.profilePhotoUrl == null
                  ? Icon(Icons.person,
                      size: 70 * scale, color: Colors.teal.shade400)
                  : null,
            ),
          ),
          SizedBox(height: 16 * scale),

          // Full Name
          Text(
            caregiver.fullName ?? authFullName ?? 'Caregiver',
            style: TextStyle(
              fontSize: 24 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            caregiver.relationship ?? 'Family Member',
            style: TextStyle(
              fontSize: 16 * scale,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 32 * scale),

          // Stats / Quick Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Patients',
                patientsAsync.when(
                  data: (p) => p.length.toString(),
                  loading: () => '...',
                  error: (_, __) => '0',
                ),
                Icons.people_outline,
                scale,
              ),
              _buildStatCard(
                'Status',
                caregiver.notificationEnabled ? 'Active' : 'Muted',
                caregiver.notificationEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                scale,
                color:
                    caregiver.notificationEnabled ? Colors.teal : Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 32 * scale),

          // Details List
          _buildInfoRow(
              Icons.phone, 'Phone', caregiver.phone ?? 'Not set', scale),
          _buildInfoRow(Icons.family_restroom, 'Relationship',
              caregiver.relationship ?? 'Not set', scale),
          _buildInfoRow(Icons.sync, 'Auto-Sync', 'Enabled', scale),
          const Divider(height: 48),

          // Actions
          _buildActionButton(
            'Manage Patients',
            Icons.manage_accounts,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CaregiverPatientsScreen()),
              );
            },
            scale,
          ),
          SizedBox(height: 16 * scale),
          _buildActionButton(
            'Sign Out',
            Icons.logout,
            () => ref.read(authControllerProvider.notifier).signOut(),
            scale,
            color: Colors.red.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, double scale,
      {Color? color}) {
    return Container(
      width: 150 * scale,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.teal, size: 28 * scale),
          SizedBox(height: 12 * scale),
          Text(
            value,
            style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 14 * scale, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12 * scale),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade300, size: 24 * scale),
          SizedBox(width: 16 * scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13 * scale)),
              Text(value,
                  style: TextStyle(
                      fontSize: 16 * scale, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onTap, double scale,
      {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: 20 * scale, vertical: 16 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: (color ?? Colors.teal).withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: color ?? Colors.teal, size: 24 * scale),
              SizedBox(width: 16 * scale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.teal.shade800,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right,
                  color: Colors.grey.shade400, size: 20 * scale),
            ],
          ),
        ),
      ),
    );
  }
}
