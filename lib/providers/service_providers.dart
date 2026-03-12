import 'package:dementia_care_app/core/services/audio/voice_playback_service.dart';
import 'package:dementia_care_app/core/services/battery_optimization_service.dart';
import 'package:dementia_care_app/core/services/fcm_service.dart';
import 'package:dementia_care_app/core/services/hive_service.dart';
import 'package:dementia_care_app/core/services/memory_query_engine.dart';
import 'package:dementia_care_app/core/services/notification/reminder_notification_service.dart';
import 'package:dementia_care_app/core/services/notification_trigger_service.dart';
import 'package:dementia_care_app/core/services/reminder_reliability_service.dart';
import 'package:dementia_care_app/core/services/tts_service.dart';
import 'package:dementia_care_app/core/services/voice/voice_storage_service.dart';
import 'package:dementia_care_app/core/services/voice_service.dart';
import 'package:dementia_care_app/data/models/reminder.dart';
import 'package:dementia_care_app/data/repositories/caregiver_repository.dart';
import 'package:dementia_care_app/data/repositories/dashboard_repository.dart';
import 'package:dementia_care_app/data/repositories/location_repository.dart';
import 'package:dementia_care_app/data/repositories/memory_repository.dart';
import 'package:dementia_care_app/data/repositories/patient_connection_repository.dart';
import 'package:dementia_care_app/data/repositories/patient_profile_repository.dart';
import 'package:dementia_care_app/data/repositories/patient_repository.dart';
import 'package:dementia_care_app/data/repositories/people_repository.dart';
import 'package:dementia_care_app/data/repositories/reminder_repository.dart';
import 'package:dementia_care_app/data/repositories/sos_repository.dart';
import 'package:dementia_care_app/data/repositories/voice_assistant_repository.dart';
import 'package:dementia_care_app/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care_app/data/datasources/local/local_reminder_datasource.dart';

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
  final voiceService = ref.watch(voiceServiceProvider);
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
