import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/reminder.dart';

// --- State Classes ---

class HomeState {
  final List<Reminder> reminders;
  final bool isOffline;
  final bool isSafe;

  HomeState({
    this.reminders = const [],
    this.isOffline = false,
    this.isSafe = true,
  });

  HomeState copyWith({
    List<Reminder>? reminders,
    bool? isOffline,
    bool? isSafe,
  }) {
    return HomeState(
      reminders: reminders ?? this.reminders,
      isOffline: isOffline ?? this.isOffline,
      isSafe: isSafe ?? this.isSafe,
    );
  }
}

// --- ViewModel ---

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel()
      : super(HomeState(
          reminders: [
            Reminder(
              id: '1',
              title: 'Take Blood Pressure Medication',
              remindAt: DateTime.now().add(const Duration(hours: 1)),
              patientId: 'currentUser',
              type: ReminderType.medication,
              createdAt: DateTime.now(),
              localAudioPath:
                  'dummy_path', // To simulate hasVoiceNote logic if needed
            ),
            Reminder(
              id: '2',
              title: 'Drink Water',
              remindAt: DateTime.now().add(const Duration(hours: 3)),
              status: ReminderStatus.pending,
              patientId: 'currentUser',
              type: ReminderType.task,
              createdAt: DateTime.now(),
            ),
            Reminder(
              id: '3',
              title: 'Afternoon Walk',
              remindAt: DateTime.now().add(const Duration(hours: 5)),
              status: ReminderStatus.pending,
              patientId: 'currentUser',
              type: ReminderType.task,
              createdAt: DateTime.now(),
            ),
          ],
        ));

  void toggleReminder(String id) {
    final updatedReminders = state.reminders.map((reminder) {
      if (reminder.id == id) {
        final newStatus = reminder.status == ReminderStatus.completed
            ? ReminderStatus.pending
            : ReminderStatus.completed;
        return reminder.copyWith(status: newStatus);
      }
      return reminder;
    }).toList();

    state = state.copyWith(reminders: updatedReminders);
  }

  void setOfflineStatus(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }

  void triggerSOS() {
    // Logic for SOS would go here (API call, SMS, etc.)
    print('SOS Triggered!');
  }
}

// --- Providers ---

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel();
});
