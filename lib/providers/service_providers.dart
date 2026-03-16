import 'package:memocare/core/services/audio/voice_playback_service.dart';
import 'package:memocare/core/services/battery_optimization_service.dart';
import 'package:memocare/core/services/fcm_service.dart';
import 'package:memocare/core/services/hive_service.dart';
import 'package:memocare/core/services/memory_query_engine.dart';
import 'package:memocare/services/reminder_notification_service.dart';
import 'package:memocare/core/services/notification_trigger_service.dart';
import 'package:memocare/core/services/reminder_reliability_service.dart';
import 'package:memocare/core/services/tts_service.dart';
import 'package:memocare/core/services/voice/voice_storage_service.dart';
import 'package:memocare/core/services/voice_service.dart';
import 'package:memocare/data/models/reminder.dart';
import 'package:memocare/data/repositories/caregiver_repository.dart';
import 'package:memocare/data/repositories/dashboard_repository.dart';
import 'package:memocare/data/repositories/location_repository.dart';
import 'package:memocare/data/repositories/memory_repository.dart';
import 'package:memocare/data/repositories/patient_connection_repository.dart';
import 'package:memocare/data/repositories/patient_profile_repository.dart';
import 'package:memocare/data/repositories/patient_repository.dart';
import 'package:memocare/data/repositories/people_repository.dart';
import 'package:memocare/data/repositories/reminder_repository.dart';
import 'package:memocare/data/repositories/sos_repository.dart';
import 'package:memocare/data/repositories/voice_assistant_repository.dart';
import 'package:memocare/providers/supabase_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:memocare/data/datasources/local/local_reminder_datasource.dart';


export 'supabase_provider.dart';

final reminderBoxProvider = FutureProvider<Box<Reminder>>((ref) async {
  return await HiveService.openReminderBox();
});

final voiceStorageServiceProvider = Provider<VoiceStorageService>((ref) {
  return VoiceStorageService(Supabase.instance.client);
});

final localReminderDatasourceProvider =
    Provider<LocalReminderDatasource>((ref) {
  return LocalReminderDatasource();
});

// FCM Service Provider
final fcmServiceProvider = Provider<FCMService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return FCMService(supabase);
});

// Reminder Notification Service Provider
final reminderNotificationServiceProvider =
    Provider<ReminderNotificationService>((ref) {
  return ReminderNotificationService();
});

// Notification Trigger Service Provider (FCM push → Supabase Edge Function)
final notificationTriggerProvider = Provider<NotificationTriggerService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return NotificationTriggerService(supabase);
});

// Reminder Repository Provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final voiceService = ref.watch(voiceStorageServiceProvider);
  final notificationService = ref.watch(reminderNotificationServiceProvider);
  final localDatasource = ref.watch(localReminderDatasourceProvider);
  return ReminderRepository(
    supabase,
    voiceService,
    notificationService,
    localDatasource,
  );
});

// People Repository Provider
final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final voiceService = ref.watch(voiceServiceProvider);
  return PeopleRepository(supabase, voiceService);
});

// Memory Repository Provider
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final voiceService = ref.watch(voiceServiceProvider);
  return MemoryRepository(supabase, voiceService);
});

// Voice Service Provider
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return VoiceService(supabase);
});

// Caregiver Repository Provider
final caregiverRepositoryProvider = Provider<CaregiverRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CaregiverRepository(supabase);
});

// ---------------------------------------------------------------------------
// caregiverIdProvider
// ---------------------------------------------------------------------------
// Session-cached provider that resolves caregiver_profiles.id for the current
// auth user.  This is the SINGLE SOURCE OF TRUTH for the FK value that must
// be used in `reminders.caregiver_id`.
//
// NEVER use `supabase.auth.currentUser!.id` directly as caregiver_id —
// that is auth.users.id, which references the wrong table.
//
// Usage:
//   final caregiverId = await ref.read(caregiverIdProvider.future);
// ---------------------------------------------------------------------------
final caregiverIdProvider = FutureProvider<String>((ref) async {
  ref.keepAlive(); // Cache result for the session — avoids repeated DB round-trips

  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw Exception('[caregiverIdProvider] No authenticated user found.');
  }

  // Always resolve from caregiver_profiles.user_id — never use user.id directly.
  final row = await supabase
      .from('caregiver_profiles')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();

  if (row != null) {
    final id = row['id'] as String;
    debugPrint('[caregiverIdProvider] ✅ Resolved caregiver_profiles.id = $id '
        '(auth.uid = ${user.id})');
    return id;
  }

  // Auto-create the profile row if it is missing (first-time login edge case).
  debugPrint('[caregiverIdProvider] ⚠️ No caregiver_profiles row found for '
      'auth.uid=${user.id} — auto-creating...');
  final fullName = user.userMetadata?['full_name'] as String? ?? 'Caregiver';
  final inserted = await supabase
      .from('caregiver_profiles')
      .insert({'user_id': user.id, 'full_name': fullName})
      .select('id')
      .single();

  final newId = inserted['id'] as String;
  debugPrint('[caregiverIdProvider] ✅ Created caregiver_profiles.id = $newId');
  return newId;
});

