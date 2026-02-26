import 'dart:async';

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
      return r.reminderTime.year == now.year &&
          r.reminderTime.month == now.month &&
          r.reminderTime.day == now.day &&
          r.status != ReminderStatus.missed;
    }).toList();
  }

  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return reminders.where((r) => r.reminderTime.isAfter(tomorrow)).toList();
  }

  List<Reminder> get completedReminders {
    return reminders
        .where((r) => r.status == ReminderStatus.completed)
        .toList();
  }
}

class ReminderViewModel extends StateNotifier<ReminderState> {
  final ReminderRepository _repository;
  final String? _userId;
  StreamSubscription<List<Reminder>>? _subscription;

  ReminderViewModel(this._repository, this._userId) : super(ReminderState()) {
    if (_userId != null) {
      _initRealtime();
    }
  }

  void _initRealtime() {
    state = state.copyWith(isLoading: true);

    _subscription?.cancel();
    _subscription = _repository.watchPatientRemindersRealtime(_userId!).listen(
      (reminders) {
        state = state.copyWith(reminders: reminders, isLoading: false);
      },
      onError: (error) {
        print('ReminderRealtime error: $error');
        state = state.copyWith(isLoading: false);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    final uid = _userId;
    if (uid == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getReminders(uid);
      state = state.copyWith(reminders: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    await _repository.addReminder(reminder);
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _repository.updateReminder(reminder);
  }

  Future<void> deleteReminder(String id) async {
    await _repository.deleteReminder(id);
  }

  Future<void> markAsDone(String id) async {
    await _repository.markReminderCompleted(id);
  }
}

final reminderViewModelProvider =
    StateNotifierProvider.autoDispose<ReminderViewModel, ReminderState>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return ReminderViewModel(repo, user?.id);
});
