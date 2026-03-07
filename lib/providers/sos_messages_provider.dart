import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/sos_messages.dart';
import '../data/repositories/sos_messages_repository.dart';
import 'service_providers.dart';

// SOS Messages Repository Provider
final sosMessagesRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SosMessagesRepository(supabase);
});

// Stream provider for a specific patient's SOS messages
final patientSosMessagesProvider =
    StreamProvider.family<List<SosMessage>, String>((ref, patientId) async* {
  final repository = ref.watch(sosMessagesRepositoryProvider);
  yield* repository.getPatientSosMessagesStream(patientId);
});

// Stream provider for all unread SOS messages
final allUnreadSosMessagesProvider =
    StreamProvider<List<SosMessage>>((ref) async* {
  final repository = ref.watch(sosMessagesRepositoryProvider);
  yield* repository.getAllUnreadSosMessagesStream();
});

// Provider for unread SOS messages count
final unreadSosMessagesCountProvider = StreamProvider<int>((ref) async* {
  final repository = ref.watch(sosMessagesRepositoryProvider);
  yield* repository.getUnreadSosMessagesCountStream();
});

// SOS Messages State Notifier
class SosMessagesStateNotifier
    extends StateNotifier<AsyncValue<List<SosMessage>>> {
  final SosMessagesRepository repository;

  SosMessagesStateNotifier(this.repository) : super(const AsyncValue.loading());

  // Mark a SOS message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await repository.markSosMessageAsRead(messageId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Mark all messages as read for a patient
  Future<void> markPatientMessagesAsRead(String patientId) async {
    try {
      await repository.markPatientSosMessagesAsRead(patientId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Delete a SOS message
  Future<void> deleteSosMessage(String messageId) async {
    try {
      await repository.deleteSosMessage(messageId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// SOS Messages Controller Provider
final sosMessagesControllerProvider = StateNotifierProvider<
    SosMessagesStateNotifier, AsyncValue<List<SosMessage>>>((ref) {
  final repository = ref.watch(sosMessagesRepositoryProvider);
  return SosMessagesStateNotifier(repository);
});
