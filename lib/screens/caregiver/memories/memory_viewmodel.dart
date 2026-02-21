import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/memory.dart';
import '../../../../data/repositories/memory_repository.dart';
import '../../../../providers/service_providers.dart';

class MemoryState {
  final List<Memory> memories;
  final bool isLoading;
  final String? error;

  MemoryState({this.memories = const [], this.isLoading = false, this.error});

  MemoryState copyWith({
    List<Memory>? memories,
    bool? isLoading,
    String? error,
  }) {
    return MemoryState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MemoryViewModel extends StateNotifier<MemoryState> {
  final MemoryRepository _repository;
  final SupabaseClient _supabase;
  final String patientId;

  MemoryViewModel(this._repository, this._supabase, this.patientId)
      : super(MemoryState()) {
    if (patientId.isNotEmpty) {
      _loadMemories();
    }
  }

  Future<void> _loadMemories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Always pull fresh from Supabase first
      await _fetchFromSupabase();
    } catch (e) {
      // Fallback to local Hive cache if network fails
      await _repository.init();
      final cached = _repository.getMemories(patientId);
      state = state.copyWith(
        memories: cached,
        isLoading: false,
        error: cached.isEmpty ? 'Failed to load memories: $e' : null,
      );
    }
  }

  Future<void> _fetchFromSupabase() async {
    final data = await _supabase
        .from('memory_cards')
        .select()
        .eq('patient_id', patientId)
        .order('event_date', ascending: false);

    final memories = (data as List)
        .map((m) => Memory.fromJson(m as Map<String, dynamic>))
        .toList();

    // Update Hive cache
    await _repository.init();
    for (final m in memories) {
      await _repository.localBox.put(m.id, m.copyWith(isSynced: true));
    }

    state = state.copyWith(memories: memories, isLoading: false);
  }

  Future<void> addMemory(Memory memory) async {
    state =
        state.copyWith(memories: [memory, ...state.memories], isLoading: false);
    try {
      await _repository.addMemory(memory);
      // Refresh from Supabase to get the server-confirmed URL
      await _fetchFromSupabase();
    } catch (e) {
      state = state.copyWith(error: 'Failed to save memory: $e');
    }
  }

  Future<void> updateMemory(Memory memory) async {
    final updatedList =
        state.memories.map((m) => m.id == memory.id ? memory : m).toList();
    state = state.copyWith(memories: updatedList);
    try {
      await _repository.updateMemory(memory);
      await _fetchFromSupabase();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update memory: $e');
    }
  }

  Future<void> deleteMemory(String id) async {
    state = state.copyWith(
        memories: state.memories.where((m) => m.id != id).toList());
    try {
      await _repository.deleteMemory(id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete memory: $e');
    }
  }

  Future<void> refresh() async {
    await _loadMemories();
  }
}

final memoryViewModelProvider =
    StateNotifierProvider.family<MemoryViewModel, MemoryState, String>(
        (ref, patientId) {
  final repo = ref.watch(memoryRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return MemoryViewModel(repo, supabase, patientId);
});
