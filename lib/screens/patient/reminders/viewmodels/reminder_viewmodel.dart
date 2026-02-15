import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/reminder.dart';
import '../../../../data/repositories/reminder_repository.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/service_providers.dart';

class ReminderState {
  final List<Reminder> reminders;
  final bool isLoading;

  ReminderState({
    this.reminders = const [],
    this.isLoading = false,
  });

  ReminderState copyWith({
    List<Reminder>? reminders,
    bool? isLoading,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<Reminder> get todayReminders {
    final now = DateTime.now();
    return reminders.where((r) {
      return r.remindAt.year == now.year &&
          r.remindAt.month == now.month &&
          r.remindAt.day == now.day &&
          r.status != ReminderStatus.missed;
    }).toList();
  }

  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return reminders.where((r) => r.remindAt.isAfter(tomorrow)).toList();
  }

  List<Reminder> get completedReminders {
    return reminders
        .where((r) => r.status == ReminderStatus.completed)
        .toList();
  }
}

class ReminderViewModel extends StateNotifier<ReminderState> {
  final ReminderRepository _repository;
  final Ref _ref;
  final String? _userId;

  ReminderViewModel(this._repository, this._ref, this._userId)
      : super(ReminderState()) {
    if (_userId != null) {
      _loadReminders();
    }
  }

  Future<void> _loadReminders() async {
    state = state.copyWith(isLoading: true);
    await _repository.init();
    if (_userId != null) {
      print('ReminderViewModel: Loading all reminders for user $_userId');
      final reminders = _repository.getReminders(_userId);
      print('ReminderViewModel: Loaded ${reminders.length} reminders.');
      state = state.copyWith(reminders: reminders, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true);
    await _repository.syncReminders(_userId);
    final reminders = _repository.getReminders(_userId);
    state = state.copyWith(reminders: reminders, isLoading: false);
  }

  Future<void> addReminder(Reminder reminder) async {
    // state = state.copyWith(reminders: [...state.reminders, reminder]); // Optimistic
    await _repository.addReminder(reminder);

    // Detailed logging
    print('ReminderViewModel: Added reminder ${reminder.id}. Reloading...');

    await _loadReminders(); // Reload from source of truth

    // Schedule Notification
    final notifService = _ref.read(reminderNotificationServiceProvider);
    await notifService.scheduleReminder(reminder);
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _repository.updateReminder(reminder);
    final notifService = _ref.read(reminderNotificationServiceProvider);

    // Reschedule
    // Reschedule
    try {
      await notifService.cancelReminder(reminder);
      if (reminder.status == ReminderStatus.pending) {
        await notifService.scheduleReminder(reminder);
      }
    } catch (e) {
      print('Notification rescheduling error: $e');
    }

    // Refresh from Hive
    await _loadReminders();
  }

  Future<void> deleteReminder(String id) async {
    // 1. Find reminder to get correct notification ID for cancellation
    final reminder = state.reminders.cast<Reminder?>().firstWhere(
          (r) => r?.id == id,
          orElse: () => null,
        );

    // 2. Cancel Notification
    final notifService = _ref.read(reminderNotificationServiceProvider);
    try {
      if (reminder != null) {
        await notifService.cancelReminder(reminder);
      } else {
        // Fallback if not in state (rare)
        await notifService.cancelReminderById(id);
      }
    } catch (e) {
      print('Notification cancel error: $e');
    }

    // 3. Delete from Repo
    await _repository.deleteReminder(id);
    await _loadReminders();
  }

  Future<void> markAsDone(String id) async {
    final reminder = state.reminders.firstWhere((r) => r.id == id,
        orElse: () => Reminder(
            id: 'error',
            patientId: '',
            title: '',
            type: ReminderType.task,
            remindAt: DateTime.now(),
            createdAt: DateTime.now()));
    if (reminder.id == 'error') return; // Not found

    final updated = reminder.copyWith(
      status: ReminderStatus.completed,
      completionHistory: [...reminder.completionHistory, DateTime.now()],
    );
    await updateReminder(updated);
  }
}

final reminderViewModelProvider =
    StateNotifierProvider.autoDispose<ReminderViewModel, ReminderState>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return ReminderViewModel(repo, ref, user?.id);
});
