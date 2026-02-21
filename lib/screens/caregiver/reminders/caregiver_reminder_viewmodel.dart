import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/reminder.dart';
import '../../../../data/repositories/reminder_repository.dart';
import '../../../../features/patient_selection/providers/patient_selection_provider.dart';
import '../../../../providers/service_providers.dart';

class CaregiverReminderState {
  final List<Reminder> reminders;
  final String selectedPatientId;
  final bool isLoading;
  final String? error;

  CaregiverReminderState({
    this.reminders = const [],
    this.selectedPatientId = '',
    this.isLoading = false,
    this.error,
  });

  CaregiverReminderState copyWith({
    List<Reminder>? reminders,
    String? selectedPatientId,
    bool? isLoading,
    String? error,
  }) {
    return CaregiverReminderState(
      reminders: reminders ?? this.reminders,
      selectedPatientId: selectedPatientId ?? this.selectedPatientId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CaregiverReminderViewModel extends StateNotifier<CaregiverReminderState> {
  final ReminderRepository _repository;
  final SupabaseClient _supabase;

  CaregiverReminderViewModel(this._repository, this._supabase)
      : super(CaregiverReminderState());

  /// Called when the globally selected patient changes
  void onPatientChanged(String patientId) {
    if (patientId == state.selectedPatientId) return;
    state = state.copyWith(selectedPatientId: patientId, reminders: []);
    if (patientId.isNotEmpty) {
      refresh();
    }
  }

  Future<void> refresh() async {
    if (state.selectedPatientId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Fetch from Supabase directly
      final data = await _supabase
          .from('reminders')
          .select()
          .eq('patient_id', state.selectedPatientId)
          .order('remind_at', ascending: true);

      final reminders = (data as List)
          .map((r) => Reminder.fromJson(r as Map<String, dynamic>))
          .toList();
      state = state.copyWith(reminders: reminders, isLoading: false);
    } catch (e) {
      // Fallback to local cache
      await _repository.init();
      final cached = _repository.getReminders(state.selectedPatientId);
      state = state.copyWith(
        reminders: cached,
        isLoading: false,
        error: 'Showing cached data. Sync failed: $e',
      );
    }
  }

  // Keep this for legacy callers
  void selectPatient(String patientId) => onPatientChanged(patientId);

  Future<void> addReminder(Reminder reminder) async {
    state = state.copyWith(reminders: [...state.reminders, reminder]);
    try {
      await _repository.addReminder(reminder);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add reminder: $e');
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    state = state.copyWith(
      reminders: [
        for (final r in state.reminders)
          if (r.id == reminder.id) reminder else r
      ],
    );
    try {
      await _repository.updateReminder(reminder);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update reminder: $e');
    }
  }

  Future<void> deleteReminder(String id) async {
    state = state.copyWith(
      reminders: state.reminders.where((r) => r.id != id).toList(),
    );
    try {
      await _repository.deleteReminder(id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete reminder: $e');
    }
  }

  // Analytics Helpers
  int get completedTodayCount {
    final now = DateTime.now();
    return state.reminders
        .where((r) =>
            r.status == ReminderStatus.completed &&
            r.completionHistory.isNotEmpty &&
            r.completionHistory.last.year == now.year &&
            r.completionHistory.last.month == now.month &&
            r.completionHistory.last.day == now.day)
        .length;
  }

  int get pendingCount {
    final now = DateTime.now();
    return state.reminders
        .where((r) =>
            r.status == ReminderStatus.pending && r.remindAt.isAfter(now))
        .length;
  }

  int get missedCount {
    final now = DateTime.now();
    return state.reminders
        .where((r) =>
            r.status == ReminderStatus.missed ||
            (r.status == ReminderStatus.pending && r.remindAt.isBefore(now)))
        .length;
  }
}

final caregiverReminderProvider =
    StateNotifierProvider<CaregiverReminderViewModel, CaregiverReminderState>(
        (ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final vm = CaregiverReminderViewModel(repo, supabase);

  // React to global patient selection changes automatically
  ref.listen<String?>(
    patientSelectionProvider.select((s) => s.selectedPatient?.id),
    (_, patientId) {
      if (patientId != null && patientId.isNotEmpty) {
        vm.onPatientChanged(patientId);
      }
    },
    fireImmediately: true,
  );

  return vm;
});
