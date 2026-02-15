import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/memory.dart';
import '../data/repositories/memory_repository.dart';
import 'service_providers.dart';

// Memory Repository Provider
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final supabase = Supabase.instance.client;
  final voiceService = ref.watch(voiceServiceProvider);
  return MemoryRepository(supabase, voiceService);
});

// Memory State for UI
class MemoryListState {
  final List<Memory> memories;
  final bool isLoading;
  final String? error;

  MemoryListState({
    this.memories = const [],
    this.isLoading = false,
    this.error,
  });

  MemoryListState copyWith({
    List<Memory>? memories,
    bool? isLoading,
    String? error,
  }) {
    return MemoryListState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Memory List Notifier for Patient View
class MemoryListNotifier extends StateNotifier<MemoryListState> {
  final MemoryRepository _repository;
  final String patientId;

  MemoryListNotifier(this._repository, this.patientId)
      : super(MemoryListState()) {
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.init();
      final memories = _repository.getMemories(patientId);
      state = state.copyWith(memories: memories, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load memories: $e',
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.syncMemories(patientId);
      final memories = _repository.getMemories(patientId);
      state = state.copyWith(memories: memories, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sync memories: $e',
      );
    }
  }
}

// Provider for Patient Memory List
final memoryListProvider =
    StateNotifierProvider.family<MemoryListNotifier, MemoryListState, String>(
        (ref, patientId) {
  final repository = ref.watch(memoryRepositoryProvider);
  return MemoryListNotifier(repository, patientId);
});

// Memory Upload State for Caregiver
class MemoryUploadState {
  final bool isUploading;
  final String? error;
  final bool success;

  MemoryUploadState({
    this.isUploading = false,
    this.error,
    this.success = false,
  });

  MemoryUploadState copyWith({
    bool? isUploading,
    String? error,
    bool? success,
  }) {
    return MemoryUploadState(
      isUploading: isUploading ?? this.isUploading,
      error: error,
      success: success ?? this.success,
    );
  }
}

// Memory Upload Notifier for Caregiver
class MemoryUploadNotifier extends StateNotifier<MemoryUploadState> {
  final MemoryRepository _repository;

  MemoryUploadNotifier(this._repository) : super(MemoryUploadState());

  Future<void> uploadMemory(Memory memory) async {
    state = state.copyWith(isUploading: true, error: null, success: false);
    try {
      await _repository.init();
      await _repository.addMemory(memory);
      state = state.copyWith(isUploading: false, success: true);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to upload memory: $e',
      );
    }
  }

  Future<void> updateMemory(Memory memory) async {
    state = state.copyWith(isUploading: true, error: null, success: false);
    try {
      await _repository.init();
      await _repository.updateMemory(memory);
      state = state.copyWith(isUploading: false, success: true);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to update memory: $e',
      );
    }
  }

  Future<void> deleteMemory(String id) async {
    state = state.copyWith(isUploading: true, error: null, success: false);
    try {
      await _repository.init();
      await _repository.deleteMemory(id);
      state = state.copyWith(isUploading: false, success: true);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to delete memory: $e',
      );
    }
  }

  void reset() {
    state = MemoryUploadState();
  }
}

// Provider for Memory Upload
final memoryUploadProvider =
    StateNotifierProvider<MemoryUploadNotifier, MemoryUploadState>((ref) {
  final repository = ref.watch(memoryRepositoryProvider);
  return MemoryUploadNotifier(repository);
});
