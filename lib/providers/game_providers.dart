import 'package:dementia_care_app/data/repositories/game_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/game_session.dart';

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
    await loadSessions();
  }

  /// Load sessions from remote
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _repository.fetchRemoteSessions(patientId);
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
      await _repository.uploadSession(session);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _repository.deleteRemoteSession(sessionId);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh
  Future<void> refresh() async {
    await loadSessions();
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
