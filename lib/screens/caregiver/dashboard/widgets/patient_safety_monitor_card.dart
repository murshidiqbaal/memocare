import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/location_tracking_service.dart';

class PatientSafetyMonitorCard extends ConsumerWidget {
  final String patientId;
  final String patientName;
  final String caregiverId;

  const PatientSafetyMonitorCard({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.caregiverId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsStream = ref.watch(realtimeLocationAlertsProvider(caregiverId));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.teal, size: 28),
                const SizedBox(width: 8),
                Text(
                  "$patientName's Safety",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 12),
            alertsStream.when(
              data: (alerts) {
                // Filter alerts for this patient
                final patientAlerts =
                    alerts.where((a) => a.patientId == patientId).toList();

                if (patientAlerts.isEmpty) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle,
                            color: Colors.green, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Patient is within safe zone.',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.green),
                      ),
                    ],
                  );
                }

                final latestAlert = patientAlerts.first;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'GEOFENCE BREACH',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Patient is ${latestAlert.distanceMeters?.toStringAsFixed(0) ?? '?'} meters away from home!",
                        style:
                            TextStyle(fontSize: 15, color: Colors.red.shade900),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            // In a real app, open a live tracking map screen here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Opening live map...')),
                            );
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('View Live Location'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Could not load safety status: $err',
                  style: const TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
