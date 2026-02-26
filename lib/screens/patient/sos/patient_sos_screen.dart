import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/sos_service.dart';

class PatientSOSScreen extends ConsumerStatefulWidget {
  const PatientSOSScreen({super.key});

  @override
  ConsumerState<PatientSOSScreen> createState() => _PatientSOSScreenState();
}

class _PatientSOSScreenState extends ConsumerState<PatientSOSScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;

  bool _isCountingDown = false;
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _triggerCountdown() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isCountingDown = true;
      _countdown = 5;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
        HapticFeedback.heavyImpact();
      } else {
        _timer?.cancel();
        _fireEmergencyAlert();
      }
    });
  }

  void _cancelCountdown() {
    _timer?.cancel();
    setState(() => _isCountingDown = false);
    HapticFeedback.vibrate();
  }

  Future<void> _fireEmergencyAlert() async {
    final patientId = Supabase.instance.client.auth.currentUser?.id;
    if (patientId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated.')),
        );
        setState(() => _isCountingDown = false);
      }
      return;
    }

    try {
      final sosService = ref.read(sosServiceProvider);
      await sosService.triggerSOS(patientId: patientId);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('SOS SENT',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: const Text(
                'Help is on the way. Caregivers have been notified.',
                style: TextStyle(fontSize: 18)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _isCountingDown = false);
                },
                child: const Text('OK', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering SOS: $e')),
        );
        setState(() => _isCountingDown = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _isCountingDown ? Colors.red.shade900 : Colors.red.shade50,
      appBar: AppBar(
        title: Text('Emergency SOS',
            style: TextStyle(
                color: _isCountingDown ? Colors.white : Colors.red.shade900,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: _isCountingDown ? Colors.white : Colors.red.shade900),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isCountingDown)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: Text(
                  'Tap the button below if you need emergency help immediately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, color: Colors.black87),
                ),
              ),
            if (_isCountingDown)
              Text(
                '$_countdown',
                style: const TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            const SizedBox(height: 64),
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) => Transform.scale(
                scale: _isCountingDown ? 1.0 : _scaleAnimation.value,
                child: GestureDetector(
                  onTap: _isCountingDown ? null : _triggerCountdown,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          spreadRadius: 10,
                          blurRadius: 30,
                        )
                      ],
                      border: Border.all(color: Colors.white, width: 8),
                    ),
                    child: Center(
                      child: Text(
                        _isCountingDown ? 'SENDING...' : 'SOS',
                        style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 64),
            if (_isCountingDown)
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: _cancelCountdown,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
