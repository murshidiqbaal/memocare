import 'dart:async';

import 'package:dementia_care_app/providers/sos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientSOSScreen extends ConsumerStatefulWidget {
  const PatientSOSScreen({super.key});

  @override
  ConsumerState<PatientSOSScreen> createState() => _PatientSOSScreenState();
}

class _PatientSOSScreenState extends ConsumerState<PatientSOSScreen>
    with SingleTickerProviderStateMixin {
  // ── Breathing animation ───────────────────────────────────────────────────
  late final AnimationController _breathCtrl;
  late final Animation<double> _scaleAnim;

  // ── Countdown state (local UI only) ──────────────────────────────────────
  bool _isCountingDown = false;
  int _countdown = 5;
  Timer? _timer;

  // ── Prevent double-fire ───────────────────────────────────────────────────
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Countdown flow ────────────────────────────────────────────────────────

  void _startCountdown() {
    if (_isCountingDown || _fired) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isCountingDown = true;
      _countdown = 5;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() => _countdown--);
        HapticFeedback.heavyImpact();
      } else {
        t.cancel();
        _fireSOS();
      }
    });
  }

  void _cancelCountdown() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isCountingDown = false;
        _fired = false;
      });
    }
    HapticFeedback.vibrate();
  }

  Future<void> _fireSOS() async {
    if (_fired) return;
    _fired = true;

    if (!mounted) return;
    setState(() => _isCountingDown = false);

    // Delegate to the Riverpod controller — it handles dedup + offline
    await ref.read(sosControllerProvider.notifier).triggerSOS();
  }

  // ── Watch controller and react to state changes ───────────────────────────

  void _onStateChange(SosState? prev, SosState next) {
    if (!mounted) return;
    switch (next) {
      case SosSent():
        _fired = false;
        _showSuccessDialog(next.wasQueued);
      case SosError():
        _fired = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS failed: ${next.message}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      default:
        break;
    }
  }

  void _showSuccessDialog(bool wasQueued) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('SOS SENT',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          wasQueued
              ? 'You are offline. Your SOS has been queued and will be sent automatically when connectivity restores.'
              : 'Help is on the way.\nAll linked caregivers have been notified.',
          style: const TextStyle(fontSize: 17),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen for controller state transitions — never inside build tree
    ref.listen<SosState>(sosControllerProvider, _onStateChange);

    final sosState = ref.watch(sosControllerProvider);
    final isSending = sosState is SosSending;

    return Scaffold(
      backgroundColor:
          _isCountingDown ? Colors.red.shade900 : Colors.red.shade50,
      appBar: AppBar(
        title: Text(
          'Emergency SOS',
          style: TextStyle(
            color: _isCountingDown ? Colors.white : Colors.red.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: _isCountingDown ? Colors.white : Colors.red.shade900,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Instruction or countdown number ───────────────────────────
              if (!_isCountingDown && !isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
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
                    color: Colors.white,
                  ),
                ),
              if (isSending)
                Column(
                  children: [
                    const CircularProgressIndicator(color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Sending alert…',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

              const SizedBox(height: 64),

              // ── Big SOS button ────────────────────────────────────────────
              if (!isSending)
                AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _isCountingDown ? 1.0 : _scaleAnim.value,
                    child: GestureDetector(
                      onTap: _isCountingDown ? null : _startCountdown,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              spreadRadius: 10,
                              blurRadius: 30,
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 8),
                        ),
                        child: Center(
                          child: Text(
                            _isCountingDown ? 'SENDING...' : 'SOS',
                            style: const TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 64),

              // ── Cancel button ─────────────────────────────────────────────
              if (_isCountingDown)
                SizedBox(
                  width: 200,
                  child: FilledButton(
                    onPressed: _cancelCountdown,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
