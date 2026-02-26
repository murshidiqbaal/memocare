// lib/screens/caregiver/dashboard/viewmodels/caregiver_dashboard_viewmodel.dart
//
// ─── LAYER 2 ViewModel ───────────────────────────────────────────────────────
//
// Single source of truth wiring:
//   patientSelectionProvider (Patient model) drives all dashboard data.
//   The ViewModel never holds its own patient list — it reacts to
//   patientSelectionProvider and loads data for whichever patient is selected.
//
// Key design decisions:
//   • NOT autoDispose — dashboard lives in an IndexedStack and must keep state
//     when the tab is off-screen.
//   • Uses ref.listen inside the Provider body to react to patient changes
//     without causing rebuild storms in the UI.
//   • All heavy fetching is async-safe: guarded against disposed state.
//   • No print() in production — uses debugPrint with assert gate.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/caregiver_patient_link.dart';
import '../../../../data/models/dashboard_stats.dart';
import '../../../../data/models/reminder.dart';
import '../../../../data/models/voice_query.dart';
import '../../../../data/repositories/dashboard_repository.dart';
import '../../../../features/patient_selection/providers/patient_selection_provider.dart';
import '../../../../providers/service_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Support models
// ─────────────────────────────────────────────────────────────────────────────

class PatientStatus {
  final String locationName;
  final bool isSafe;
  final DateTime lastActive;
  final int completedReminders;
  final int totalReminders;

  const PatientStatus({
    required this.locationName,
    required this.isSafe,
    required this.lastActive,
    this.completedReminders = 0,
    this.totalReminders = 0,
  });
}

class WeeklyStat {
  final String day;
  final double engagement;

