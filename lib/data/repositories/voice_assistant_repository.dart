import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/voice_query.dart';

/// Repository for managing voice query history
/// Handles Supabase synchronization
class VoiceAssistantRepository {
  final SupabaseClient _supabase;

  VoiceAssistantRepository(this._supabase);

  /// Get all voice queries for a patient
  Future<List<VoiceQuery>> getQueries(String patientId) async {
    try {
      final data = await _supabase
          .from('voice_queries')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(50); // Limit to recent 50 queries

      return (data as List).map((map) => VoiceQuery.fromJson(map)).toList();
    } catch (e) {
      print('Fetch voice queries failed: $e');
      return [];
    }
  }

  /// Add a new voice query
  Future<void> addQuery(VoiceQuery query) async {
    try {
      await _supabase.from('voice_queries').insert(query.toJson());
    } catch (e) {
      print('Sync add voice query failed: $e');
      throw Exception('Database sync failed: $e');
    }
  }

  /// Delete a voice query
  Future<void> deleteQuery(String id) async {
    try {
      await _supabase.from('voice_queries').delete().eq('id', id);
    } catch (e) {
      print('Sync delete voice query failed: $e');
      throw Exception('Delete failed: $e');
    }
  }
}
