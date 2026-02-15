import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/caregiver_patient_link.dart';
import '../../../providers/connection_providers.dart';

class PatientConnectionsScreen extends ConsumerWidget {
  const PatientConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Linked caregivers are now instantly connected via invite codes
    final linkedCaregivers = ref.watch(linkedCaregiversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Caregivers'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connected Caregivers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            linkedCaregivers.when(
              data: (caregivers) => caregivers.isEmpty
                  ? const _EmptyState(
                      icon: Icons.people_outline,
                      message:
                          'No caregivers connected yet.\nShare your invite code with a caregiver to connect.',
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: caregivers.length,
                      itemBuilder: (context, index) =>
                          _CaregiverCard(caregiver: caregivers[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaregiverCard extends StatelessWidget {
  final CaregiverPatientLink caregiver;

  const _CaregiverCard({required this.caregiver});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(
          caregiver.caregiverName ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(caregiver.caregiverEmail ?? ''),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