  const WeeklyStat({required this.day, required this.engagement});
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class CaregiverDashboardState {
  final bool isLoading;
  final bool isOffline;
  final DateTime? lastUpdated;
  final String? error;

  // Derived from patientSelectionProvider — never set locally
  final String? selectedPatientId; // null = no patient selected
  final String selectedPatientName;
  final String? selectedPatientPhotoUrl;

  // Legacy compat: needed by old widgets still using CaregiverPatientLink
  final CaregiverPatientLink? selectedPatient;
  final List<CaregiverPatientLink> linkedPatients;

  // Dashboard data
  final DashboardStats stats;
  final Reminder? nextReminder;
  final List<VoiceQuery> recentVoiceInteractions;

  const CaregiverDashboardState({
    this.isLoading = false,
    this.isOffline = false,
    this.lastUpdated,
    this.error,
    this.selectedPatientId,
    this.selectedPatientName = 'No Patient Selected',
    this.selectedPatientPhotoUrl,
    this.selectedPatient,
    this.linkedPatients = const [],
    DashboardStats? stats,
    this.nextReminder,
    this.recentVoiceInteractions = const [],
  }) : stats = stats ?? const DashboardStats();

  CaregiverDashboardState copyWith({
    bool? isLoading,
    bool? isOffline,
    DateTime? lastUpdated,
    String? error,
    bool clearError = false,
    String? selectedPatientId,
    String? selectedPatientName,
    String? selectedPatientPhotoUrl,
    CaregiverPatientLink? selectedPatient,
    List<CaregiverPatientLink>? linkedPatients,
    DashboardStats? stats,
    Reminder? nextReminder,
    List<VoiceQuery>? recentVoiceInteractions,
  }) {
    return CaregiverDashboardState(
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: clearError ? null : (error ?? this.error),
      selectedPatientId: selectedPatientId ?? this.selectedPatientId,
      selectedPatientName: selectedPatientName ?? this.selectedPatientName,
      selectedPatientPhotoUrl:
          selectedPatientPhotoUrl ?? this.selectedPatientPhotoUrl,
      selectedPatient: selectedPatient ?? this.selectedPatient,
      linkedPatients: linkedPatients ?? this.linkedPatients,
      stats: stats ?? this.stats,
      nextReminder: nextReminder ?? this.nextReminder,
      recentVoiceInteractions:
          recentVoiceInteractions ?? this.recentVoiceInteractions,
    );
  }

  // ── Convenience getters used by UI widgets ──────────────────────────────

  bool get hasPatientSelected =>
      selectedPatientId != null && selectedPatientId!.isNotEmpty;

  PatientStatus get patientStatus => PatientStatus(
        locationName: selectedPatientName,
        isSafe: stats.isInSafeZone,
        lastActive: stats.lastVoiceInteraction ?? DateTime.now(),
        completedReminders: stats.remindersCompleted,
        totalReminders: stats.remindersCompleted +
            stats.remindersPending +
            stats.remindersMissed,
      );

  List<WeeklyStat> get weeklyStats {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days
        .map((d) => WeeklyStat(
              day: d,
              engagement: stats.adherencePercentage / 100.0,
            ))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class CaregiverDashboardViewModel
    extends StateNotifier<CaregiverDashboardState> {
  final DashboardRepository _repository;

  CaregiverDashboardViewModel(this._repository)
      : super(const CaregiverDashboardState());

  // ── Called by the provider body when selected patient changes ───────────

  void onPatientChanged(
      String? patientId, String patientName, String? photoUrl) {
    if (state.selectedPatientId == patientId) return; // idempotent

    state = state.copyWith(
      selectedPatientId: patientId,
      selectedPatientName: patientName,
      selectedPatientPhotoUrl: photoUrl,
      // Reset dashboard data on patient switch
      stats: const DashboardStats(),
      nextReminder: null,
      recentVoiceInteractions: [],
      clearError: true,
    );

    if (patientId != null && patientId.isNotEmpty) {
      loadDashboardData(patientId);
    }
  }

  // ── Data loading ────────────────────────────────────────────────────────

  Future<void> loadDashboardData(String patientId) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _repository.getDashboardStats(patientId),
        _repository.getNextReminder(patientId),
        _repository.getRecentVoiceInteractions(patientId),
      ]);

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        isOffline: false,
        stats: results[0] as DashboardStats,
        nextReminder: results[1] as Reminder?,
        recentVoiceInteractions: results[2] as List<VoiceQuery>,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _log('loadDashboardData error: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isOffline: true,
        error: 'Could not refresh data. Showing cached information.',
      );
    }
  }

  Future<void> refresh() async {
    final pid = state.selectedPatientId;
    if (pid == null || pid.isEmpty) return;
    await loadDashboardData(pid);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _log(String msg) {
    assert(() {
      debugPrint('[CaregiverDashboard] $msg');
      return true;
    }());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod Provider — NOT autoDispose (lives in IndexedStack)
//
// Reacts to patientSelectionProvider via ref.listen in the provider body.
// This keeps the ViewModel state alive and avoids rebuild storms in the UI.
// ─────────────────────────────────────────────────────────────────────────────
final caregiverDashboardProvider = StateNotifierProvider.family<
    CaregiverDashboardViewModel, CaregiverDashboardState, String>(
  (ref, caregiverId) {
    final repository = ref.watch(dashboardRepositoryProvider);
    final vm = CaregiverDashboardViewModel(repository);

    // ── React to patientSelectionProvider changes ─────────────────────────
    // This is the ONLY place patient data flows into the dashboard ViewModel.
    // fireImmediately loads data for the currently selected patient on first build.
    ref.listen<PatientState>(
      patientSelectionProvider,
      (previous, next) {
        final patient = next.selectedPatient;
        vm.onPatientChanged(
          patient?.id,
          patient?.fullName ?? 'No Patient Selected',
          patient?.profileImageUrl,
        );
      },
      fireImmediately: true,
    );

    return vm;
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Backward-compat alias used by caregiver_dashboard_tab.dart
// Re-maps to the unified provider for zero migration cost.
// ─────────────────────────────────────────────────────────────────────────────
final caregiverDashboardViewModelProvider = caregiverDashboardProvider;
