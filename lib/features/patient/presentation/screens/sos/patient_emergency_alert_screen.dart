import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memocare/features/patient/data/sos_repository.dart';
// import '../../data/sos_repository.dart';

class PatientEmergencyAlertScreen extends ConsumerStatefulWidget {
  const PatientEmergencyAlertScreen({super.key});

  @override
  ConsumerState<PatientEmergencyAlertScreen> createState() =>
      _PatientEmergencyAlertScreenState();
}

class _PatientEmergencyAlertScreenState
    extends ConsumerState<PatientEmergencyAlertScreen>
    with TickerProviderStateMixin {
  int countdown = 5;
  Timer? countdownTimer;
  bool isSending = false;
  late AnimationController pulseController;
  late AnimationController scaleController;
  late TextEditingController noteController;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    noteController = TextEditingController();
    scrollController = ScrollController();
    _startCountdown();
    // Haptic feedback on screen open
    HapticFeedback.heavyImpact();
  }

  void _initializeAnimations() {
    // Pulsing animation for the countdown number
    pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    // Scale animation for warning icon
    scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    pulseController.dispose();
    scaleController.dispose();
    noteController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          if (countdown > 0) {
            countdown--;
            // Vibrate on each second
            HapticFeedback.mediumImpact();
          }
        });

        if (countdown == 0) {
          t.cancel();
          _sendSOS();
        }
      }
    });
  }

  Future<void> _sendSOS() async {
    if (!mounted) return;

    setState(() {
      isSending = true;
    });

    try {
      // Strong haptic feedback when sending
      HapticFeedback.heavyImpact();

      // Use the repository to send the SOS alert with note
      final repository = ref.read(patientSosRepositoryProvider);
      final noteText = noteController.text.trim().isEmpty
          ? 'Manual Emergency SOS Alert'
          : noteController.text.trim();

      await repository.sendSOSAlert(note: noteText);

      debugPrint('SOS sent successfully via repository');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Emergency alert sent to caregivers'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error sending SOS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _cancelSOS() {
    // Soft haptic on cancel
    HapticFeedback.lightImpact();
    countdownTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from dismissing without canceling timer
        if (countdown > 0) {
          _cancelSOS();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Emergency Header
                  const Text(
                    '🚨 EMERGENCY 🚨',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scaled Warning Icon
                  ScaleTransition(
                    scale: Tween(begin: 0.9, end: 1.1).animate(
                      CurvedAnimation(
                          parent: scaleController, curve: Curves.ease),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 150,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Countdown or Sending State
                  if (countdown > 0) ...[
                    const Text(
                      'Sending SOS in',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ScaleTransition(
                      scale: Tween(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Text(
                        '$countdown',
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sending...',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Note Input Section (only show during countdown)
                  if (countdown > 0 && !isSending)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildNoteInput(),
                    ),

                  const SizedBox(height: 32),

                  // Cancel Button (only show during countdown)
                  if (countdown > 0 && !isSending)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ElevatedButton(
                        onPressed: _cancelSOS,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade900,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        child: const Text(
                          'Cancel SOS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                  // Safety Info
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      countdown > 0
                          ? 'Press Cancel within ${countdown}s to stop the alert'
                          : 'Alert has been sent to your caregivers',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s happening?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: noteController,
          maxLines: 3,
          minLines: 2,
          enabled: countdown > 0 && !isSending,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Describe your emergency situation...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white,
                width: 2.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white38, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Colors.white,
        ),
        const SizedBox(height: 8),
        Text(
          'Your caregivers will see this information',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
