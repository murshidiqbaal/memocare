import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final String patientId;

  MemoryViewModel(this._repository, this.patientId) : super(MemoryState()) {
    if (patientId.isNotEmpty) {
      _loadMemories();
    }
  }

  Future<void> _loadMemories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final memories = await _repository.getMemories(patientId);
      state = state.copyWith(memories: memories, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load memories: $e',
      );
    }
  }

  Future<void> addMemory(Memory memory) async {
    state =
        state.copyWith(memories: [memory, ...state.memories], isLoading: false);
    try {
      await _repository.addMemory(memory);
      // Refresh from Supabase to get the server-confirmed URL
      await _loadMemories();
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
      await _loadMemories();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update memory: $e');
    }
  }

  Future<void> deleteMemory(Memory memory) async {
    state = state.copyWith(
        memories: state.memories.where((m) => m.id != memory.id).toList());
    try {
      await _repository.deleteMemory(memory);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete memory: $e');
      // optional: reload memories to sync on failure
      await _loadMemories();
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
  return MemoryViewModel(repo, patientId);
});
