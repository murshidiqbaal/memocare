import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/service_providers.dart';
import 'routes/app_router.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase (Safely)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // Initialize Supabase
  await SupabaseConfig.initialize();

  final container = ProviderContainer();

  // Initialize Notification Service early (local alarms + channels)
  await container.read(reminderNotificationServiceProvider).init();

  // Register the global navigator key with FCMService so notification
  // taps can navigate to the correct screen from any app state.
  FCMService.setNavigatorKey(rootNavigatorKey);

  // Initialize FCM Service (Safely)
  try {
    final fcmService = container.read(fcmServiceProvider);
    await fcmService.initialize();
  } catch (e) {
    print('FCM initialization failed: $e');
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'MemoCare',
      theme: AppTheme
          .lightTheme, // Applied the requested rich aesthetics (via AppTheme)
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
