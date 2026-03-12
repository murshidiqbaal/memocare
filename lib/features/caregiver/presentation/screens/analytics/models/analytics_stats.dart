// lib/features/caregiver/presentation/screens/analytics/models/analytics_stats.dart

enum TimeRange { thisWeek, lastWeek, thisMonth, last3Months }

enum InsightType { positive, warning, neutral }

class AnalyticsInsight {
  final String text;
  final InsightType type;
  const AnalyticsInsight({required this.text, required this.type});
}

/// Full analytics snapshot for a patient over a given [TimeRange].
class AnalyticsStats {
  // ── Reminder / adherence ─────────────────────────────────────────────────
  final int reminderAdherencePercent; // 0–100
  final int remindersMissedCount;
  final int completedReminders;
  final int missedReminders;
  final int voiceRemindersPlayed;
  final List<int> weeklyAdherence; // 7 values, Mon–Sun

  // ── Games / cognitive ────────────────────────────────────────────────────
  final int gamesScore; // gamesPlayedThisWeek from game_analytics
  final List<int> dailyGameSessions; // 7 values

  // ── Safety ───────────────────────────────────────────────────────────────
  final int safeZoneBreaches;
  final List<int> weeklyBreaches; // 7 values

  // ── Memory journal ───────────────────────────────────────────────────────
  final int journalEntryDays;
  final int journalPhotoCount;
  final int journalConsistencyPercent;

  // ── Insights / suggestions ───────────────────────────────────────────────
  final List<AnalyticsInsight> insights;
  final List<String> suggestions;

  const AnalyticsStats({
    required this.reminderAdherencePercent,
    required this.remindersMissedCount,
    required this.completedReminders,
    required this.missedReminders,
    required this.voiceRemindersPlayed,
    required this.weeklyAdherence,
    required this.gamesScore,
    required this.dailyGameSessions,
    required this.safeZoneBreaches,
    required this.weeklyBreaches,
    required this.journalEntryDays,
    required this.journalPhotoCount,
    required this.journalConsistencyPercent,
    required this.insights,
    required this.suggestions,
  });

  /// Build from the `game_analytics` Supabase row.
  /// Fields that aren't in game_analytics are set to sensible defaults;
  /// extend this factory once you add more columns to the table.
  factory AnalyticsStats.fromSupabase({
    required Map<String, dynamic> gameAnalyticsRow,
  }) {
    final adherence =
        (gameAnalyticsRow['adherence_percentage'] as num? ?? 0).toInt();
    final breaches =
        (gameAnalyticsRow['safezone_breaches_this_week'] as num? ?? 0).toInt();
    final gamesPlayed =
        (gameAnalyticsRow['games_played_this_week'] as num? ?? 0).toInt();
    final journalConsistency =
        (gameAnalyticsRow['journal_consistency'] as num? ?? 0).toInt();

    // Derive insights from real values
    final insights = <AnalyticsInsight>[];
    if (adherence >= 80) {
      insights.add(const AnalyticsInsight(
        text: 'Great adherence! Patient is following reminders consistently.',
        type: InsightType.positive,
      ));
    } else if (adherence < 50) {
      insights.add(const AnalyticsInsight(
        text: 'Adherence is low. Consider reviewing reminder schedule.',
        type: InsightType.warning,
      ));
    }
    if (breaches > 0) {
      insights.add(AnalyticsInsight(
        text: 'Patient left the safe zone $breaches time(s) this week.',
        type: InsightType.warning,
      ));
    }
    if (gamesPlayed >= 5) {
      insights.add(const AnalyticsInsight(
        text: 'Excellent cognitive engagement — games played every day.',
        type: InsightType.positive,
      ));
    }

    final suggestions = <String>[];
    if (adherence < 70) {
      suggestions.add('Set up voice reminders to improve adherence.');
    }
    if (breaches > 2) {
      suggestions.add('Review safe zone radius — it may need to be expanded.');
    }
    if (gamesPlayed == 0) {
      suggestions.add('Encourage the patient to play at least one game daily.');
    }

    return AnalyticsStats(
      reminderAdherencePercent: adherence.clamp(0, 100),
      remindersMissedCount: ((100 - adherence) / 10).round(),
      completedReminders: adherence,
      missedReminders: 100 - adherence,
      voiceRemindersPlayed: gamesPlayed, // best proxy until dedicated column
      weeklyAdherence:
          List.generate(7, (i) => (adherence - i * 2).clamp(0, 100)),
      gamesScore: gamesPlayed,
      dailyGameSessions: List.generate(7, (i) => (gamesPlayed / 7).round()),
      safeZoneBreaches: breaches,
      weeklyBreaches: List.generate(7, (i) => i < breaches ? 1 : 0),
      journalEntryDays: (journalConsistency / 14).round(),
      journalPhotoCount: (journalConsistency / 10).round(),
      journalConsistencyPercent: journalConsistency.clamp(0, 100),
      insights: insights,
      suggestions: suggestions,
    );
  }

  static const AnalyticsStats empty = AnalyticsStats(
        reminderAdherencePercent: 0,
        remindersMissedCount: 0,
        completedReminders: 0,
        missedReminders: 0,
        voiceRemindersPlayed: 0,
        weeklyAdherence: [0, 0, 0, 0, 0, 0, 0],
        gamesScore: 0,
        dailyGameSessions: [0, 0, 0, 0, 0, 0, 0],
        safeZoneBreaches: 0,
        weeklyBreaches: [0, 0, 0, 0, 0, 0, 0],
        journalEntryDays: 0,
        journalPhotoCount: 0,
        journalConsistencyPercent: 0,
        insights: [],
        suggestions: [],
      );
}
