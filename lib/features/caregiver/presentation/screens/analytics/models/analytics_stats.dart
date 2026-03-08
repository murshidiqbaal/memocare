enum TimeRange { thisWeek, lastWeek, thisMonth }

class AnalyticsStats {
  // Reminders
  final int reminderAdherencePercent;
  final int remindersMissedCount;
  final int completedReminders;
  final int missedReminders;
  final int voiceRemindersPlayed;
  final List<int> weeklyAdherence; // 7 days of completion counts

  // Games
  final int gamesScore;
  final int avgGameDurationMinutes;
  final List<int> dailyGameSessions; // 7 days count

  // Safety
  final int safeZoneBreaches;
  final int consecutiveSafeDays;
  final bool isCurrentlySafe;
  final List<int> weeklyBreaches; // 7 days count

  // Journal
  final int journalEntryDays;
  final int journalPhotoCount;
  final int journalConsistencyPercent;

  // Insights
  final List<InsightItem> insights;
  final List<String> suggestions;

  AnalyticsStats({
    this.reminderAdherencePercent = 0,
    this.remindersMissedCount = 0,
    this.completedReminders = 0,
    this.missedReminders = 0,
    this.voiceRemindersPlayed = 0,
    this.weeklyAdherence = const [],
    this.gamesScore = 0,
    this.avgGameDurationMinutes = 0,
    this.dailyGameSessions = const [],
    this.safeZoneBreaches = 0,
    this.consecutiveSafeDays = 0,
    this.isCurrentlySafe = true,
    this.weeklyBreaches = const [],
    this.journalEntryDays = 0,
    this.journalPhotoCount = 0,
    this.journalConsistencyPercent = 0,
    this.insights = const [],
    this.suggestions = const [],
  });

  AnalyticsStats copyWith({
    int? reminderAdherencePercent,
    int? remindersMissedCount,
    int? completedReminders,
    int? missedReminders,
    int? voiceRemindersPlayed,
    List<int>? weeklyAdherence,
    int? gamesScore,
    int? avgGameDurationMinutes,
    List<int>? dailyGameSessions,
    int? safeZoneBreaches,
    int? consecutiveSafeDays,
    bool? isCurrentlySafe,
    List<int>? weeklyBreaches,
    int? journalEntryDays,
    int? journalPhotoCount,
    int? journalConsistencyPercent,
    List<InsightItem>? insights,
    List<String>? suggestions,
  }) {
    return AnalyticsStats(
      reminderAdherencePercent:
          reminderAdherencePercent ?? this.reminderAdherencePercent,
      remindersMissedCount: remindersMissedCount ?? this.remindersMissedCount,
      completedReminders: completedReminders ?? this.completedReminders,
      missedReminders: missedReminders ?? this.missedReminders,
      voiceRemindersPlayed: voiceRemindersPlayed ?? this.voiceRemindersPlayed,
      weeklyAdherence: weeklyAdherence ?? this.weeklyAdherence,
      gamesScore: gamesScore ?? this.gamesScore,
      avgGameDurationMinutes:
          avgGameDurationMinutes ?? this.avgGameDurationMinutes,
      dailyGameSessions: dailyGameSessions ?? this.dailyGameSessions,
      safeZoneBreaches: safeZoneBreaches ?? this.safeZoneBreaches,
      consecutiveSafeDays: consecutiveSafeDays ?? this.consecutiveSafeDays,
      isCurrentlySafe: isCurrentlySafe ?? this.isCurrentlySafe,
      weeklyBreaches: weeklyBreaches ?? this.weeklyBreaches,
      journalEntryDays: journalEntryDays ?? this.journalEntryDays,
      journalPhotoCount: journalPhotoCount ?? this.journalPhotoCount,
      journalConsistencyPercent:
          journalConsistencyPercent ?? this.journalConsistencyPercent,
      insights: insights ?? this.insights,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

enum InsightType { positive, warning, neutral }

class InsightItem {
  final String text;
  final InsightType type;

  InsightItem({required this.text, required this.type});
}
