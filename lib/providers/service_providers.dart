import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/patient_profile.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/patient_profile_repository.dart';
import '../data/repositories/people_repository.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/repositories/voice_assistant_repository.dart';
import '../services/audio/voice_playback_service.dart';
import '../services/memory_query_engine.dart';
import '../services/notification/reminder_notification_service.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final reminderNotificationServiceProvider =
    Provider<ReminderNotificationService>((ref) {
  final service = ReminderNotificationService();
  // We initialize it in main.dart, but having it here allows access
  return service;
});

final voicePlaybackServiceProvider = Provider<VoicePlaybackService>((ref) {
  return VoicePlaybackService();
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return VoiceService(supabase);
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final voiceService = ref.watch(voiceServiceProvider);
  return ReminderRepository(supabase, voiceService);
});

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final voiceService = ref.watch(voiceServiceProvider);
  return PeopleRepository(supabase, voiceService);
});

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final voiceService = ref.watch(voiceServiceProvider);
  return MemoryRepository(supabase, voiceService);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DashboardRepository(supabase);
});

final ttsServiceProvider = Provider<TTSService>((ref) {
  return TTSService();
});

final voiceAssistantRepositoryProvider =
    Provider<VoiceAssistantRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return VoiceAssistantRepository(supabase);
});

final memoryQueryEngineProvider = Provider<MemoryQueryEngine>((ref) {
  final reminderRepo = ref.watch(reminderRepositoryProvider);
  final peopleRepo = ref.watch(peopleRepositoryProvider);
  final memoryRepo = ref.watch(memoryRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return MemoryQueryEngine(reminderRepo, peopleRepo, memoryRepo, supabase);
});

final patientProfileRepositoryProvider =
    Provider<PatientProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final box = Hive.box<PatientProfile>('patient_profiles');
  return PatientProfileRepository(supabase, box);
});
