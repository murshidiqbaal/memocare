import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientEmergencyAlertScreen extends StatefulWidget {
  const PatientEmergencyAlertScreen({super.key});

  @override
  State<PatientEmergencyAlertScreen> createState() =>
      _PatientEmergencyAlertScreenState();
}

class _PatientEmergencyAlertScreenState
    extends State<PatientEmergencyAlertScreen> with TickerProviderStateMixin {
  int countdown = 5;
  Timer? countdownTimer;
  bool isSending = false;
  late AnimationController pulseController;
  late AnimationController scaleController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint('Error: No authenticated user found');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Not authenticated. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      isSending = true;
    });

    try {
      // Strong haptic feedback when sending
      HapticFeedback.heavyImpact();

      // Step 1: Resolve internal patient_id from Auth ID
      final patientResponse = await supabase
          .from('patients')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (patientResponse == null) {
        debugPrint('Error: Patient profile not found for user ${user.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Patient profile not found.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      final patientId = patientResponse['id'] as String;

      // Step 2: Try to get real-time location (don't block if fails)
      double lat = 0.0;
      double lng = 0.0;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (e) {
        debugPrint('Location lookup failed for SOS: $e');
      }

      // Step 3: Look up linked caregiver using internal patientId
      final linkResponse = await supabase
          .from('caregiver_patient_links')
          .select('caregiver_id')
          .eq('patient_id', patientId)
          .maybeSingle();

      if (linkResponse == null) {
        debugPrint('No caregiver linked to patient $patientId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No caregiver linked. Please contact support.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      final caregiverId = linkResponse['caregiver_id'] as String;

      // Step 4: Insert SOS message into 'sos_messages' table
      await supabase.from('sos_messages').insert({
        'patient_id': patientId,
        'caregiver_id': caregiverId,
        'status': 'pending',
        'triggered_at': DateTime.now().toUtc().toIso8601String(),
        'location_lat': lat,
        'location_lng': lng,
        'note': 'Manual Emergency SOS Alert',
      });

      debugPrint('SOS sent successfully');

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
    } on PostgrestException catch (e) {
      debugPrint('Postgres error sending SOS: ${e.message} | code: ${e.code}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SOS: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Unexpected error sending SOS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending SOS. Please try again.'),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

                const SizedBox(height: 48),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
