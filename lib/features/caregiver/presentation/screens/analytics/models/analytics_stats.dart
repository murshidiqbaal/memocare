enum TimeRange {
  thisWeek,
  lastWeek,
  thisMonth,
  last3Months,
}

enum InsightType {
  positive,
  warning,
  neutral,
}

class AnalyticsInsight {
  final String text;
  final InsightType type;

  const AnalyticsInsight({
    required this.text,
    required this.type,
  });
}

class AnalyticsStats {
  final int reminderAdherencePercent;
  final int remindersMissedCount;

  final int completedReminders;
  final int missedReminders;
  final int voiceRemindersPlayed;

  final List<int> weeklyAdherence;

  final int gamesScore;
  final List<int> dailyGameSessions;

  final int safeZoneBreaches;
  final List<int> weeklyBreaches;

  final int journalEntryDays;
  final int journalPhotoCount;
  final int journalConsistencyPercent;

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

  static const empty = AnalyticsStats(
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
