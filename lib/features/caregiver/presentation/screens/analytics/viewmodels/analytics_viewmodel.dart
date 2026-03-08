import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analytics_stats.dart';

class AnalyticsState {
  final AnalyticsStats stats;
  final bool isLoading;
  final TimeRange selectedRange;

  AnalyticsState({
    required this.stats,
    this.isLoading = false,
    this.selectedRange = TimeRange.thisWeek,
  });

  AnalyticsState copyWith({
    AnalyticsStats? stats,
    bool? isLoading,
    TimeRange? selectedRange,
  }) {
    return AnalyticsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      selectedRange: selectedRange ?? this.selectedRange,
    );
  }
}

class AnalyticsViewModel extends StateNotifier<AnalyticsState> {
  AnalyticsViewModel() : super(AnalyticsState(stats: AnalyticsStats())) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);

    // Simulate aggregation delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate Dummy Data based on selected range
    // In real app: fetch from DB/Repository based on range dates
    final newStats = _generateDummyStats(state.selectedRange);

    state = state.copyWith(
      stats: newStats,
      isLoading: false,
    );
  }

  void setTimeRange(TimeRange range) {
    state = state.copyWith(selectedRange: range);
    loadData();
  }

  AnalyticsStats _generateDummyStats(TimeRange range) {
    // 1. Base Numbers Simulation
    bool isWeek = range == TimeRange.thisWeek || range == TimeRange.lastWeek;

    // Reminders
    int total = isWeek ? 28 : 120;
    int completed = isWeek ? (range == TimeRange.thisWeek ? 24 : 20) : 100;
    int missed = total - completed;
    int adherence = ((completed / total) * 100).round();

    // Safety
    int breaches =
        range == TimeRange.thisWeek ? 0 : (range == TimeRange.lastWeek ? 2 : 5);
    bool isSafe = true;

    // Insights Generation (Rule-Based)
    List<InsightItem> insights = [];
    if (adherence < 80) {
      insights.add(InsightItem(
          text: 'Reminder adherence dropped below 80%.',
          type: InsightType.warning));
    } else {
      insights.add(InsightItem(
          text: 'Great reminder adherence this week.',
          type: InsightType.positive));
    }

    if (breaches > 0) {
      insights.add(InsightItem(
          text: '$breaches safe-zone breaches detected.',
          type: InsightType.warning));
    } else {
      insights.add(InsightItem(
          text: 'Patient remained safe in zone all week.',
          type: InsightType.positive));
    }

    if (isWeek && completed > 20) {
      insights.add(InsightItem(
          text: 'Game engagement improving steadily.',
          type: InsightType.positive));
    }

    // Suggestions Generation
    List<String> suggestions = [];
    if (missed > 2) {
      suggestions
          .add('Consider checking medication routine or snooze settings.');
    }
    if (breaches > 1) {
      suggestions.add('Review safe-zone radius settings in Safety tab.');
    }
    suggestions
        .add('Encourage daily memory journal entry to boost cognitive recall.');

    return AnalyticsStats(
      reminderAdherencePercent: adherence,
      remindersMissedCount: missed,
      completedReminders: completed,
      missedReminders: missed,
      voiceRemindersPlayed: isWeek ? 12 : 45,
      weeklyAdherence: [3, 4, 4, 3, 2, 4, 4], // Mock daily counts

      gamesScore: range == TimeRange.thisWeek ? 850 : 720,
      avgGameDurationMinutes: 15,
      dailyGameSessions: [1, 2, 0, 1, 3, 2, 1],

      safeZoneBreaches: breaches,
      consecutiveSafeDays: 5,
      isCurrentlySafe: isSafe,
      weeklyBreaches: [0, 0, 0, breaches, 0, 0, 0], // Put breaches on Wed/Thu

      journalEntryDays: 4,
      journalPhotoCount: 12,
      journalConsistencyPercent: 60,

      insights: insights,
      suggestions: suggestions,
    );
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsViewModel, AnalyticsState>((ref) {
  return AnalyticsViewModel();
});
