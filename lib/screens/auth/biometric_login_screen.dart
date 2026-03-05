import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/biometric_providers.dart';

/// Biometric login screen.
///
/// Flow:
///  1. User enters email.
///  2. Taps "Login with Fingerprint".
///  3. BiometricService resolves userId → checks enrollment → OS prompt → restores session.
///  4. GoRouter redirects to the correct home screen on success.
class BiometricLoginScreen extends ConsumerStatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  ConsumerState<BiometricLoginScreen> createState() =>
      _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    await ref.read(biometricLoginProvider.notifier).loginWithBiometric(email);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for success → GoRouter handles redirect automatically
    ref.listen<BiometricLoginState>(biometricLoginProvider, (prev, next) {
      if (next.status == BiometricLoginStatus.success) {
        // GoRouter redirect will navigate to the correct home screen
        // because the Supabase session is now active.
        context.go('/');
      }
    });

    final state = ref.watch(biometricLoginProvider);
    final isLoading = state.status == BiometricLoginStatus.loading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF004D5C),
              const Color(0xFF00897B),
              const Color(0xFF26C6DA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/login'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Fingerprint icon ──────────────────
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.tealAccent.withOpacity(0.35),
                                  blurRadius: 32,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.fingerprint,
                              size: 64,
                              color:
                                  isLoading ? Colors.tealAccent : Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Title ─────────────────────────────
                        const Text(
                          'Fingerprint Login',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your email to identify your account,\nthen scan your fingerprint.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.72),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Glass card ────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.11),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Email address',
                                    labelStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.75)),
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: Colors.white.withOpacity(0.65)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Colors.tealAccent, width: 1.8),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Colors.orangeAccent),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: Colors.orangeAccent,
                                          width: 1.8),
                                    ),
                                    errorStyle: const TextStyle(
                                        color: Colors.orangeAccent),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.07),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Error message
                                if (state.errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.redAccent
                                              .withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.warning_amber_rounded,
                                            color: Colors.orangeAccent,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            state.errorMessage!,
                                            style: const TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 13,
                                                height: 1.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Submit button
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : _submit,
                                    icon: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.fingerprint,
                                            size: 22),
                                    label: Text(
                                      isLoading
                                          ? 'Verifying…'
                                          : 'Login with Fingerprint',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00897B),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          const Color(0xFF00897B)
                                              .withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Fallback ──────────────────────────
                        TextButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: Icon(Icons.lock_outline,
                              size: 16, color: Colors.white.withOpacity(0.65)),
                          label: Text(
                            'Use email & password instead',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 13),
                          ),
                        ),
                      ],
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
