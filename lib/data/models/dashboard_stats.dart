/// Dashboard statistics model
/// Aggregated data for caregiver dashboard overview
class DashboardStats {
  // Reminder stats
  final int remindersCompleted;
  final int remindersPending;
  final int remindersMissed;
  final double adherencePercentage;

  // Activity stats
  final int memoryCardsCount;
  final int peopleCardsCount;
  final DateTime? lastJournalEntry;
  final DateTime? lastVoiceInteraction;

  // Safety stats
  final bool isInSafeZone;
  final int safeZoneBreachesThisWeek;
  final DateTime? lastLocationUpdate;

  // Engagement stats
  final int gamesPlayedThisWeek;
  final double memoryJournalConsistency; // 0.0 to 1.0

  // Alert count
  final int unreadAlerts;

  DashboardStats({
    this.remindersCompleted = 0,
    this.remindersPending = 0,
    this.remindersMissed = 0,
    this.adherencePercentage = 0.0,
    this.memoryCardsCount = 0,
    this.peopleCardsCount = 0,
    this.lastJournalEntry,
    this.lastVoiceInteraction,
    this.isInSafeZone = true,
    this.safeZoneBreachesThisWeek = 0,
    this.lastLocationUpdate,
    this.gamesPlayedThisWeek = 0,
    this.memoryJournalConsistency = 0.0,
    this.unreadAlerts = 0,
  });

  DashboardStats copyWith({
    int? remindersCompleted,
    int? remindersPending,
    int? remindersMissed,
    double? adherencePercentage,
    int? memoryCardsCount,
    int? peopleCardsCount,
    DateTime? lastJournalEntry,
    DateTime? lastVoiceInteraction,
    bool? isInSafeZone,
    int? safeZoneBreachesThisWeek,
    DateTime? lastLocationUpdate,
    int? gamesPlayedThisWeek,
    double? memoryJournalConsistency,
    int? unreadAlerts,
  }) {
    return DashboardStats(
      remindersCompleted: remindersCompleted ?? this.remindersCompleted,
      remindersPending: remindersPending ?? this.remindersPending,
      remindersMissed: remindersMissed ?? this.remindersMissed,
      adherencePercentage: adherencePercentage ?? this.adherencePercentage,
      memoryCardsCount: memoryCardsCount ?? this.memoryCardsCount,
      peopleCardsCount: peopleCardsCount ?? this.peopleCardsCount,
      lastJournalEntry: lastJournalEntry ?? this.lastJournalEntry,
      lastVoiceInteraction: lastVoiceInteraction ?? this.lastVoiceInteraction,
      isInSafeZone: isInSafeZone ?? this.isInSafeZone,
      safeZoneBreachesThisWeek:
          safeZoneBreachesThisWeek ?? this.safeZoneBreachesThisWeek,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      gamesPlayedThisWeek: gamesPlayedThisWeek ?? this.gamesPlayedThisWeek,
      memoryJournalConsistency:
          memoryJournalConsistency ?? this.memoryJournalConsistency,
      unreadAlerts: unreadAlerts ?? this.unreadAlerts,
    );
  }

  /// Get total reminders today
  int get totalRemindersToday =>
      remindersCompleted + remindersPending + remindersMissed;

  /// Check if there are any safety concerns
  bool get hasSafetyConcerns =>
      !isInSafeZone || safeZoneBreachesThisWeek > 0 || unreadAlerts > 0;

  /// Get insight message based on stats
  String get insightMessage {
    if (adherencePercentage < 50) {
      return "Reminder adherence is low. Consider reviewing medication schedule.";
    } else if (safeZoneBreachesThisWeek > 3) {
      return "Multiple safe-zone exits this week. Review safety settings.";
    } else if (memoryJournalConsistency < 0.3) {
      return "Memory journal usage is low. Encourage daily entries.";
    } else if (adherencePercentage > 80 && memoryJournalConsistency > 0.7) {
      return "Great progress! Patient is maintaining good routines.";
    } else {
      return "Patient is doing well. Continue monitoring daily activities.";
    }
  }
}
