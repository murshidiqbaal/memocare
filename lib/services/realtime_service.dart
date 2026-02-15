import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/reminder.dart';
import '../data/models/sos_event.dart';
import '../data/repositories/reminder_repository.dart';
import '../providers/service_providers.dart';
import 'notification/reminder_notification_service.dart';

// Stream Providers for Realtime Data
final realtimeReminderStreamProvider =
    StreamProvider.autoDispose<List<Reminder>>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.reminderStream;
});

final realtimeSosStreamProvider = StreamProvider.autoDispose<SosEvent?>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.sosStream;
});

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(
    ref.watch(supabaseClientProvider),
    ref.watch(reminderRepositoryProvider),
    ref.watch(reminderNotificationServiceProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

class RealtimeService {
  final SupabaseClient _supabase;
  final ReminderRepository _reminderRepo;
  final ReminderNotificationService _notificationService;

  RealtimeChannel? _patientChannel;
  RealtimeChannel? _caregiverChannel;

  // Streams to expose to UI
  final _reminderController = StreamController<List<Reminder>>.broadcast();
  Stream<List<Reminder>> get reminderStream => _reminderController.stream;

  final _sosController = StreamController<SosEvent?>.broadcast();
  Stream<SosEvent?> get sosStream => _sosController.stream;

  RealtimeService(
    this._supabase,
    this._reminderRepo,
    this._notificationService,
  );

  /// Initialize realtime subscriptions based on user role
  Future<void> initialize() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Fetch user role
    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = profile?['role'] as String?;

    if (role == 'patient') {
      _subscribeAsPatient(user.id);
    } else if (role == 'caregiver') {
      await _subscribeAsCaregiver(user.id);
    }
  }

  /// Patient subscriptions:
  void _subscribeAsPatient(String patientId) {
    _patientChannel = _supabase.channel('patient_realtime:$patientId');

    _patientChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reminders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ),
          callback: (payload) =>
              _handleReminderChange(payload, isPatient: true),
        )
        .subscribe();

    print('RealtimeService: Subscribed as Patient ($patientId)');
  }

  /// Caregiver subscriptions:
  Future<void> _subscribeAsCaregiver(String userId) async {
    final caregiverProfile = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (caregiverProfile == null) return;
    final String caregiverId = caregiverProfile['id'];

    final List<dynamic> links = await _supabase
        .from('caregiver_patient_links')
        .select('patient_id')
        .eq('caregiver_id', caregiverId);

    final patientIds = links.map((l) => l['patient_id'] as String).toList();

    // We subscribe regardless of patient count for the connection listener
    _caregiverChannel = _supabase.channel('caregiver_realtime:$caregiverId');

    for (final pid in patientIds) {
      // SOS Alerts
      _caregiverChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'sos_events',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'patient_id',
          value: pid,
        ),
        callback: (payload) => _handleSosAlert(payload),
      );

      // Reminder Adherence (Updates)
      _caregiverChannel!.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'reminders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'patient_id',
          value: pid,
        ),
        callback: (payload) => _handleReminderChange(payload, isPatient: false),
      );
    }

    // Listen for new connections
    _caregiverChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'caregiver_patient_links',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'caregiver_id',
        value: caregiverId,
      ),
      callback: (payload) {
        _caregiverChannel?.unsubscribe();
        _subscribeAsCaregiver(userId);
        print('RealtimeService: New patient linked, re-subscribing.');
      },
    );

    _caregiverChannel!.subscribe();
    print(
        'RealtimeService: Subscribed as Caregiver ($caregiverId) for ${patientIds.length} patients');
  }

  Future<void> _handleReminderChange(PostgresChangePayload payload,
      {required bool isPatient}) async {
    final eventType = payload.eventType;
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    print('RealtimeService: Reminder Change Event: $eventType');

    try {
      if (eventType == PostgresChangeEvent.insert) {
        if (newRecord.isEmpty) return;
        final reminder = Reminder.fromJson(newRecord);
        await _reminderRepo.upsertFromRealtime(reminder);

        if (isPatient) {
          if (reminder.remindAt.isAfter(DateTime.now())) {
            await _notificationService.scheduleReminder(reminder);
          }
          _refreshReminderStream(reminder.patientId);
        }
      } else if (eventType == PostgresChangeEvent.update) {
        if (newRecord.isEmpty) return;
        final reminder = Reminder.fromJson(newRecord);
        await _reminderRepo.upsertFromRealtime(reminder);

        if (isPatient) {
          if (reminder.isCompleted) {
            await _notificationService.cancelNotification(reminder.id.hashCode);
          } else {
            await _notificationService.scheduleReminder(reminder);
          }
          _refreshReminderStream(reminder.patientId);
        } else {
          print(
              'Caregiver received reminder update for patient: ${reminder.patientId}');
        }
      } else if (eventType == PostgresChangeEvent.delete) {
        final id = oldRecord['id'] as String?;
        if (id != null) {
          await _reminderRepo.deleteFromRealtime(id);
          if (isPatient) {
            await _notificationService.cancelNotification(id.hashCode);
            final user = _supabase.auth.currentUser;
            if (user != null) _refreshReminderStream(user.id);
          }
        }
      }
    } catch (e) {
      print('RealtimeService: Error handling reminder change: $e');
    }
  }

  void _handleSosAlert(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.insert) {
      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      try {
        final sosEvent = SosEvent.fromJson(newRecord);
        _sosController.add(sosEvent);

        _notificationService.showEmergencyNotification(
          title: 'SOS ALERT',
          body: 'Patient has triggered an emergency alert!',
        );
      } catch (e) {
        print('RealtimeService: Error handling SOS: $e');
      }
    }
  }

  void _refreshReminderStream(String patientId) {
    final reminders = _reminderRepo.getReminders(patientId);
    _reminderController.add(reminders);
  }

  void dispose() {
    print('RealtimeService: Disposing...');
    _patientChannel?.unsubscribe();
    _caregiverChannel?.unsubscribe();
    _reminderController.close();
    _sosController.close();
  }
}
