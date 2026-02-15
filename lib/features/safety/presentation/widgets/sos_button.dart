import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/sos_controller.dart';

class SosButton extends ConsumerWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlert = ref.watch(activeSosAlertProvider);
    final sosControllerState = ref.watch(sosControllerProvider);

    final bool isTracking = activeAlert != null;

    return Center(
      child: GestureDetector(
        onTap: () => _handlePress(context, ref, isTracking),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: isTracking ? 180 : 150,
          height: isTracking ? 180 : 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTracking ? Colors.red.shade700 : Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: isTracking ? 30 : 15,
                spreadRadius: isTracking ? 10 : 2,
              ),
            ],
          ),
          child: sosControllerState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isTracking
                          ? Icons.location_on_outlined
                          : Icons.emergency_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTracking ? 'SOS ACTIVE' : 'SOS',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isTracking)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Sharing Location...',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handlePress(
      BuildContext context, WidgetRef ref, bool isActive) async {
    if (isActive) {
      // Show dialog to cancel
      final bool? cancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel SOS?'),
          content: const Text(
              'Are you safe now? This will stop sharing your location.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Active'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('I am Safe'),
            ),
          ],
        ),
      );

      if (cancel == true) {
        ref.read(sosControllerProvider.notifier).cancelSos();
      }
    } else {
      // Show dialog to trigger
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Emergency SOS'),
          content: const Text(
            'This will alert your caregivers and share your current location immediately.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SEND ALERT'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(sosControllerProvider.notifier).triggerSos();
      }
    }
  }
}
