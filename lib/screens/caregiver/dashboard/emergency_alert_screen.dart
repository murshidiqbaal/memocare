import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/sos_alert.dart';
import '../../../../data/repositories/sos_repository.dart';
import '../../../../providers/active_patient_provider.dart';
import '../../../../services/call_service.dart';

class EmergencyAlertScreen extends ConsumerStatefulWidget {
  final SosAlert alert;

  const EmergencyAlertScreen({super.key, required this.alert});

  @override
  ConsumerState<EmergencyAlertScreen> createState() =>
      _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends ConsumerState<EmergencyAlertScreen> {
  bool _isAcknowledging = false;

  Future<void> _acknowledgeEmergency() async {
    if (_isAcknowledging) return;
    setState(() => _isAcknowledging = true);

    try {
      final repo = ref.read(sosRepositoryProvider);
      await repo.acknowledgeAlert(widget.alert.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert acknowledged.'),
          behavior: SnackBarBehavior.floating,
        ),
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
    final linkedPatients = ref.read(linkedPatientsProvider).value ?? [];
    final patient = linkedPatients.cast<dynamic>().firstWhere(
          (p) => p.id == widget.alert.patientId,
          orElse: () => null,
        );

    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient contact details not found.')),
      );
      return;
    }

    try {
      final callService = ref.read(callServiceProvider);
      await callService.callPatient(
        phone: patient.phoneNumber,
        emergencyPhone: patient.emergencyContactPhone,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call failed: $e')),
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
    final linkedPatients = ref.watch(linkedPatientsProvider).value ?? [];
    final patient = linkedPatients.cast<dynamic>().firstWhere(
          (p) => p.id == widget.alert.patientId,
          orElse: () => null,
        );

    final patientName = patient?.fullName ?? 'Patient';

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Emergency Alert',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: Colors.white, size: 80),
                    const SizedBox(height: 20),
                    Text(
                      '$patientName triggered an SOS!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Triggered at: ${DateFormat('h:mm a - MMM d, yyyy').format(widget.alert.triggeredAt)}',
                      style:
                          TextStyle(fontSize: 16, color: Colors.red.shade100),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'ACTION REQUIRED',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      onPressed: _callPatient,
                      icon: Icons.phone,
                      label: 'Call Patient',
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionButton(
                      onPressed: (widget.alert.locationLat != null &&
                              widget.alert.locationLng != null)
                          ? _openMap
                          : null,
                      icon: Icons.map,
                      label: 'Open Map',
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isAcknowledging ? null : _acknowledgeEmergency,
                  child: _isAcknowledging
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('ACKNOWLEDGE ALERT',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Marking as acknowledged lets the patient know you are responding.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
