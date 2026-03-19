import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/sos_system_repository.dart';
import '../../../../data/models/sos_message.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import 'emergency_map_screen.dart';

final caregiverAlertsStreamProvider = StreamProvider.autoDispose<List<SosMessage>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null || profile.role != 'caregiver') {
    return const Stream.empty();
  }
  final repo = ref.watch(sosSystemRepositoryProvider);
  return repo.streamActiveSosMessages(profile.id);
});

class CaregiverAlertsScreen extends ConsumerWidget {
  const CaregiverAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(caregiverAlertsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Active Emergencies', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        elevation: 0,
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading alerts: $err')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _AlertCard(alert: alert);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gpp_good, size: 80, color: Colors.green.shade400),
          const SizedBox(height: 16),
          const Text(
            'All Patients Safe',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'No active SOS alerts right now.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  final SosMessage alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('MMM d, h:mm a').format(alert.triggeredAt.toLocal());
    final isNew = alert.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNew ? Colors.red.shade400 : Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: isNew ? Colors.red : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.note ?? 'Emergency SOS Triggered',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isNew ? Colors.red.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.access_time_filled, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(timeStr, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text('Patient ID: ${alert.patientId.substring(0, 8)}...', style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    // Mark as resolved
                    await ref.read(sosSystemRepositoryProvider).updateSosStatus(alert.id!, 'resolved');
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  label: const Text('Resolve', style: TextStyle(color: Colors.green)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (isNew) {
                      ref.read(sosSystemRepositoryProvider).updateSosStatus(alert.id!, 'viewed');
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmergencyMapScreen(alert: alert),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.map, size: 20),
                  label: const Text('Track Map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
