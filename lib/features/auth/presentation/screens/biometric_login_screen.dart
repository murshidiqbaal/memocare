import 'package:dementia_care_app/features/auth/providers/auth_provider.dart';
import 'package:dementia_care_app/features/auth/providers/biometric_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen biometric authentication screen.
///
/// Flow:
///   1. Automatically tries to authenticate on first mount.
///   2. Shows animated fingerprint icon during loading.
///   3. On success → GoRouter redirect handles navigation (auth state updated).
///   4. On failure → shows error message + retry button.
class BiometricLoginScreen extends ConsumerStatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  ConsumerState<BiometricLoginScreen> createState() =>
      _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Kick off biometric auth automatically on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerLogin();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerLogin() {
    ref.read(biometricLoginProvider.notifier).login();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(biometricLoginProvider);

    // Navigate once success + auth state is propagated
    ref.listen(biometricLoginProvider, (_, next) {
      if (next.isSuccess) {
        // Small delay so the Supabase auth stream has time to emit
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          // Invalidate profile so GoRouter re-evaluates redirect
          ref.invalidate(userProfileProvider);
        });
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── App branding ─────────────────────────────────────────
                const Icon(
                  Icons.favorite_rounded,
                  size: 40,
                  color: Color(0xFF6D28D9),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MemoCare',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 64),

                // ── Fingerprint icon ──────────────────────────────────────
                _buildFingerprintIcon(state, colorScheme),
                const SizedBox(height: 32),

                // ── Status message ────────────────────────────────────────
                _buildStatusMessage(state),
                const SizedBox(height: 48),

                // ── Retry / back buttons ──────────────────────────────────
                ..._buildActions(context, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFingerprintIcon(
      BiometricLoginState state, ColorScheme colorScheme) {
    final color = state.isFailure
        ? Colors.redAccent
        : state.isSuccess
            ? Colors.greenAccent
            : Colors.white;

    return ScaleTransition(
      scale:
          state.isLoading ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: state.isLoading
            ? const Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white70,
                ),
              )
            : Icon(
                state.isSuccess
                    ? Icons.check_circle_outline_rounded
                    : state.isFailure
                        ? Icons.error_outline_rounded
                        : Icons.fingerprint_rounded,
                size: 64,
                color: color,
              ),
      ),
    );
  }

  Widget _buildStatusMessage(BiometricLoginState state) {
    final message = state.isLoading
        ? 'Authenticating…'
        : state.isSuccess
            ? 'Authenticated!'
            : state.isFailure
                ? (state.errorMessage ?? 'Authentication failed.')
                : 'Authenticate to continue';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        message,
        key: ValueKey(message),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: state.isFailure
              ? Colors.redAccent.shade100
              : Colors.white.withValues(alpha: 0.85),
          height: 1.5,
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, BiometricLoginState state) {
    if (state.isLoading || state.isSuccess) return [];

    return [
      if (state.isFailure) ...[
        FilledButton.icon(
          onPressed: () {
            ref.read(biometricLoginProvider.notifier).reset();
            _triggerLogin();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6D28D9),
            foregroundColor: Colors.white,
            minimumSize: const Size(200, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      TextButton(
        onPressed: () {
          ref.read(biometricLoginProvider.notifier).reset();
          context.go('/login');
        },
        child: Text(
          'Use password instead',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      ),
    ];
  }
}
