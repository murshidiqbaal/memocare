import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/memory.dart';
import '../../../../data/repositories/memory_repository.dart';
import '../../../../providers/service_providers.dart';

class MemoryState {
  final List<Memory> memories;
  final bool isLoading;

  MemoryState({this.memories = const [], this.isLoading = false});
}

class MemoryViewModel extends StateNotifier<MemoryState> {
  final MemoryRepository _repository;
  final String patientId;

  MemoryViewModel(this._repository, this.patientId) : super(MemoryState()) {
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    state = MemoryState(isLoading: true, memories: state.memories);
    await _repository.init();
    final memories = _repository.getMemories(patientId);
    state = MemoryState(memories: memories, isLoading: false);
  }

  Future<void> addMemory(Memory memory) async {
    // Optimistic update
    state =
        MemoryState(memories: [...state.memories, memory], isLoading: false);
    await _repository.addMemory(memory);
    _loadMemories();
  }

  Future<void> updateMemory(Memory memory) async {
    final updatedList =
        state.memories.map((m) => m.id == memory.id ? memory : m).toList();
    state = MemoryState(memories: updatedList, isLoading: false);
    await _repository.updateMemory(memory);
    _loadMemories();
  }

  Future<void> deleteMemory(String id) async {
    final updatedList = state.memories.where((m) => m.id != id).toList();
    state = MemoryState(memories: updatedList, isLoading: false);
    await _repository.deleteMemory(id);
  }

  Future<void> refresh() async {
    state = MemoryState(memories: state.memories, isLoading: true);
    await _repository.syncMemories(patientId);
    _loadMemories();
  }
}

final memoryViewModelProvider =
    StateNotifierProvider.family<MemoryViewModel, MemoryState, String>(
        (ref, patientId) {
  final repo = ref.watch(memoryRepositoryProvider);
  return MemoryViewModel(repo, patientId);
});
