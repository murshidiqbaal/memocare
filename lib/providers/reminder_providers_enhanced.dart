import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/reminder.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// ============================================================================
/// PATIENT REMINDERS - REALTIME STREAM
/// ============================================================================

/// ✅ Patient Reminders Stream Provider
/// Watches reminders for the current patient in realtime
/// Updates instantly when caregivers create/update/delete reminders
final patientRemindersStreamProvider =
    StreamProvider.autoDispose<List<Reminder>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(reminderRepositoryProvider);

  // Initialize repository
  repository.init();

  // Return realtime stream
  return repository.watchPatientRemindersRealtime(user.id);
});

/// ✅ Patient Reminders Provider (for backward compatibility)
/// Returns current state from stream
final patientRemindersProvider =
    Provider.autoDispose<AsyncValue<List<Reminder>>>((ref) {
  return ref.watch(patientRemindersStreamProvider);
});

/// ============================================================================
/// CAREGIVER REMINDERS - REALTIME STREAM
/// ============================================================================

/// ✅ Caregiver Reminders Stream Provider
/// Watches reminders for all linked patients in realtime
/// Updates instantly when patients complete reminders
final caregiverRemindersStreamProvider =
    StreamProvider.autoDispose<List<Reminder>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(reminderRepositoryProvider);

  // Initialize repository
  repository.init();

  // Return realtime stream for caregiver's linked patients
  return repository.watchCaregiverPatientReminders(user.id);
});

/// ✅ Caregiver Reminders Provider (for backward compatibility)
final caregiverRemindersProvider =
    Provider.autoDispose<AsyncValue<List<Reminder>>>((ref) {
  return ref.watch(caregiverRemindersStreamProvider);
});

/// ============================================================================
/// CREATE REMINDER PROVIDER
/// ============================================================================

/// ✅ Create Reminder Provider (AsyncNotifier)
/// Handles creating reminders for patients (caregiver action)
final createReminderProvider =
    AsyncNotifierProvider<CreateReminderNotifier, void>(
        CreateReminderNotifier.new);

class CreateReminderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state
  }

  /// Create a reminder for a specific patient
  Future<void> createReminder({
    required Reminder reminder,
    required String patientId,
  }) async {
    state = const AsyncLoading();

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final repository = ref.read(reminderRepositoryProvider);
      final notificationService = ref.read(reminderNotificationServiceProvider);

      // Create reminder in database
      await repository.createReminderForPatient(
        reminder: reminder.copyWith(patientId: patientId),
        createdBy: user.id,
      );

      // Schedule notification
      await notificationService.scheduleReminder(reminder);

      // Invalidate streams to refresh UI
      ref.invalidate(patientRemindersStreamProvider);
      ref.invalidate(caregiverRemindersStreamProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// ============================================================================
/// COMPLETE REMINDER PROVIDER
/// ============================================================================

/// ✅ Complete Reminder Provider
/// Handles marking reminders as completed
/// Syncs instantly to caregiver via realtime
final completeReminderProvider =
    AsyncNotifierProvider<CompleteReminderNotifier, void>(
        CompleteReminderNotifier.new);

class CompleteReminderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state
  }

  /// Mark a reminder as completed
  Future<void> completeReminder(String reminderId) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(reminderRepositoryProvider);
      final notificationService = ref.read(reminderNotificationServiceProvider);

      // Mark as completed in database
      await repository.markReminderCompleted(reminderId);

      // Cancel notification (if it's not a repeating reminder)
      await notificationService.cancelReminderById(reminderId);

      // Invalidate streams to refresh UI
      ref.invalidate(patientRemindersStreamProvider);
      ref.invalidate(caregiverRemindersStreamProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// ============================================================================
/// UPDATE REMINDER PROVIDER
/// ============================================================================

/// ✅ Update Reminder Provider
final updateReminderProvider =
    AsyncNotifierProvider<UpdateReminderNotifier, void>(
        UpdateReminderNotifier.new);

class UpdateReminderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state
  }

  /// Update an existing reminder
  Future<void> updateReminder(Reminder reminder) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(reminderRepositoryProvider);
      final notificationService = ref.read(reminderNotificationServiceProvider);

      // Update in database
      await repository.updateReminder(reminder);

      // Reschedule notification
      await notificationService.cancelReminder(reminder);
      await notificationService.scheduleReminder(reminder);

      // Invalidate streams
      ref.invalidate(patientRemindersStreamProvider);
      ref.invalidate(caregiverRemindersStreamProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// ============================================================================
/// DELETE REMINDER PROVIDER
/// ============================================================================

/// ✅ Delete Reminder Provider
final deleteReminderProvider =
    AsyncNotifierProvider<DeleteReminderNotifier, void>(
        DeleteReminderNotifier.new);

class DeleteReminderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(reminderRepositoryProvider);
      final notificationService = ref.read(reminderNotificationServiceProvider);

      // Delete from database
      await repository.deleteReminder(reminderId);

      // Cancel notification
      await notificationService.cancelReminderById(reminderId);

      // Invalidate streams
      ref.invalidate(patientRemindersStreamProvider);
      ref.invalidate(caregiverRemindersStreamProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// ============================================================================
/// NOTIFICATION INITIALIZATION PROVIDER
/// ============================================================================

/// ✅ Notification Init Provider
/// Initializes notification service and reschedules reminders on app start
final notificationInitProvider = FutureProvider<void>((ref) async {
  final notificationService = ref.watch(reminderNotificationServiceProvider);

  // Initialize notification service
  await notificationService.init();

  // Request permissions
  await notificationService.requestPermissions();
});
