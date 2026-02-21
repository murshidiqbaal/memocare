import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/patient_profile.dart'; // Added
import '../data/repositories/caregiver_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/patient_connection_repository.dart';
import '../data/repositories/patient_profile_repository.dart'; // Added
import '../data/repositories/people_repository.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/repositories/safety_repository.dart';
import '../data/repositories/voice_assistant_repository.dart';
import '../services/audio/voice_playback_service.dart'; // Added
import '../services/fcm_service.dart';
import '../services/llm_memory_query_engine.dart';
import '../services/memory_query_engine.dart';
import '../services/notification/reminder_notification_service.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
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

// Reminder Repository Provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final voiceService = ref.watch(voiceServiceProvider);
  return ReminderRepository(supabase, voiceService);
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

// Safety Repository Provider
final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SafetyRepository(supabase);
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
  // Box is opened in main.dart
  final box = Hive.box<PatientProfile>('patient_profiles');
  return PatientProfileRepository(supabase, box);
});

// TTS Service Provider
final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});

// Legacy Memory Query Engine Provider (Keyword based)
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

// Enhanced LLM Memory Query Engine Provider (Gemini based)
final llmMemoryQueryEngineProvider = Provider<LLMMemoryQueryEngine>((ref) {
  final reminderRepo = ref.watch(reminderRepositoryProvider);
  final peopleRepo = ref.watch(peopleRepositoryProvider);
  final memoryRepo = ref.watch(memoryRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);

  // Use API key from .env file
  final apiKey = dotenv.env['GOOGLE_GEMINI_API_KEY'] ?? '';

  return LLMMemoryQueryEngine(
    reminderRepo,
    peopleRepo,
    memoryRepo,
    supabase,
    apiKey,
  );
});

// Voice Playback Service Provider
final voicePlaybackServiceProvider = Provider<VoicePlaybackService>((ref) {
  return VoicePlaybackService();
});

// Generic Query Engine Provider - can be toggled in settings or based on availability
// For now, defaulting to LLM if API key is present
final activeMemoryQueryEngineProvider = Provider<dynamic>((ref) {
  final llmEngine = ref.watch(llmMemoryQueryEngineProvider);
  final legacyEngine = ref.watch(memoryQueryEngineProvider);

  final hasApiKey = dotenv.env['GOOGLE_GEMINI_API_KEY'] != null &&
      dotenv.env['GOOGLE_GEMINI_API_KEY']!.isNotEmpty;

  return hasApiKey ? llmEngine : legacyEngine;
});
