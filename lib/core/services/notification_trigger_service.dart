import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationTriggerService
//
// Calls the Supabase Edge Function `send-reminder-notification` to deliver
// push notifications to patient devices and linked caregivers.
//
// This is the Flutter-side half of the notification pipeline.
// The Edge Function is the server-side half that calls FCM HTTP v1 API.
//
// Usage:
//   ref.read(notificationTriggerProvider).sendReminderCreated(reminder);
//   ref.read(notificationTriggerProvider).sendReminderDue(reminder);
// ─────────────────────────────────────────────────────────────────────────────
class NotificationTriggerService {
  final SupabaseClient _supabase;

  NotificationTriggerService(this._supabase);

  // ── Public Trigger Methods ─────────────────────────────────────────────────

  /// Called when a caregiver creates a new reminder.
  /// Notifies the PATIENT device.
  Future<void> sendReminderCreated({
    required String patientId,
    required String reminderId,
    required String reminderTitle,
    String? reminderDescription,
  }) async {
    await _invoke(
      patientId: patientId,
      reminderId: reminderId,
      title: '🔔 New Reminder Added',
      body: reminderTitle +
          (reminderDescription != null ? '\n$reminderDescription' : ''),
      notificationType: 'reminder_created',
      notifyPatient: true,
      notifyCaregivers: false,
    );
  }

  /// Called when a reminder time is reached.
  /// Notifies the PATIENT device (primary) and caregivers (for monitoring).
  Future<void> sendReminderDue({
    required String patientId,
    required String reminderId,
    required String reminderTitle,
    required String reminderType, // 'medication', 'appointment', 'task'
  }) async {
    final body = _bodyForType(reminderType, reminderTitle);

    await _invoke(
      patientId: patientId,
      reminderId: reminderId,
      title: '⏰ Reminder: $reminderTitle',
      body: body,
      notificationType: 'reminder_due',
      notifyPatient: true,
      notifyCaregivers:
          true, // Caregivers also get notified when patient has a due reminder
    );
  }

  /// Called when a reminder is snoozed.
  Future<void> sendReminderSnoozed({
    required String patientId,
    required String reminderId,
    required String reminderTitle,
    required int snoozeMinutes,
  }) async {
    await _invoke(
      patientId: patientId,
      reminderId: reminderId,
      title: '😴 Reminder Snoozed',
      body: '$reminderTitle – will remind again in ${snoozeMinutes}m',
      notificationType: 'reminder_snoozed',
      notifyPatient: false, // Patient snoozed it themselves
      notifyCaregivers: true,
    );
  }

  /// Called when a reminder is missed (past due + not completed).
  Future<void> sendReminderMissed({
    required String patientId,
    required String reminderId,
    required String reminderTitle,
  }) async {
    await _invoke(
      patientId: patientId,
      reminderId: reminderId,
      title: '⚠️ Missed Reminder',
      body: '$reminderTitle was not completed',
      notificationType: 'reminder_missed',
      notifyPatient: true,
      notifyCaregivers: true,
    );
  }

  /// Called when a reminder is updated by the caregiver.
  Future<void> sendReminderUpdated({
    required String patientId,
    required String reminderId,
    required String reminderTitle,
  }) async {
    await _invoke(
      patientId: patientId,
      reminderId: reminderId,
      title: '✏️ Reminder Updated',
      body: '$reminderTitle has been updated',
      notificationType: 'reminder_updated',
      notifyPatient: true,
      notifyCaregivers: false,
    );
  }

  // ── Edge Function Invocation ───────────────────────────────────────────────

  Future<void> _invoke({
    required String patientId,
    required String reminderId,
    required String title,
    required String body,
    required String notificationType,
    required bool notifyPatient,
    required bool notifyCaregivers,
  }) async {
    if (patientId.isEmpty) {
      debugLog('Skipping — patientId is empty.');
      return;
    }

    try {
      final response = await _supabase.functions.invoke(
        'send-reminder-notification',
        body: {
          'patient_id': patientId,
          'reminder_id': reminderId,
          'title': title,
          'body': body,
          'notification_type': notificationType,
          'notify_patient': notifyPatient,
          'notify_caregivers': notifyCaregivers,
          // Extra data payload (available in message.data on device)
          'data': {
            'type': 'reminder',
            'reminder_id': reminderId,
            'notification_type': notificationType,
          },
        },
      );

      if (response.status >= 200 && response.status < 300) {
        debugLog('Push sent successfully for $notificationType');
      } else {
        debugLog(
            'Edge Function returned status ${response.status}: ${response.data}');
      }
    } on FunctionException catch (e) {
      debugLog('FunctionException: ${e.status} – ${e.details}');
    } catch (e) {
      debugLog('Unexpected error invoking Edge Function: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _bodyForType(String reminderType, String title) {
    switch (reminderType.toLowerCase()) {
      case 'medication':
        return 'Time to take your medication: $title';
      case 'appointment':
        return 'You have an appointment: $title';
      case 'task':
        return 'Reminder: $title';
      default:
        return "It's time for: $title";
    }
  }

  void debugLog(String msg) {
    debugPrint('[NotificationTrigger] $msg');
  }
}
