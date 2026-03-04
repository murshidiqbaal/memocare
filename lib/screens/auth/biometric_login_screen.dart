import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/biometric_providers.dart';

/// Full-screen biometric login screen shown to patients on subsequent app opens.
///
/// Design principles (dementia-friendly):
///  - Single large fingerprint icon
///  - Minimal text, plain language
///  - Large touch targets (min 56×56dp)
///  - Calm teal palette
///  - No technical jargon
class BiometricLoginScreen extends ConsumerStatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  ConsumerState<BiometricLoginScreen> createState() =>
      _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-trigger biometric on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricLogin());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricLogin() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final error = await ref
        .read(biometricControllerProvider.notifier)
        .loginWithBiometric();

    if (!mounted) return;

    if (error == null) {
      // Success — GoRouter will redirect based on updated auth state
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _errorMessage = error;
    });
  }

  void _goToPasswordLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state change → navigate away automatically
    ref.listen(authStateChangesProvider, (_, next) {
      if (next.valueOrNull?.session != null && mounted) {
        // GoRouter redirect will handle the right page
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF9), // calm teal tint
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── App Logo ──
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.psychology,
                  size: 44,
                  color: Colors.teal.shade600,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'MemoCare',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(),

              // ── Fingerprint Button ──
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) {
                  return Transform.scale(
                    scale: _isAuthenticating ? _pulseAnim.value : 1.0,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: _tryBiometricLogin,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.teal.shade300,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.18),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 96,
                      color: _isAuthenticating
                          ? Colors.teal.shade600
                          : Colors.teal.shade400,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Instruction Text ──
              Text(
                _isAuthenticating
                    ? 'Checking your fingerprint…'
                    : 'Touch the fingerprint\nbutton to open MemoCare',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade800,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              // ── Error Message ──
              if (_errorMessage != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.orange.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Spacer(),

              // ── Use Password Instead ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _goToPasswordLogin,
                  icon: const Icon(Icons.lock_outline, size: 22),
                  label: const Text(
                    'Use Password Instead',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: BorderSide(color: Colors.teal.shade300, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
