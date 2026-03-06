import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/memocare_theme.dart';
import 'package:dementia_care_app/features/auth/providers/auth_provider.dart';
import 'providers/service_providers.dart';
import 'routes/app_router.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // Supabase
  await SupabaseConfig.initialize();

  // ✅ Wait for Supabase to restore session from storage BEFORE
  // building the app. This is the root cause — without this await,
  // GoRouter evaluates redirect while session is still null.
  await _waitForInitialSession();

  final container = ProviderContainer();

  await container.read(reminderNotificationServiceProvider).init();

  container.read(sessionPersistenceProvider);
  container.read(authStateChangesProvider);

  FCMService.setNavigatorKey(rootNavigatorKey);

  try {
    final fcmService = container.read(fcmServiceProvider);
    await fcmService.initialize();
  } catch (e) {
    print('FCM initialization failed: $e');
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

// ✅ Waits for the FIRST auth event from Supabase stream.
// This guarantees session is either restored or confirmed null
// before the app renders — so GoRouter redirect has correct state.
Future<void> _waitForInitialSession() async {
  final completer = Completer<void>();

  final sub = Supabase.instance.client.auth.onAuthStateChange.listen(
    (event) {
      print('🔍 INITIAL AUTH EVENT: ${event.event}');
      print('🔍 INITIAL SESSION: ${event.session?.user.id ?? 'null'}');

      if (!completer.isCompleted) completer.complete();
    },
    onError: (_) {
      if (!completer.isCompleted) completer.complete();
    },
  );

  // Safety timeout — if stream never emits, continue after 3s
  await completer.future.timeout(
    const Duration(seconds: 3),
    onTimeout: () {
      print('⚠️ Session restore timeout — continuing without session');
    },
  );

  await sub.cancel();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'MemoCare',
      theme: MemoCareTheme.lightTheme,
      darkTheme: MemoCareTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
