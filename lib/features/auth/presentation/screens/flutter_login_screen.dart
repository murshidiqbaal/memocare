import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dementia_care_app/features/auth/providers/auth_provider.dart';
import 'package:dementia_care_app/features/auth/providers/biometric_providers.dart';

/// Login screen with biometric-enable flow.
///
/// After successful email+password login:
/// 1. Credentials are saved to [FlutterSecureStorage].
/// 2. GoRouter redirect handles navigation based on role.
/// 3. Fingerprint hint leads to [BiometricLoginScreen].
class FlutterLoginScreen extends ConsumerWidget {
  const FlutterLoginScreen({super.key});

  /// Email + password login — also saves credentials for biometric reuse.
  Future<String?> _authUser(WidgetRef ref, LoginData data) async {
    final result = await ref.read(authRepositoryProvider).signIn(
          email: data.name,
          password: data.password,
        );

    return result.fold(
      (failure) => failure.message,
      (_) async {
        // ✅ Persist credentials securely for future biometric logins
        final storage = ref.read(secureStorageProvider);
        await saveCredentials(
          storage,
          email: data.name,
          password: data.password,
        );
        return null; // null = success
      },
    );
  }

  /// Signup
  Future<String?> _signupUser(WidgetRef ref, SignupData data) async {
    final role = data.additionalSignupData?['role']?.toLowerCase() ?? 'patient';
    const validRoles = ['patient', 'caregiver'];

    if (!validRoles.contains(role)) {
      return 'Role must be either "patient" or "caregiver"';
    }

    final result = await ref.read(authRepositoryProvider).signUp(
          email: data.name ?? '',
          password: data.password ?? '',
          role: role,
          fullName: data.additionalSignupData?['fullName'] ?? '',
        );

    return result.fold(
      (failure) => failure.message,
      (_) => null,
    );
  }

  /// Password recovery placeholder
  Future<String?> _recoverPassword(String name) async {
    return 'Password recovery is not implemented yet.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAvailable =
        ref.watch(biometricAvailableProvider).valueOrNull ?? false;

    return Stack(
      children: [
        FlutterLogin(
          title: 'MemoCare',
          onLogin: (loginData) => _authUser(ref, loginData),
          onSignup: (signupData) => _signupUser(ref, signupData),
          onRecoverPassword: _recoverPassword,
          theme: LoginTheme(
            primaryColor: Colors.teal,
            accentColor: Colors.teal.shade700,
            errorColor: Colors.deepOrange,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            bodyStyle: const TextStyle(
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.underline,
            ),
            textFieldStyle: const TextStyle(
              color: Colors.black,
            ),
          ),
          additionalSignupFields: const [
            UserFormField(
              keyName: 'fullName',
              displayName: 'Full Name',
              userType: LoginUserType.name,
            ),
            UserFormField(
              keyName: 'role',
              displayName: 'Role (patient/caregiver)',
              userType: LoginUserType.text,
            ),
          ],
          messages: LoginMessages(
            additionalSignUpFormDescription:
                'Enter your details. For Role, type "patient" or "caregiver".',
          ),
          userValidator: (value) {
            if (value == null || value.isEmpty) return 'Email is required';
            if (!value.contains('@')) return 'Enter a valid email address';
            return null;
          },
          passwordValidator: (value) {
            if (value == null || value.isEmpty) return 'Password is required';
            if (value.length < 6)
              return 'Password must be at least 6 characters';
            return null;
          },
        ),

        // ── Fingerprint hint (only shown when biometrics are available) ──
        if (biometricAvailable)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => context.go('/biometric-login'),
                child: const _FingerprintHint(),
              ),
            ),
          ),
      ],
    );
  }
}

/// Fingerprint hint badge shown at the bottom of the login screen.
class _FingerprintHint extends StatelessWidget {
  const _FingerprintHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.fingerprint,
            size: 40,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use fingerprint login',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.65),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
