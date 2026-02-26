import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/sos_alert.dart';
import '../../../../services/sos_service.dart';
import '../../../../services/call_service.dart';
import '../../../../features/patient_selection/providers/patient_selection_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyAlertScreen extends ConsumerStatefulWidget {
  final SosAlert alert;

  const EmergencyAlertScreen({super.key, required this.alert});

  @override
  ConsumerState<EmergencyAlertScreen> createState() =>
      _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends ConsumerState<EmergencyAlertScreen> {
  bool _isAcknowledging = false;

  void _acknowledgeEmergency() async {
    setState(() => _isAcknowledging = true);
    try {
      final sosService = ref.read(sosServiceProvider);
      await sosService.updateSosStatus(widget.alert.id, 'acknowledged');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert acknowledged.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to acknowledge: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAcknowledging = false);
    }
  }

  void _callPatient() async {
    final linkedPatients = ref.read(patientSelectionProvider).linkedPatients;
    final patient = linkedPatients.firstWhere(
      (p) => p.id == widget.alert.patientId,
      orElse: () => throw Exception('Patient not found'),
    );

    try {
      final callService = ref.read(callServiceProvider);
      await callService.callPatient(
        phone: patient.phoneNumber,
        emergencyPhone: patient.emergencyContactPhone,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())), // Error message from CallService
      );
    }
  }

  void _openMap() async {
    final lat = widget.alert.locationLat;
    final lng = widget.alert.locationLng;
    if (lat == null || lng == null) return;

    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkedPatients = ref.read(patientSelectionProvider).linkedPatients;
    final patientName = linkedPatients
        .firstWhere(
          (p) => p.id == widget.alert.patientId,
          orElse: () => throw Exception(),
        )
        .fullName;

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Emergency Alert',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26, spreadRadius: 0, blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    '$patientName triggered an SOS!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${DateFormat('h:mm a - MMM d, yyyy').format(widget.alert.triggeredAt)}',
                    style: TextStyle(fontSize: 16, color: Colors.red.shade100),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _callPatient,
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Patient',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: (widget.alert.locationLat != null &&
                            widget.alert.locationLng != null)
                        ? _openMap
                        : null,
                    icon: const Icon(Icons.map),
                    label:
                        const Text('Open Map', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onPressed: _isAcknowledging ? null : _acknowledgeEmergency,
                child: _isAcknowledging
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ACKNOWLEDGE ALERT',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
