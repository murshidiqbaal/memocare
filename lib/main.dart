import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'data/models/caregiver_patient_link.dart';
import 'data/models/game_session.dart';
import 'data/models/memory.dart';
import 'data/models/patient_profile.dart';
import 'data/models/person.dart';
import 'data/models/reminder.dart';
import 'data/models/voice_query.dart';
import 'providers/service_providers.dart';
import 'routes/app_router.dart';

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

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(ReminderTypeAdapter());
  Hive.registerAdapter(ReminderFrequencyAdapter());
  Hive.registerAdapter(ReminderStatusAdapter());
  Hive.registerAdapter(VoiceQueryAdapter());
  Hive.registerAdapter(CaregiverPatientLinkAdapter());
  Hive.registerAdapter(PatientProfileAdapter());
  Hive.registerAdapter(PersonAdapter());
  Hive.registerAdapter(MemoryAdapter());
  Hive.registerAdapter(GameSessionAdapter());

  await Hive.openBox<PatientProfile>('patient_profiles');

  final container = ProviderContainer();

  // Initialize Notification Service early
  await container.read(reminderNotificationServiceProvider).init();

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
