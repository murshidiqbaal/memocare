import 'dart:async';

import 'package:dementia_care_app/core/config/supabase_config.dart';
import 'package:dementia_care_app/core/services/fcm_service.dart';
import 'package:dementia_care_app/core/theme/memocare_theme.dart';
import 'package:dementia_care_app/data/models/reminder.dart';
import 'package:dementia_care_app/features/auth/providers/auth_provider.dart';
import 'package:dementia_care_app/providers/service_providers.dart';
import 'package:dementia_care_app/router/app_router.dart';
import 'package:dementia_care_app/widgets/reliability_wrapper.dart';
import 'package:dementia_care_app/widgets/safety_monitoring_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Hive Initialization
  await Hive.initFlutter();

  // Register Adapters Safely
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ReminderTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ReminderFrequencyAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ReminderStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ReminderAdapter());
  }

  debugPrint('Hive initialized');

  // Open Reminders Box
  await Hive.openBox<Reminder>('reminders');
  debugPrint('Reminder box opened');

  // Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Supabase
  await SupabaseConfig.initialize();

  // Wait for session restoration
  await _waitForInitialSession();

  final container = ProviderContainer();

  // Initialize essential services that need early setup
  try {
    // await container.read(reminderNotificationServiceProvider).init();
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
