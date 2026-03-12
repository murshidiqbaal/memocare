// lib/features/caregiver/presentation/screens/analytics/viewmodels/analytics_viewmodel.dart

// import 'package:dementia_care_app/features/caregiver/providers/caregiver_dashboard_providers.dart';
import 'package:dementia_care_app/providers/active_patient_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/analytics_stats.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
class AnalyticsState {
  final bool isLoading;
  final String? error;
  final AnalyticsStats stats;
  final TimeRange selectedRange;

  const AnalyticsState({
    this.isLoading = false,
    this.error,
    this.stats = AnalyticsStats.empty,
    this.selectedRange = TimeRange.thisWeek,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    String? error,
    AnalyticsStats? stats,
    TimeRange? selectedRange,
    bool clearError = false,
  }) =>
      AnalyticsState(
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        stats: stats ?? this.stats,
        selectedRange: selectedRange ?? this.selectedRange,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier(this._ref) : super(const AnalyticsState()) {
    loadData();
  }

  final Ref _ref;

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final patientId = _ref.read(activePatientIdProvider);
      if (patientId == null) {
        state = state.copyWith(isLoading: false, stats: AnalyticsStats.empty);
        return;
      }

      final db = Supabase.instance.client;

      // Fetch from game_analytics
      final rows = await db
          .from('game_analytics')
          .select()
          .eq('patient_id', patientId)
          .limit(1);

      final AnalyticsStats stats;
      if ((rows as List).isEmpty) {
        stats = AnalyticsStats.empty;
      } else {
        stats = AnalyticsStats.fromSupabase(
          gameAnalyticsRow: rows.first as Map<String, dynamic>,
        );
      }

      state = state.copyWith(isLoading: false, stats: stats);
    } on PostgrestException catch (e) {
      debugPrint('[Analytics] loadData: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load analytics: ${e.message}',
      );
    } catch (e) {
      debugPrint('[Analytics] loadData: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error: $e',
      );
    }
  }

  void setTimeRange(TimeRange range) {
    state = state.copyWith(selectedRange: range);
    loadData(); // re-fetch with new range when you add date filtering
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(ref),
);
