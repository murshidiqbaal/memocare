import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/reminder.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// ============================================================================
/// PATIENT REMINDERS - REALTIME STREAM
/// ============================================================================

/// ✅ Patient Reminders Stream Provider
/// Watches reminders for the current patient in realtime.
///
/// FIX: Resolves `patients.id` (internal PK) from the auth UUID before
/// streaming, instead of incorrectly passing `auth.users.id` as `patient_id`.
final patientRemindersStreamProvider =
    StreamProvider.autoDispose<List<Reminder>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final repository = ref.watch(reminderRepositoryProvider);
  final patientRepo = ref.watch(patientRepositoryProvider);

  // Resolve the internal patients.id — not the auth UUID
  final String patientId;
  try {
    patientId = await patientRepo.getOrCreatePatientProfile(user.id);
  } catch (e) {
    yield [];
    return;
  }

  repository.init();

  yield* repository.watchPatientRemindersRealtime(patientId);
});

/// ✅ Patient Reminders Provider (for backward compatibility)
final patientRemindersProvider =
    Provider.autoDispose<AsyncValue<List<Reminder>>>((ref) {
  return ref.watch(patientRemindersStreamProvider);
});

/// ============================================================================
/// CAREGIVER REMINDERS - REALTIME STREAM
/// ============================================================================

/// ✅ Caregiver Reminders Stream Provider
/// Watches reminders for all linked patients in realtime.
///
/// FIX: Resolves `caregiver_profiles.id` (internal PK) from the auth UUID
/// before streaming, instead of incorrectly passing `auth.users.id` as
/// `caregiver_id`.
final caregiverRemindersStreamProvider =
    StreamProvider.autoDispose<List<Reminder>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final repository = ref.watch(reminderRepositoryProvider);
  final caregiverRepo = ref.watch(caregiverRepositoryProvider);

  // Resolve the internal caregiver_profiles.id — not the auth UUID
  final String caregiverId;
  try {
    caregiverId = await caregiverRepo.getOrCreateCaregiverProfile(user.id);
  } catch (e) {
    yield [];
    return;
  }

  repository.init();

  yield* repository.watchCaregiverPatientReminders(caregiverId);
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
/// Handles creating reminders for patients (caregiver action).
final createReminderProvider =
    AsyncNotifierProvider<CreateReminderNotifier, void>(
        CreateReminderNotifier.new);

class CreateReminderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state
  }

  /// Create a reminder for a specific patient.
  ///
  /// Uses [caregiverIdProvider] as the SINGLE SOURCE OF TRUTH for the
  /// `caregiver_profiles.id` FK value.  The auth.users.id is NEVER used
  /// as caregiverId — that would violate the FK constraint.
  Future<void> createReminder({
    required Reminder reminder,
    required String patientId,
  }) async {
    state = const AsyncLoading();

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final profile = await ref.read(userProfileProvider.future);
      final String userRole = profile?.role ?? 'patient';

      final repository = ref.read(reminderRepositoryProvider);
      final notificationService = ref.read(reminderNotificationServiceProvider);

      // ── Resolve caregiver_profiles.id ──────
      final String resolvedCaregiverId =
          await ref.read(caregiverIdProvider.future);

      if (resolvedCaregiverId.isEmpty && userRole == 'caregiver') {
        throw Exception(
            '[CreateReminderNotifier] caregiverIdProvider returned empty id for caregiver user.');
      }

      // ── Resolve patient_id ──────────────────────────────────────────────────
      final String resolvedPatientId =
          reminder.patientId.isNotEmpty ? reminder.patientId : patientId;

      // ── PART 5: Validate link exists if caregiver is creating ───────────────
      if (userRole == 'caregiver') {
        final supabase = Supabase.instance.client;
        final linkCheck = await supabase
            .from('caregiver_patient_links')
            .select()
            .eq('caregiver_id', resolvedCaregiverId)
            .eq('patient_id', resolvedPatientId)
            .maybeSingle();

        if (linkCheck == null) {
          throw Exception(
              'Validation Error: You are not linked to this patient.');
        }
      }

      debugPrint('[CreateReminderNotifier] Creating Reminder:\n'
          '  Auth UID      = ${user.id}\n'
          '  Role          = $userRole\n'
          '  caregiver_id  = $resolvedCaregiverId\n'
          '  patient_id    = $resolvedPatientId\n'
          '  created_by    = ${user.id}\n'
          '  created_role  = $userRole');

      // Always override IDs right before save
      final reminderToSave = reminder.copyWith(
        patientId: resolvedPatientId,
        caregiverId: resolvedCaregiverId,
        createdBy: user.id,
        createdRole: userRole,
      );

      await repository.createReminderForPatient(reminder: reminderToSave);

      // Schedule notification
      await notificationService.scheduleReminder(reminderToSave);

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

      await repository.markReminderCompleted(reminderId);
      await notificationService.cancelReminderById(reminderId);

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

      await repository.updateReminder(reminder);

      await notificationService.cancelReminder(reminder);
      await notificationService.scheduleReminder(reminder);

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

      await repository.deleteReminder(reminderId);
      await notificationService.cancelReminderById(reminderId);

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
final notificationInitProvider = FutureProvider<void>((ref) async {
  final notificationService = ref.watch(reminderNotificationServiceProvider);

  await notificationService.init();
  await notificationService.requestPermissions();
});
