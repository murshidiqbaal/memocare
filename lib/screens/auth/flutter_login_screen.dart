import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

class FlutterLoginScreen extends ConsumerWidget {
  const FlutterLoginScreen({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(WidgetRef ref, LoginData data) async {
    final result = await ref.read(authRepositoryProvider).signIn(
          email: data.name,
          password: data.password,
        );

    return result.fold(
      (failure) => failure.message,
      (success) => null, // Success means no error message
    );
  }

  Future<String?> _signupUser(WidgetRef ref, SignupData data) async {
    final role = data.additionalSignupData?['role']?.toLowerCase() ?? 'patient';
    final validRoles = ['patient', 'caregiver'];

    // Simple validation for role
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
    // Placeholder for password recovery
    return 'Password recovery is not implemented yet.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlutterLogin(
      title: 'MemoCare',
      // logo: const AssetImage('assets/images/logo.png'), // No logo available
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
          color: Colors.black, // Ensure text is visible
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
        if (value == null || value.isEmpty) {
          return 'Email is required';
        }
        if (!value.contains('@')) {
          return 'Enter a valid email address';
        }
        return null;
      },
      passwordValidator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
      onSubmitAnimationCompleted: () {
        // AppRouter will handle navigation based on auth state change
      },
    );
  }
}
