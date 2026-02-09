import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/people_repository.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/repositories/voice_assistant_repository.dart';
import '../services/memory_query_engine.dart';
import '../services/notification_service.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.init();
  return service;
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
