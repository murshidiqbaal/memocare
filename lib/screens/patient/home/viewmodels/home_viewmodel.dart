import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/reminder.dart';
import '../../../../data/repositories/reminder_repository.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/service_providers.dart';
import '../../../../services/notification/reminder_notification_service.dart';

// --- State Classes ---

class HomeState {
  // SOURCE OF TRUTH: Contains ALL reminders for the patient.
  final List<Reminder> reminders;
  final bool isOffline;
  final bool isSafe;
  final bool isLoading;

  HomeState({
    this.reminders = const [],
    this.isOffline = false,
    this.isSafe = true,
    this.isLoading = false,
  });

  HomeState copyWith({
    List<Reminder>? reminders,
    bool? isOffline,
    bool? isSafe,
    bool? isLoading,
  }) {
    return HomeState(
      reminders: reminders ?? this.reminders,
      isOffline: isOffline ?? this.isOffline,
      isSafe: isSafe ?? this.isSafe,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // --- Derived Getters (Reactive Views) ---

  /// Returns reminders scheduled for TODAY (including repeats).
  /// Automatically handles "stale" completion status for repeating tasks.
  List<Reminder> get todayReminders {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final filtered = reminders.where((r) {
      // 1. Filter by Date Logic
      if (r.remindAt.year == now.year &&
          r.remindAt.month == now.month &&
          r.remindAt.day == now.day) {
        return true;
      }
      // Future one-time reminders are excluded
      if (r.repeatRule == ReminderFrequency.once &&
          r.remindAt.isAfter(todayEnd)) {
        return false;
      }
      // Repeating rules
      if (r.repeatRule == ReminderFrequency.daily) return true;
      if (r.repeatRule == ReminderFrequency.weekly) {
        return r.remindAt.weekday == now.weekday;
      }
      return false;
    }).map((r) {
      // 2. Handle Repeating Task Status
      // If a repeating task says "completed" but wasn't completed TODAY, list it as pending.
      if (r.status == ReminderStatus.completed &&
          r.repeatRule != ReminderFrequency.once) {
        final last =
            r.completionHistory.isNotEmpty ? r.completionHistory.last : null;
        final completedToday = last != null &&
            last.year == now.year &&
            last.month == now.month &&
            last.day == now.day;

        if (!completedToday) {
          return r.copyWith(status: ReminderStatus.pending);
        }
      }
      return r;
    }).toList();

    // 3. Sort by Time (normalized to today)
    filtered.sort((a, b) {
      final timeA = DateTime(
          now.year, now.month, now.day, a.remindAt.hour, a.remindAt.minute);
      final timeB = DateTime(
          now.year, now.month, now.day, b.remindAt.hour, b.remindAt.minute);
      return timeA.compareTo(timeB);
    });

    return filtered;
  }

  /// All upcoming reminders (future dates)
  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    final tomorrowStart = DateTime(now.year, now.month, now.day + 1);
    return reminders
        .where((r) =>
            r.remindAt.isAfter(tomorrowStart) &&
            r.repeatRule == ReminderFrequency.once)
        .toList();
  }

  /// Completed reminders (History)
  List<Reminder> get completedReminders {
    return reminders
        .where((r) => r.status == ReminderStatus.completed)
        .toList();
  }
}

// --- ViewModel ---

class HomeViewModel extends StateNotifier<HomeState> {
  final ReminderRepository _repository;
  final ReminderNotificationService _notificationService;

  HomeViewModel(this._repository, this._notificationService)
      : super(HomeState());

  // --- Actions ---

