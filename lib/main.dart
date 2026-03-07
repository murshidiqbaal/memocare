import 'dart:async';

import 'package:dementia_care_app/features/auth/providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/memocare_theme.dart';
import 'providers/service_providers.dart';
import 'routes/app_router.dart';
import 'services/fcm_service.dart';
import 'widgets/reliability_wrapper.dart';
import 'widgets/safety_monitoring_wrapper.dart';

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

  // Wait for session restoration
  await _waitForInitialSession();

  final container = ProviderContainer();

  // Initialize essential services that need early setup
  try {
    await container.read(reminderNotificationServiceProvider).init();
    await container.read(fcmServiceProvider).initialize();
  } catch (e) {
    debugPrint('Service initialization failed: $e');
  }

  // Pre-read persistent state providers
  container.read(sessionPersistenceProvider);
  container.read(authStateChangesProvider);

  FCMService.setNavigatorKey(rootNavigatorKey);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
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
      builder: (context, child) {
        return SafetyMonitoringWrapper(
          child: ReliabilityWrapper(
            child: child!,
          ),
        );
      },
    );
  }
}
