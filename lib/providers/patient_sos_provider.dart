import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SosMessage {
  final String id;
  final String patientId;
  final String? caregiverId;
  final double? lat;
  final double? lng;
  final String? status;
  final String? note;
  final DateTime triggeredAt;
  final bool isRead;

  SosMessage({
    required this.id,
    required this.patientId,
    this.caregiverId,
    this.lat,
    this.lng,
    this.status,
    this.note,
    required this.triggeredAt,
    required this.isRead,
  });

  factory SosMessage.fromJson(Map<String, dynamic> json) {
    return SosMessage(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      caregiverId: json['caregiver_id'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      status: json['status'] as String?,
      note: json['note'] as String?,
      triggeredAt: DateTime.parse(json['triggered_at']),
      isRead: json['is_read'] ?? false,
    );
  }
}

class SosState {
  final List<SosMessage> messages;

  SosState({required this.messages});

  int get unreadCount => messages.where((m) => !m.isRead).length;

  SosMessage? get latestUnread {
    final unread = messages.where((m) => !m.isRead).toList();
    if (unread.isEmpty) return null;

    unread.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    return unread.first;
  }
}

class SosNotifier extends FamilyAsyncNotifier<SosState, String> {
  StreamSubscription? _sub;

  @override
  Future<SosState> build(String patientId) async {
    if (patientId.isEmpty) {
      return SosState(messages: []);
    }

    final supabase = Supabase.instance.client;

    /// Initial fetch
    final rows = await supabase
        .from('sos_messages')
        .select(
            'id, patient_id, caregiver_id, lat, lng, status, note, triggered_at, is_read')
        .eq('patient_id', patientId)
        .eq('is_read', false)
        .order('triggered_at', ascending: false);

    final messages = (rows as List).map((r) => SosMessage.fromJson(r)).toList();

    /// Realtime subscription
    _sub = supabase
        .from('sos_messages')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('triggered_at', ascending: false)
        .listen((data) {
          final msgs = data.map((r) => SosMessage.fromJson(r)).toList();

          /// keep only unread alerts
          final unread = msgs.where((m) => !m.isRead).toList();

          state = AsyncData(SosState(messages: unread));
        });

    ref.onDispose(() {
      _sub?.cancel();
    });

    return SosState(messages: messages);
  }

  /// Mark single alert as read
  Future<void> markAsRead(String id) async {
    await Supabase.instance.client
        .from('sos_messages')
        .update({'is_read': true}).eq('id', id);
  }

  /// Mark all alerts for this patient as read
  Future<void> markAllAsRead() async {
    final patientId = arg;

    await Supabase.instance.client
        .from('sos_messages')
        .update({'is_read': true})
        .eq('patient_id', patientId)
        .eq('is_read', false);
  }
}

final patientSosProvider =
    AsyncNotifierProvider.family<SosNotifier, SosState, String>(
  SosNotifier.new,
);
