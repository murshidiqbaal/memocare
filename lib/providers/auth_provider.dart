import 'dart:async';

import 'package:memocare/data/models/user/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/datasources/remote/remote_auth_datasource.dart';
import '../data/repositories/auth_repository.dart';
// import '../models/user/profile.dart';
// import '../providers/biometric_providers.dart';

final remoteAuthDatasourceProvider = Provider<RemoteAuthDatasource>((ref) {
  return RemoteAuthDatasource(Supabase.instance.client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(remoteAuthDatasourceProvider));
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value?.session?.user ??
      ref.watch(authRepositoryProvider).currentUser;
});

final userProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final result = await ref.watch(authRepositoryProvider).getProfile(user.id);
    return result.fold(
      (failure) {
        // If it's a genuine network error etc., propagate as AsyncError
        throw Exception('Profile load failed: ${failure.message}');
      },
      (profile) => profile, // may be null if record hasn't been created yet
    );
  } catch (e) {
    // Re-throw so state becomes AsyncError for debugging
    rethrow;
  }
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    result.fold(
      (l) => state = AsyncError(l.message, StackTrace.current),
      (r) => state = const AsyncData(null),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signUp(
          email: email,
          password: password,
          role: role,
          fullName: fullName,
        );
    result.fold(
      (l) => state = AsyncError(l.message, StackTrace.current),
      (r) => state = const AsyncData(null),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signOut();
    result.fold(
      (l) => state = AsyncError(l.message, StackTrace.current),
      (r) => state = const AsyncData(null),
    );
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

/// A provider that listens to auth state changes and ensures the secure storage
/// is kept in sync with the current Supabase session if biometrics are enabled.
final sessionPersistenceProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<AuthState>>(authStateChangesProvider,
      (prev, next) async {
    final session = next.valueOrNull?.session;
    // if (session != null) {
    //   final storage = ref.read(secureStorageServiceProvider);
    //   final isEnabled = await storage.isBiometricEnabled();
    //   if (isEnabled) {
    //     await storage.saveSession(
    //       accessToken: session.accessToken,
    //       refreshToken: session.refreshToken ?? '',
    //     );
    //   }
    // }
  });
});
