import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../providers/providers.dart'; // import linkedPatientsProvider
import '../../data/models/sos_alert.dart';
import '../controllers/sos_controller.dart';
import 'live_map_screen.dart';

class CaregiverAlertScreen extends ConsumerWidget {
  const CaregiverAlertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlerts = ref.watch(activeAlertsStreamProvider);
    final linkedPatients = ref.watch(linkedPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Alerts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: activeAlerts.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'All patients are safe',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];

              // Find patient name from linked patients list
              // linkedPatients is AsyncValue<List<Patient>>
              final patientName = linkedPatients.valueOrNull
                      ?.cast<
                          dynamic>() // Use dynamic cast if type is confused or just ensure iterable
                      .firstWhere(
                        (p) =>
                            p.id == alert.patientId, // Patient model uses 'id'
                        orElse: () => null,
                      )
                      ?.fullName ?? // Patient model uses 'fullName'
                  'Unknown Patient';

              return _buildAlertCard(context, alert, patientName);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAlertCard(
      BuildContext context, SosAlert alert, String patientName) {
    final timeStr = DateFormat('h:mm a').format(alert.createdAt.toLocal());

    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMERGENCY: $patientName',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Triggered at $timeStr',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('TRACK LIVE LOCATION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveMapScreen(
                        alert: alert,
                        patientName: patientName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
