import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sos_messages.dart';

class SosMessagesRepository {
  final SupabaseClient _supabase;
  static const _tableName = 'sos_messages';

  SosMessagesRepository(this._supabase);

  // Stream provider for a specific patient's SOS messages
  Stream<List<SosMessage>> getPatientSosMessagesStream(String patientId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => SosMessage.fromJson(json)).toList());
  }

  // Stream provider for all unread SOS messages
  Stream<List<SosMessage>> getAllUnreadSosMessagesStream() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('is_marked_as_read', false)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => SosMessage.fromJson(json)).toList());
  }

  // Provider for unread SOS messages count
  Stream<int> getUnreadSosMessagesCountStream() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('is_marked_as_read', false)
        .map((data) => data.length);
  }

  // Mark a SOS message as read
  Future<void> markSosMessageAsRead(String messageId) async {
    await _supabase
        .from(_tableName)
        .update({'is_marked_as_read': true}).eq('id', messageId);
  }

  // Mark all messages as read for a patient
  Future<void> markPatientSosMessagesAsRead(String patientId) async {
    await _supabase
        .from(_tableName)
        .update({'is_marked_as_read': true})
        .eq('patient_id', patientId)
        .eq('is_marked_as_read', false);
  }

  // Delete a SOS message
  Future<void> deleteSosMessage(String messageId) async {
    await _supabase.from(_tableName).delete().eq('id', messageId);
  }
}
