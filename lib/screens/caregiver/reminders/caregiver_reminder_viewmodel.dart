import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/reminder.dart';
import '../../../../data/repositories/reminder_repository.dart';
import '../../../../features/patient_selection/providers/patient_selection_provider.dart';
import '../../../../providers/service_providers.dart';
import '../../../../services/notification/reminder_notification_service.dart';
import '../../../../services/notification_trigger_service.dart';

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
  final NotificationTriggerService _notificationTrigger;
  final ReminderNotificationService _localNotifications;

  CaregiverReminderViewModel(
    this._repository,
    this._supabase,
    this._notificationTrigger,
    this._localNotifications,
  ) : super(CaregiverReminderState());

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
      state = state.copyWith(
        isLoading: false,
        error: 'Sync failed: $e',
      );
    }
  }

  // Keep for legacy callers
  void selectPatient(String patientId) => onPatientChanged(patientId);

  // ── CRUD + Push Notifications ─────────────────────────────────────────────

  Future<void> addReminder(Reminder reminder) async {
    // Optimistic update
    state = state.copyWith(reminders: [...state.reminders, reminder]);
    try {
      await _repository.addReminder(reminder);

      // Schedule local device alarm (for patient's device)
      await _localNotifications.scheduleReminder(reminder);

      // Send FCM push to patient device + caregivers
      await _notificationTrigger.sendReminderCreated(
        patientId: reminder.patientId,
        reminderId: reminder.id,
        reminderTitle: reminder.title,
        reminderDescription: reminder.description,
      );

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

      // Re-schedule local alarm with updated time
      await _localNotifications.cancelReminder(reminder);
      await _localNotifications.scheduleReminder(reminder);

      // Notify patient of the change
      await _notificationTrigger.sendReminderUpdated(
        patientId: reminder.patientId,
        reminderId: reminder.id,
        reminderTitle: reminder.title,
      );

      await refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update reminder: $e');
    }
  }

  Future<void> deleteReminder(String id) async {
    // Find reminder before removing from state for notification cancel
    final reminder = state.reminders.firstWhere(
      (r) => r.id == id,
      orElse: () => state.reminders.first,
    );

    state = state.copyWith(
      reminders: state.reminders.where((r) => r.id != id).toList(),
    );
    try {
      // Cancel local scheduled alarm
      await _localNotifications.cancelReminder(reminder);
      await _repository.deleteReminder(id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete reminder: $e');
    }
  }

  /// Called by the patient app when a reminder becomes due.
  /// Sends push to caregivers for monitoring awareness.
  Future<void> markReminderDue(Reminder reminder) async {
    await _notificationTrigger.sendReminderDue(
      patientId: reminder.patientId,
      reminderId: reminder.id,
      reminderTitle: reminder.title,
      reminderType: reminder.type.name,
    );
  }

  /// Called when a reminder is missed (past due, still pending).
  Future<void> markReminderMissed(Reminder reminder) async {
    await _notificationTrigger.sendReminderMissed(
      patientId: reminder.patientId,
      reminderId: reminder.id,
      reminderTitle: reminder.title,
    );
  }

  // ── Analytics helpers ──────────────────────────────────────────────────────

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
            r.status == ReminderStatus.pending && r.reminderTime.isAfter(now))
        .length;
  }

  int get missedCount {
    final now = DateTime.now();
    return state.reminders
        .where((r) =>
            r.status == ReminderStatus.missed ||
            (r.status == ReminderStatus.pending && r.reminderTime.isBefore(now)))
        .length;
  }
}

final caregiverReminderProvider =
    StateNotifierProvider<CaregiverReminderViewModel, CaregiverReminderState>(
        (ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final trigger = ref.watch(notificationTriggerProvider);
  final localNotifs = ref.watch(reminderNotificationServiceProvider);

  final vm = CaregiverReminderViewModel(repo, supabase, trigger, localNotifs);

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