  /// Load all reminders from Hive and populate state.
  Future<void> loadReminders(String patientId) async {
    print('HomeViewModel: Loading ALL reminders for patient $patientId');
    state = state.copyWith(isLoading: true);

    try {
      await _repository.init();
      final allReminders = _repository.getReminders(patientId);

      // We store ALL reminders. The 'todayReminders' getter handles filtering.
      state = state.copyWith(reminders: allReminders, isLoading: false);
      print('HomeViewModel: Loaded ${allReminders.length} reminders.');
    } catch (e) {
      print('HomeViewModel Error loading reminders: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Add a reminder: Persist -> Notify -> Update State
  Future<void> addReminder(Reminder reminder) async {
    print('HomeViewModel: Adding reminder ${reminder.title}');
    try {
      // Step A: Save to Hive
      await _repository.addReminder(reminder);

      // Schedule Notification
      await _notificationService.scheduleReminder(reminder);

      // Step B & C: Update State Immutably
      state = state.copyWith(reminders: [...state.reminders, reminder]);
    } catch (e) {
      print('HomeViewModel Error adding reminder: $e');
    }
  }

  /// Update a reminder: Persist -> Notify -> Update State
  Future<void> updateReminder(Reminder reminder) async {
    print('HomeViewModel: Updating reminder ${reminder.id}');
    try {
      // Step A: Save to Hive
      await _repository.updateReminder(reminder);

      // Schedule/Cancel Notification
      await _notificationService
          .cancelReminder(reminder); // Cancel old using stable ID
      if (reminder.status == ReminderStatus.pending) {
        await _notificationService.scheduleReminder(reminder);
      }

      // Step B & C: Update State Immutably
      final updatedList = state.reminders.map((r) {
        return r.id == reminder.id ? reminder : r;
      }).toList();

      state = state.copyWith(reminders: updatedList);
    } catch (e) {
      print('HomeViewModel Error updating reminder: $e');
    }
  }

  /// Delete a reminder: Persist -> Cancel Notify -> Update State
  Future<void> deleteReminder(String id) async {
    print('HomeViewModel: Deleting reminder $id');
    try {
      // Find reminder first to cancel notification
      final reminder = state.reminders.firstWhere((r) => r.id == id,
          orElse: () => Reminder(
              id: 'err',
              patientId: '',
              title: '',
              type: ReminderType.task,
              remindAt: DateTime.now(),
              createdAt: DateTime.now()));

      if (reminder.id != 'err') {
        await _notificationService.cancelReminder(reminder);
      } else {
        // Fallback
        await _notificationService.cancelReminderById(id);
      }

      // Step A: Delete from Hive
      await _repository.deleteReminder(id);

      // Step B & C: Filter List & Emit
      final updatedList = state.reminders.where((r) => r.id != id).toList();
      state = state.copyWith(reminders: updatedList);
    } catch (e) {
      print('HomeViewModel Error deleting reminder: $e');
    }
  }

  /// Toggle completion status
  Future<void> toggleReminder(String id) async {
    // 1. Find in current list
    final reminderIndex = state.reminders.indexWhere((r) => r.id == id);
    if (reminderIndex == -1) return;

    final reminder = state.reminders[reminderIndex];
    final bool isNowCompleted = reminder.status != ReminderStatus.completed;
    final newStatus =
        isNowCompleted ? ReminderStatus.completed : ReminderStatus.pending;

    // Logic: Append to history if completing, else keep history
    final updatedReminder = reminder.copyWith(
        status: newStatus,
        completionHistory: isNowCompleted
            ? [...reminder.completionHistory, DateTime.now()]
            : reminder.completionHistory);

    try {
      // Step A: Persist
      if (isNowCompleted) {
        await _repository.markAsDone(id); // Updates Repo
        await _notificationService.cancelReminder(reminder);
      } else {
        await _repository.updateReminder(updatedReminder);
        await _notificationService.scheduleReminder(updatedReminder);
      }

      // Step B & C: Update State Immutably
      final updatedList = List<Reminder>.from(state.reminders);
      updatedList[reminderIndex] = updatedReminder;
      state = state.copyWith(reminders: updatedList);
    } catch (e) {
      print('HomeViewModel Error toggling reminder: $e');
    }
  }

  void setOfflineStatus(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }

  void triggerSOS() {
    print('SOS Triggered!');
  }
}

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final reminderRepo = ref.watch(reminderRepositoryProvider);
  final notificationService = ref.watch(reminderNotificationServiceProvider);
  final viewModel = HomeViewModel(reminderRepo, notificationService);

  // Watch user to trigger load immediately and once
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    // Only load if empty? No, load fresh on auth change.
    viewModel.loadReminders(user.id);
  }

  return viewModel;
});
