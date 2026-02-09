import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/reminder.dart';
import '../../../../data/repositories/reminder_repository.dart';
import '../../../../providers/service_providers.dart';
// import 'package:audioplayers/audioplayers.dart'; // Or just_audio if desired, but VM might not play audio directly?
// VM creates reminders. UI plays audio.

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
          r.status !=
              ReminderStatus
                  .missed; // Or include missed? Prompt says "Today, Upcoming, Completed". Usually Today includes pending.
    }).toList();
  }

  List<Reminder> get upcomingReminders {
    final now = DateTime.now();
    // upcoming means after today? or just future time?
    // "Today" tab handles today. "Upcoming" usually means tomorrow onwards or later today?
    // Let's say strictly after today for separation, or just future.
    // Common pattern: Today = starts today. Upcoming = starts tomorrow onwards.
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return reminders
        .where((r) =>
            r.remindAt.isAfter(tomorrow) &&
            r.status != ReminderStatus.completed)
        .toList();
  }

  List<Reminder> get completedReminders {
    return reminders
        .where((r) => r.status == ReminderStatus.completed)
        .toList();
  }
}

class ReminderViewModel extends StateNotifier<ReminderState> {
  final ReminderRepository _repository;
  // final NotificationService _notificationService; // Injected via provider if needed, or we use specialized provider.
  // Actually VM should coordinate.
  final Ref _ref;

  ReminderViewModel(this._repository, this._ref) : super(ReminderState()) {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    state = state.copyWith(isLoading: true);
    // TODO: Get real patient ID from helper/auth
    // For now assuming a single user or handled by repo if it knew the user.
    // But Repo method is `getReminders(patientId)`.
    // We can't easily get auth state synchronously in constructor if it changes.
    // But usually we init with a user ID.
    // For demo, we might use a fixed ID or assume the Repo handles it if specialized.
    // Let's just fetch dummy or empty for now.
    // Or, better, observe the auth state in the provider definition.

    // For now, load local:
    await _repository.init();
    final reminders =
        _repository.getReminders('currentUser'); // Replace with actual ID
    state = state.copyWith(reminders: reminders, isLoading: false);
  }

  Future<void> refresh(String patientId) async {
    state = state.copyWith(isLoading: true);
    await _repository.syncReminders(patientId);
    final reminders = _repository.getReminders(patientId);
    state = state.copyWith(reminders: reminders, isLoading: false);
  }

  Future<void> addReminder(Reminder reminder) async {
    state = state.copyWith(reminders: [...state.reminders, reminder]);
    await _repository.addReminder(reminder);

    // Schedule Notification
    final notifService = _ref.read(notificationServiceProvider);
    await notifService.scheduleReminder(reminder);

    // If audio exists, sync is handled by Repo (it tries to upload/sync).
    // But Repo logic in step 4 doesn't upload files designated by `localAudioPath` to Supabase Storage.
    // It only inserts JSON.
    // We need to upload the file separately if `localAudioPath` is present, then update `voiceAudioUrl`.

    if (reminder.localAudioPath != null) {
      await _uploadVoiceFile(reminder);
    }
  }

  Future<void> _uploadVoiceFile(Reminder reminder) async {
    try {
      final file = File(reminder.localAudioPath!);
      if (!file.existsSync()) return;

      final path = 'voice-reminders/${reminder.patientId}/${reminder.id}.aac';

      final supabase = _ref.read(supabaseClientProvider);

      // Upload
      await supabase.storage.from('voice_reminders').upload(path, file);

      // Get URL
      final url = supabase.storage.from('voice_reminders').getPublicUrl(path);

      // Update Reminder
      final updated = reminder.copyWith(voiceAudioUrl: url, isSynced: false);
      // isSynced false because we just changed it and need to sync json again?
      // Actually `addReminder` already tried to sync.
      // We should update and sync again.
      await updateReminder(updated);
    } catch (e) {
      print('Upload audio failed: $e');
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _repository.updateReminder(reminder);
    final notifService = _ref.read(notificationServiceProvider);
    // Reschedule
    await notifService.cancelReminder(reminder.id);
    if (reminder.status == ReminderStatus.pending) {
      await notifService.scheduleReminder(reminder);
    }

    // Update state
    state = state.copyWith(
      reminders: [
        for (final r in state.reminders)
          if (r.id == reminder.id) reminder else r
      ],
    );
  }

  Future<void> deleteReminder(String id) async {
    await _repository.deleteReminder(id);
    final notifService = _ref.read(notificationServiceProvider);
    await notifService.cancelReminder(id);

    state = state.copyWith(
      reminders: state.reminders.where((r) => r.id != id).toList(),
    );
  }

  Future<void> markAsDone(String id) async {
    final reminder = state.reminders.firstWhere((r) => r.id == id);
    final updated = reminder.copyWith(
      status: ReminderStatus.completed,
      completionHistory: [...reminder.completionHistory, DateTime.now()],
    );
    await updateReminder(updated);
  }
}

final reminderViewModelProvider =
    StateNotifierProvider<ReminderViewModel, ReminderState>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return ReminderViewModel(repo, ref);
});
