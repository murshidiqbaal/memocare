import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/reminder.dart';
import '../../../../data/repositories/reminder_repository.dart';
import '../../../../providers/service_providers.dart';

class CaregiverReminderState {
  final List<Reminder> reminders;
  final String selectedPatientId;
  final bool isLoading;

  CaregiverReminderState({
    this.reminders = const [],
    this.selectedPatientId = 'patient_1', // Default or passed in
    this.isLoading = false,
  });

  CaregiverReminderState copyWith({
    List<Reminder>? reminders,
    String? selectedPatientId,
    bool? isLoading,
  }) {
    return CaregiverReminderState(
      reminders: reminders ?? this.reminders,
      selectedPatientId: selectedPatientId ?? this.selectedPatientId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CaregiverReminderViewModel extends StateNotifier<CaregiverReminderState> {
  final ReminderRepository _repository;

  CaregiverReminderViewModel(this._repository)
      : super(CaregiverReminderState()) {
    // Initial load? Or wait for patient selection?
    // For now, load default
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    state = state.copyWith(isLoading: true);
    await _repository.init();
    // Fetch for the selected patient
    final reminders = _repository.getReminders(state.selectedPatientId);
    state = state.copyWith(reminders: reminders, isLoading: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _repository.syncReminders(state.selectedPatientId);
    final reminders = _repository.getReminders(state.selectedPatientId);
    state = state.copyWith(reminders: reminders, isLoading: false);
  }

  void selectPatient(String patientId) {
    state = state.copyWith(selectedPatientId: patientId);
    refresh();
  }

  Future<void> addReminder(Reminder reminder) async {
    // Optimistic update
    state = state.copyWith(reminders: [...state.reminders, reminder]);
    await _repository.addReminder(reminder);
    // Sync happens in repo
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _repository.updateReminder(reminder);
    state = state.copyWith(
      reminders: [
        for (final r in state.reminders)
          if (r.id == reminder.id) reminder else r
      ],
    );
  }

  Future<void> deleteReminder(String id) async {
    await _repository.deleteReminder(id);
    state = state.copyWith(
      reminders: state.reminders.where((r) => r.id != id).toList(),
    );
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
            (r.status == ReminderStatus.pending &&
                r.remindAt.isBefore(now))) // Simple logic
        .length;
  }
}

final caregiverReminderProvider =
    StateNotifierProvider<CaregiverReminderViewModel, CaregiverReminderState>(
        (ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return CaregiverReminderViewModel(repo);
});
