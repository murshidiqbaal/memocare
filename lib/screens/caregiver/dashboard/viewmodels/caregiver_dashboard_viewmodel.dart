import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/caregiver_patient_link.dart';
import '../../../../data/models/dashboard_stats.dart';
import '../../../../data/models/reminder.dart';
import '../../../../data/models/voice_query.dart';
import '../../../../data/repositories/dashboard_repository.dart';
import '../../../../providers/service_providers.dart';

/// Patient Status Model
/// Used to display current patient status in the dashboard
class PatientStatus {
  final String locationName;
  final bool isSafe;
  final DateTime lastActive;
  final int completedReminders;
  final int totalReminders;

  PatientStatus({
    required this.locationName,
    required this.isSafe,
    DateTime? lastActive,
    this.completedReminders = 0,
    this.totalReminders = 0,
  }) : lastActive = lastActive ?? DateTime.now();
}

/// Weekly Stat Model
/// Used for analytics chart
class WeeklyStat {
  final String day;
  final double engagement;

  WeeklyStat({
    required this.day,
    required this.engagement,
  });
}

/// Caregiver Dashboard State
class CaregiverDashboardState {
  final bool isLoading;
  final bool isOffline;
  final DateTime? lastUpdated;
  final String? error;

  // Patient selection
  final List<CaregiverPatientLink> linkedPatients;
  final CaregiverPatientLink? selectedPatient;

  // Dashboard data
  final DashboardStats stats;
  final Reminder? nextReminder;
  final List<VoiceQuery> recentVoiceInteractions;

  CaregiverDashboardState({
    this.isLoading = false,
    this.isOffline = false,
    this.lastUpdated,
    this.error,
    this.linkedPatients = const [],
    this.selectedPatient,
    DashboardStats? stats,
    this.nextReminder,
    this.recentVoiceInteractions = const [],
  }) : stats = stats ?? DashboardStats();

  CaregiverDashboardState copyWith({
    bool? isLoading,
    bool? isOffline,
    DateTime? lastUpdated,
    String? error,
    List<CaregiverPatientLink>? linkedPatients,
    CaregiverPatientLink? selectedPatient,
    DashboardStats? stats,
    Reminder? nextReminder,
    List<VoiceQuery>? recentVoiceInteractions,
  }) {
    return CaregiverDashboardState(
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
      linkedPatients: linkedPatients ?? this.linkedPatients,
      selectedPatient: selectedPatient ?? this.selectedPatient,
      stats: stats ?? this.stats,
      nextReminder: nextReminder ?? this.nextReminder,
      recentVoiceInteractions:
          recentVoiceInteractions ?? this.recentVoiceInteractions,
    );
  }

  /// Convenience getters for backward compatibility with UI
  String get selectedPatientName =>
      selectedPatient?.patientName ?? 'No Patient Selected';

  PatientStatus get patientStatus {
    return PatientStatus(
      locationName: selectedPatient?.patientName ?? 'Unknown',
      isSafe: stats.isInSafeZone,
      lastActive: stats.lastVoiceInteraction,
      completedReminders: stats.remindersCompleted,
      totalReminders: stats.remindersCompleted +
          stats.remindersPending +
          stats.remindersMissed,
    );
  }

  List<WeeklyStat> get weeklyStats {
    // Generate 7 days of stats (placeholder - adjust based on actual data)
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days
        .map((day) => WeeklyStat(
              day: day,
              engagement: stats.adherencePercentage / 100.0,
            ))
        .toList();
  }
}

/// Caregiver Dashboard ViewModel
/// Manages state and business logic for the caregiver dashboard
class CaregiverDashboardViewModel
    extends StateNotifier<CaregiverDashboardState> {
  final DashboardRepository _repository;
  final String caregiverId;

  CaregiverDashboardViewModel(this._repository, this.caregiverId)
      : super(CaregiverDashboardState()) {
    _init();
  }

  /// Initialize dashboard
  Future<void> _init() async {
    await loadLinkedPatients();
  }

  /// Load linked patients
  Future<void> loadLinkedPatients() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final patients = await _repository.getLinkedPatients(caregiverId);

      if (patients.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          linkedPatients: [],
          error: 'No linked patients found',
        );
        return;
      }

      // Select first patient or primary caregiver's patient
      final primary = patients.firstWhere(
        (p) => p.isPrimary,
        orElse: () => patients.first,
      );

      state = state.copyWith(
        isLoading: false,
        linkedPatients: patients,
        selectedPatient: primary,
        lastUpdated: DateTime.now(),
      );

      // Load dashboard data for selected patient
      await loadDashboardData();
    } catch (e) {
      print('Error loading linked patients: $e');
      state = state.copyWith(
        isLoading: false,
        isOffline: true,
        error: 'Could not load patients. Check your connection.',
      );
    }
  }

  /// Select a patient
  Future<void> selectPatient(CaregiverPatientLink patient) async {
    if (state.selectedPatient?.id == patient.id) return;

    state = state.copyWith(selectedPatient: patient);
    await loadDashboardData();
  }

  /// Load dashboard data for selected patient
  Future<void> loadDashboardData() async {
    if (state.selectedPatient == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final patientId = state.selectedPatient!.patientId;

      // Load all dashboard data in parallel
      final results = await Future.wait([
        _repository.getDashboardStats(patientId),
        _repository.getNextReminder(patientId),
        _repository.getRecentVoiceInteractions(patientId),
      ]);

      state = state.copyWith(
        isLoading: false,
        stats: results[0] as DashboardStats,
        nextReminder: results[1] as Reminder?,
        recentVoiceInteractions: results[2] as List<VoiceQuery>,
        lastUpdated: DateTime.now(),
        isOffline: false,
      );
    } catch (e) {
      print('Error loading dashboard data: $e');
      state = state.copyWith(
        isLoading: false,
        isOffline: true,
        error: 'Could not refresh data. Showing cached information.',
      );
    }
  }

  /// Refresh dashboard
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Sync dashboard (background)
  Future<void> sync() async {
    try {
      await _repository.syncDashboard(caregiverId);
      await loadLinkedPatients();
    } catch (e) {
      print('Background sync error: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Riverpod Provider for Caregiver Dashboard
///
/// This provider creates a CaregiverDashboardViewModel instance
/// Use this to access the dashboard state and methods in your UI
///
/// Note: This uses .family to accept a caregiverId parameter
/// Usage: ref.watch(caregiverDashboardProvider(caregiverId))
final caregiverDashboardProvider = StateNotifierProvider.autoDispose
    .family<CaregiverDashboardViewModel, CaregiverDashboardState, String>(
  (ref, caregiverId) {
    final repository = ref.watch(dashboardRepositoryProvider);
    return CaregiverDashboardViewModel(repository, caregiverId);
  },
);
