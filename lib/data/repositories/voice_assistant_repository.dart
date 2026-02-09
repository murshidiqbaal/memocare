import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/voice_query.dart';

/// Repository for managing voice query history
/// Handles local storage and Supabase synchronization
class VoiceAssistantRepository {
  final SupabaseClient _supabase;
  late Box<VoiceQuery> _box;
  bool _isInit = false;

  VoiceAssistantRepository(this._supabase);

  /// Initialize Hive box
  Future<void> init() async {
    if (_isInit) return;
    _box = await Hive.openBox<VoiceQuery>('voice_queries');
    _isInit = true;
  }

  /// Get all voice queries for a patient
  List<VoiceQuery> getQueries(String patientId) {
    if (!_isInit) return [];
    return _box.values.where((q) => q.patientId == patientId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Add a new voice query
  Future<void> addQuery(VoiceQuery query) async {
    await _box.put(query.id, query.copyWith(isSynced: false));

    // Try to sync immediately
    try {
      await _supabase.from('voice_queries').insert(query.toJson());
      await _box.put(query.id, query.copyWith(isSynced: true));
    } catch (e) {
      print('Sync add voice query failed: $e');
      // Will sync later
    }
  }

  /// Delete a voice query
  Future<void> deleteQuery(String id) async {
    await _box.delete(id);
    try {
      await _supabase.from('voice_queries').delete().eq('id', id);
    } catch (e) {
      print('Sync delete voice query failed: $e');
    }
  }

  /// Sync voice queries with Supabase
  Future<void> syncQueries(String patientId) async {
    await init();

    // Push local unsynced queries
    final unsynced = _box.values.where((q) => !q.isSynced);
    for (var q in unsynced) {
      try {
        await _supabase.from('voice_queries').upsert(q.toJson());
        await _box.put(q.id, q.copyWith(isSynced: true));
      } catch (e) {
        print('Sync push voice query failed for ${q.id}: $e');
      }
    }

    // Pull remote queries
    try {
      final data = await _supabase
          .from('voice_queries')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(50); // Limit to recent 50 queries

      for (var map in data) {
        final remote = VoiceQuery.fromJson(map);
        await _box.put(remote.id, remote.copyWith(isSynced: true));
      }
    } catch (e) {
      print('Sync pull voice queries failed: $e');
    }
  }

  /// Clear all local queries (for testing/reset)
  Future<void> clearLocal() async {
    await _box.clear();
  }
}
