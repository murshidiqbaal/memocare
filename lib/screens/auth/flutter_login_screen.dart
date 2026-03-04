import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/biometric_providers.dart';
import 'enable_biometric_dialog.dart';

/// Login screen with biometric-enable flow.
///
/// After successful email+password login:
///  1. If role == 'patient': checks biometric hardware availability
///  2. If biometric is available AND NOT yet enabled: shows [EnableBiometricDialog]
///  3. Router handles home navigation
class FlutterLoginScreen extends ConsumerWidget {
  const FlutterLoginScreen({super.key});

  Future<String?> _authUser(WidgetRef ref, LoginData data) async {
    final result = await ref.read(authRepositoryProvider).signIn(
          email: data.name,
          password: data.password,
        );

    return result.fold(
      (failure) => failure.message,
      (success) => null,
    );
  }

  Future<String?> _signupUser(WidgetRef ref, SignupData data) async {
    final role = data.additionalSignupData?['role']?.toLowerCase() ?? 'patient';
    final validRoles = ['patient', 'caregiver'];

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
      (success) => null,
    );
  }

  Future<String?> _recoverPassword(String name) async {
    return 'Password recovery is not implemented yet.';
  }

  /// After login animation completes: check if we should offer biometric.
  Future<void> _onLoginComplete(BuildContext context, WidgetRef ref) async {
    final profile = await ref.read(userProfileProvider.future);

    // Only offer biometric to patients
    if (profile?.role != 'patient') {
      // Navigate will be handled by GoRouter redirect
      return;
    }

    final biometricAvailable =
        await ref.read(biometricAvailableProvider.future);
    final biometricAlreadyEnabled =
        await ref.read(biometricEnabledProvider.future);

    if (biometricAvailable && !biometricAlreadyEnabled && context.mounted) {
      await showEnableBiometricDialog(context, ref, profile!.id);
    }

    // GoRouter redirect will fire based on auth state change
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlutterLogin(
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
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      onSubmitAnimationCompleted: () => _onLoginComplete(context, ref),
    );
  }
}
