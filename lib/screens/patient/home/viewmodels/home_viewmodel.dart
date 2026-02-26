import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/reminder.dart';
import '../../../../data/repositories/reminder_repository.dart';
import '../../../../data/repositories/safety_repository.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/service_providers.dart';
import '../../../../services/realtime_service.dart';

// --- State Classes ---

class HomeState {
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

  List<Reminder> get todayReminders {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final filtered = reminders.where((r) {
      if (r.reminderTime.year == now.year &&
          r.reminderTime.month == now.month &&
          r.reminderTime.day == now.day) {
        return true;
      }
      if (r.repeatRule == ReminderFrequency.once &&
          r.reminderTime.isAfter(todayEnd)) {
        return false;
      }
      if (r.repeatRule == ReminderFrequency.daily) return true;
      if (r.repeatRule == ReminderFrequency.weekly) {
        return r.reminderTime.weekday == now.weekday;
      }
      return false;
    }).map((r) {
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

    filtered.sort((a, b) {
      final timeA = DateTime(now.year, now.month, now.day, a.reminderTime.hour,
          a.reminderTime.minute);
      final timeB = DateTime(now.year, now.month, now.day, b.reminderTime.hour,
          b.reminderTime.minute);
      return timeA.compareTo(timeB);
    });

    return filtered;
  }

  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    final tomorrowStart = DateTime(now.year, now.month, now.day + 1);
    return reminders
        .where((r) =>
            r.reminderTime.isAfter(tomorrowStart) &&
            r.repeatRule == ReminderFrequency.once)
        .toList();
  }

  List<Reminder> get completedReminders {
    return reminders
        .where((r) => r.status == ReminderStatus.completed)
        .toList();
  }
}

// --- ViewModel ---

class HomeViewModel extends StateNotifier<HomeState> {
  final ReminderRepository _repository;
  final SafetyRepository _safetyRepository;

  HomeViewModel(this._repository, this._safetyRepository) : super(HomeState());

  bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  Future<void> loadReminders(String patientId) async {
    print('HomeViewModel: Loading ALL reminders for patient $patientId');
    state = state.copyWith(isLoading: true);

    try {
      final remote = await _repository.getReminders(patientId);

      state = state.copyWith(
        reminders: remote,
        isLoading: false,
      );

      _checkMissedReminders(patientId, remote);
    } catch (e) {
      print('HomeViewModel Error loading reminders: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void _checkMissedReminders(String patientId, List<Reminder> all) async {
    final now = DateTime.now();
    bool updated = false;

    for (var r in all) {
      if (r.reminderTime.isBefore(now) && r.status == ReminderStatus.pending) {
        final updatedR = r.copyWith(status: ReminderStatus.missed);
        await _repository.updateReminder(updatedR);
        updated = true;
      }
    }

    if (updated) {
      final fresh = await _repository.getReminders(patientId);
      if (mounted) {
        state = state.copyWith(reminders: fresh);
      }
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    print('HomeViewModel: Adding reminder ${reminder.title}');
    try {
      await _repository.addReminder(reminder);
      await loadReminders(reminder.patientId);
    } catch (e) {
      print('HomeViewModel Error adding reminder: $e');
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    print('HomeViewModel: Updating reminder ${reminder.id}');
    try {
      await _repository.updateReminder(reminder);
      await loadReminders(reminder.patientId);
    } catch (e) {
      print('HomeViewModel Error updating reminder: $e');
    }
  }

  Future<void> deleteReminder(String id) async {
    print('HomeViewModel: Deleting reminder $id');
    try {
      final reminder = state.reminders.firstWhere((r) => r.id == id,
          orElse: () => Reminder(
              id: 'err',
              caregiverId: '',
              patientId: '',
              title: '',
              type: ReminderType.task,
              reminderTime: DateTime.now(),
              createdAt: DateTime.now()));

      await _repository.deleteReminder(id);

      if (reminder.id != 'err') {
        await loadReminders(reminder.patientId);
      }
    } catch (e) {
      print('HomeViewModel Error deleting reminder: $e');
    }
  }

  Future<void> toggleReminder(String id) async {
    final reminderIndex = state.reminders.indexWhere((r) => r.id == id);
    if (reminderIndex == -1) return;

    final reminder = state.reminders[reminderIndex];
    final bool isNowCompleted = reminder.status != ReminderStatus.completed;
    final newStatus =
        isNowCompleted ? ReminderStatus.completed : ReminderStatus.pending;

    final updatedReminder = reminder.copyWith(
        status: newStatus,
        completionHistory: isNowCompleted
            ? [...reminder.completionHistory, DateTime.now()]
            : reminder.completionHistory);

    try {
      if (isNowCompleted) {
        await _repository.markAsDone(id);
      } else {
        await _repository.updateReminder(updatedReminder);
      }
      await loadReminders(reminder.patientId);
    } catch (e) {
      print('HomeViewModel Error toggling reminder: $e');
    }
  }

  void setOfflineStatus(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }

  Future<void> triggerSOS() async {
    print('SOS Triggered!');
    try {
      await _safetyRepository.sendSos(lat: null, lon: null);
    } catch (e) {
      print('Error sending SOS: $e');
    }
  }

  void updateRemindersFromRealtime(List<Reminder> reminders) {
    state = state.copyWith(reminders: reminders);
  }
}

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final reminderRepo = ref.watch(reminderRepositoryProvider);
  final safetyRepo = ref.watch(safetyRepositoryProvider);

  final viewModel = HomeViewModel(reminderRepo, safetyRepo);

  final user = ref.watch(currentUserProvider);
  if (user != null) {
    viewModel.loadReminders(user.id);
  }

  ref.listen(realtimeReminderStreamProvider, (prev, next) {
    next.whenData((reminders) {
      viewModel.updateRemindersFromRealtime(reminders);
    });
  });

  return viewModel;
});
