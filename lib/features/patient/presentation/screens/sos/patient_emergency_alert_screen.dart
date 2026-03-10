import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/sos_alert_controller.dart';

class PatientEmergencyAlertScreen extends ConsumerStatefulWidget {
  const PatientEmergencyAlertScreen({super.key});

  @override
  ConsumerState<PatientEmergencyAlertScreen> createState() =>
      _PatientEmergencyAlertScreenState();
}

class _PatientEmergencyAlertScreenState
    extends ConsumerState<PatientEmergencyAlertScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start countdown automatically when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sosAlertControllerProvider.notifier).startCountdown();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('SOS Sent'),
        content: const Text('Your caregiver has been notified.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosAlertControllerProvider);
    final controller = ref.read(sosAlertControllerProvider.notifier);

    // Listen for success state to show dialog
    ref.listen<SosAlertState>(sosAlertControllerProvider, (previous, next) {
      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        _showSuccessDialog();
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.errorMessage}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large warning icon
              const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Emergency Alert',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'A message will be sent to your caregiver in ${sosState.countdownSeconds} seconds',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),

              // Countdown Display
              if (sosState.countdownSeconds > 0 && !sosState.isSending)
                Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Text(
                    '${sosState.countdownSeconds}',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

              if (sosState.isSending)
                const CircularProgressIndicator(color: Colors.white),

              const SizedBox(height: 48),

              // Note field
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Send SOS Button
              GestureDetector(
                onTap: sosState.isSending
                    ? null
                    : () => controller.sendSOSAlert(note: _noteController.text),
                child: Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sosState.isSending ? Colors.grey : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 8),
                  ),
                  child: const Text(
                    'SEND SOS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Cancel Button
              TextButton(
                onPressed: () {
                  controller.cancelCountdown();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
