// lib/features/caregiver/presentation/screens/analytics/viewmodels/analytics_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memocare/providers/active_patient_provider.dart';
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
      final now = DateTime.now();
      final range = state.selectedRange;

      DateTime startDate;
      DateTime endDate = now;

      // 1. Determine Date Range
      switch (range) {
        case TimeRange.thisWeek:
          // Start of current week (Monday)
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case TimeRange.lastWeek:
          // Monday of last week
          final lastMon = now.subtract(Duration(days: (now.weekday - 1) + 7));
          startDate = DateTime(lastMon.year, lastMon.month, lastMon.day);
          // Sunday of last week
          final lastSun = lastMon.add(const Duration(days: 6));
          endDate =
              DateTime(lastSun.year, lastSun.month, lastSun.day, 23, 59, 59);
          break;
        case TimeRange.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case TimeRange.last3Months:
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
      }

      final startIso = startDate.toIso8601String();
      final endIso = endDate.toIso8601String();

      // 2. Fetch all required tables in parallel
      final results = await Future.wait([
        db
            .from('reminders')
            .select()
            .eq('patient_id', patientId)
            .gte('created_at', startIso)
            .lte('created_at', endIso),
        db
            .from('game_sessions')
            .select()
            .eq('patient_id', patientId)
            .gte('created_at', startIso)
            .lte('created_at', endIso),
        db
            .from('game_analytics_daily')
            .select()
            .eq('patient_id', patientId)
            .gte('created_at', startIso)
            .lte('created_at', endIso),
        db
            .from('journal_entries')
            .select()
            .eq('patient_id', patientId)
            .gte('created_at', startIso)
            .lte('created_at', endIso),
      ]);

      final remindersRows = (results[0] as List).cast<Map<String, dynamic>>();
      final gameSessionsRows =
          (results[1] as List).cast<Map<String, dynamic>>();
      final safetyEventsRows =
          (results[2] as List).cast<Map<String, dynamic>>();
      final journalRows = (results[3] as List).cast<Map<String, dynamic>>();

      // 3. Compute Statistics

      // Helper to group by day for the "Mon-Sun" 7-day lists
      // We use the Mon-Sun week of the endDate
      final mondayOfRangeWeek =
          endDate.subtract(Duration(days: endDate.weekday - 1));
      final mondayOfRangeWeekStart = DateTime(mondayOfRangeWeek.year,
          mondayOfRangeWeek.month, mondayOfRangeWeek.day);

      // Pre-parse dates to avoid redundant parsing in loops
      final parsedReminders = remindersRows
          .map((r) => {
                'completed': r['completed'] == true,
                'voice_played': r['voice_played'] == true,
                'date': DateTime.parse(r['created_at']),
              })
          .toList();

      final parsedGames = gameSessionsRows
          .map((s) => {
                'date': DateTime.parse(s['created_at']),
              })
          .toList();

      final parsedSafety = safetyEventsRows
          .map((e) => {
                'is_breach': e['event_type'] == 'breach',
                'date': DateTime.parse(e['created_at']),
              })
          .toList();

      final parsedJournal = journalRows
          .map((j) => {
                'has_photo': j['photo_url'] != null,
                'date': DateTime.parse(j['created_at']),
              })
          .toList();

      // -- Reminder Adherence
      final completedReminders =
          parsedReminders.where((r) => r['completed'] == true).length;
      final missedReminders =
          parsedReminders.where((r) => r['completed'] == false).length;
      final voiceReminders =
          parsedReminders.where((r) => r['voice_played'] == true).length;
      final totalReminders = parsedReminders.length;
      final reminderAdherence = totalReminders == 0
          ? 0
          : ((completedReminders / totalReminders) * 100).round();

      final List<int> weeklyAdherenceTrend = List.generate(7, (i) {
        final dayStart = mondayOfRangeWeekStart.add(Duration(days: i));
        final dayEnd =
            dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));

        final dayRows = parsedReminders.where((r) {
          final d = r['date'] as DateTime;
          return d.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
              d.isBefore(dayEnd.add(const Duration(seconds: 1)));
        }).toList();

        if (dayRows.isEmpty) return 0;
        final dayComp = dayRows.where((r) => r['completed'] == true).length;
        return ((dayComp / dayRows.length) * 100).round();
      });

      // -- Game Engagement
      final gamesCount = parsedGames.length;
      final List<int> dailyGameSessions = List.generate(7, (i) {
        final dayStart = mondayOfRangeWeekStart.add(Duration(days: i));
        final dayEnd =
            dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        return parsedGames.where((s) {
          final d = s['date'] as DateTime;
          return d.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
              d.isBefore(dayEnd.add(const Duration(seconds: 1)));
        }).length;
      });

      // -- Safety Breaches
      final breachesCount =
          parsedSafety.where((e) => e['is_breach'] == true).length;
      final List<int> weeklyBreachesTrend = List.generate(7, (i) {
        final dayStart = mondayOfRangeWeekStart.add(Duration(days: i));
        final dayEnd =
            dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        return parsedSafety.where((e) {
          final d = e['date'] as DateTime;
          return e['is_breach'] == true &&
              d.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
              d.isBefore(dayEnd.add(const Duration(seconds: 1)));
        }).length;
      });

      // -- Memory Journal
      final journalPhotoCount =
          parsedJournal.where((j) => j['has_photo'] == true).length;
      final uniqueJournalDays = parsedJournal
          .map((j) {
            final d = j['date'] as DateTime;
            return DateTime(d.year, d.month, d.day);
          })
          .toSet()
          .length;

      final daysInRange = endDate.difference(startDate).inDays + 1;
      final journalConsistency = daysInRange <= 0
          ? 0
          : ((uniqueJournalDays / daysInRange) * 100).round();

      // -- Insights & Suggestions
      final insights = <AnalyticsInsight>[];
      if (reminderAdherence >= 80) {
        insights.add(const AnalyticsInsight(
          text: 'Great adherence! Patient is following reminders consistently.',
          type: InsightType.positive,
        ));
      } else if (reminderAdherence < 50 && totalReminders > 0) {
        insights.add(const AnalyticsInsight(
          text: 'Adherence is low. Consider reviewing reminder schedule.',
          type: InsightType.warning,
        ));
      }
      if (breachesCount > 0) {
        insights.add(AnalyticsInsight(
          text:
              'Patient left the safe zone $breachesCount time(s) during this period.',
          type: InsightType.warning,
        ));
      }
      if (gamesCount >= 5) {
        insights.add(const AnalyticsInsight(
          text: 'Excellent cognitive engagement — games played frequently.',
          type: InsightType.positive,
        ));
      }

      final suggestions = <String>[];
      if (reminderAdherence < 70 && totalReminders > 0) {
        suggestions.add('Set up voice reminders to improve adherence.');
      }
      if (breachesCount > 2) {
        suggestions
            .add('Review safe zone radius — it may need to be expanded.');
      }
      if (gamesCount == 0 && daysInRange >= 1) {
        suggestions
            .add('Encourage the patient to play at least one game daily.');
      }

      final stats = AnalyticsStats(
        reminderAdherencePercent: reminderAdherence.clamp(0, 100),
        remindersMissedCount: missedReminders,
        completedReminders: completedReminders,
        missedReminders: missedReminders,
        voiceRemindersPlayed: voiceReminders,
        weeklyAdherence: weeklyAdherenceTrend,
        gamesScore: gamesCount,
        dailyGameSessions: dailyGameSessions,
        safeZoneBreaches: breachesCount,
        weeklyBreaches: weeklyBreachesTrend,
        journalEntryDays: uniqueJournalDays,
        journalPhotoCount: journalPhotoCount,
        journalConsistencyPercent: journalConsistency.clamp(0, 100),
        insights: insights,
        suggestions: suggestions,
      );

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
    loadData();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(ref),
);
