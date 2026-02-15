import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/game_session.dart';
import '../data/repositories/game_repository.dart';

// Game Repository Provider
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(Supabase.instance.client);
});

// Game Sessions State
class GameSessionsState {
  final List<GameSession> sessions;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? stats;

  GameSessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.stats,
  });

  GameSessionsState copyWith({
    List<GameSession>? sessions,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? stats,
  }) {
    return GameSessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

// Game Sessions Notifier
class GameSessionsNotifier extends StateNotifier<GameSessionsState> {
  final GameRepository _repository;
  final String patientId;

  GameSessionsNotifier(this._repository, this.patientId)
      : super(GameSessionsState()) {
    _init();
  }

  Future<void> _init() async {
    await _repository.init();
    await loadSessions();
  }

  /// Load sessions from local storage
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _repository.getLocalSessions(patientId);
      final stats = await _repository.getGameStats(patientId);
      state = state.copyWith(
        sessions: sessions,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Save a new game session
  Future<void> saveSession(GameSession session) async {
    try {
      // Save locally first (offline-first)
      await _repository.saveLocalSession(session);

      // Try to sync to remote
      try {
        await _repository.uploadSession(session);
        // Mark as synced
        final synced = session.copyWith(isSynced: true);
        await _repository.saveLocalSession(synced);
      } catch (e) {
        // If upload fails, keep as unsynced - will sync later
        print('Failed to upload session, will retry later: $e');
      }

      // Reload sessions
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _repository.deleteLocalSession(sessionId);

      // Try to delete from remote
      try {
        await _repository.deleteRemoteSession(sessionId);
      } catch (e) {
        print('Failed to delete from remote: $e');
      }

      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Sync with remote
  Future<void> sync() async {
    try {
      await _repository.fullSync(patientId);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh (reload + sync)
  Future<void> refresh() async {
    await sync();
  }
}

// Game Sessions Provider (per patient)
final gameSessionsProvider = StateNotifierProvider.family<GameSessionsNotifier,
    GameSessionsState, String>(
  (ref, patientId) {
    final repository = ref.watch(gameRepositoryProvider);
    return GameSessionsNotifier(repository, patientId);
  },
);
