import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/location_tracking_service.dart';
import '../../home_location/patient_set_home_location_screen.dart';

class SafetyStatusCard extends ConsumerWidget {
  final String patientId;

  const SafetyStatusCard({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusStatus = ref.watch(safetyStatusProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            statusStatus.when(
              data: (status) {
                print('Safety status update: $status');
                String title;
                Color color;
                IconData icon;
                String subtitle;

                switch (status) {
                  case 0:
                    title = 'Safe at Home';
                    color = Colors.green;
                    icon = Icons.home_filled;
                    subtitle = 'You are within your safe zone.';
                    break;
                  case 1:
                    title = 'Near Boundary';
                    color = Colors.orange;
                    icon = Icons.warning_amber_rounded;
                    subtitle = 'You are near the edge of your safe zone.';
                    break;
                  case 2:
                    title = 'Outside Safe Zone';
                    color = Colors.red;
                    icon = Icons.emergency;
                    subtitle = 'Alert sent to your caregiver.';
                    break;
                  default:
                    title = 'Safe at Home';
                    color = Colors.green;
                    icon = Icons.home_filled;
                    subtitle = 'You are within your safe zone.';
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.grey, size: 36),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Location status unavailable. Tap below to set home.',
                          style: TextStyle(fontSize: 16))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PatientSetHomeLocationScreen(patientId: patientId),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Set Home Location',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