// ---------------------------------------------------------------------------
// patientIdProvider
// ---------------------------------------------------------------------------
// Session-cached provider that resolves patients.id for the current auth user.
// Used when the patient is also the logged-in user (self-managed reminders).
//
// Usage:
//   final patientId = await ref.read(patientIdProvider.future);
// ---------------------------------------------------------------------------
final patientIdProvider = FutureProvider<String?>((ref) async {
  ref.keepAlive();

  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final row = await supabase
      .from('patients')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();

  if (row == null) return null;
  final id = row['id'] as String;
  debugPrint('[patientIdProvider] ✅ Resolved patients.id = $id '
      '(auth.uid = ${user.id})');
  return id;
});

// Voice Assistant Repository Provider
final voiceAssistantRepositoryProvider =
    Provider<VoiceAssistantRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return VoiceAssistantRepository(supabase);
});

// Safety Repository Provider (Aliased for compatibility)
final safetyRepositoryProvider = Provider<SosRepository>((ref) {
  return ref.watch(sosRepositoryProvider);
});

// Dashboard Repository Provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DashboardRepository(supabase);
});

// Patient Connection Repository Provider
final patientConnectionRepositoryProvider =
    Provider<PatientConnectionRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PatientConnectionRepository(supabase);
});

// Patient Profile Repository Provider
final patientProfileRepositoryProvider =
    Provider<PatientProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PatientProfileRepository(supabase);
});

// Patient Repository Provider
final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PatientRepository(supabase);
});
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LocationRepository(supabase);
});

// TTS Service Provider
final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});

// Memory Query Engine Provider (Keyword based)
final memoryQueryEngineProvider = Provider<MemoryQueryEngine>((ref) {
  final reminderRepo = ref.watch(reminderRepositoryProvider);
  final peopleRepo = ref.watch(peopleRepositoryProvider);
  final memoryRepo = ref.watch(memoryRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);

  return MemoryQueryEngine(
    reminderRepo,
    peopleRepo,
    memoryRepo,
    supabase,
  );
});

// Voice Playback Service Provider
// keepAlive ensures the same AudioPlayer instance is reused across screens,
// preventing duplicate audio playing and memory leaks.
final voicePlaybackServiceProvider = Provider<VoicePlaybackService>((ref) {
  final service = VoicePlaybackService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Generic Query Engine Provider
// Defaulting to legacy engine as LLM is removed
final activeMemoryQueryEngineProvider = Provider<MemoryQueryEngine>((ref) {
  return ref.watch(memoryQueryEngineProvider);
});

// Battery Optimization Service Provider
final batteryOptimizationServiceProvider =
    Provider<BatteryOptimizationService>((ref) {
  return BatteryOptimizationService();
});

// Reminder Reliability Service Provider
final reminderReliabilityServiceProvider =
    Provider<ReminderReliabilityService>((ref) {
  return ReminderReliabilityService();
});

// caregiverUserIdProvider(patientId)
// Fetches and caches the auth user ID (auth.users.id) of the caregiver linked to a patient.
final caregiverUserIdProvider =
    FutureProvider.family<String?, String>((ref, patientId) async {
  final patientRepo = ref.watch(patientRepositoryProvider);
  return await patientRepo.getCaregiverUserId(patientId);
});

/// patientUserIdProvider(patientId)
/// Returns the patient's own auth user ID (auth.users.id) for a given patient record.
final patientUserIdProvider =
    FutureProvider.family<String?, String>((ref, patientId) async {
  final supabase = Supabase.instance.client;
  try {
    final res = await supabase
        .from('patients')
        .select('user_id')
        .eq('id', patientId)
        .maybeSingle();
    return res?['user_id'] as String?;
  } catch (e) {
    debugPrint('[patientUserIdProvider] Error: $e');
    return null;
  }
});
