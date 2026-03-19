import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/sos_message.dart';
import '../../../../data/models/patient_location.dart';
import '../../../../providers/supabase_provider.dart';

final sosSystemRepositoryProvider = Provider<SosSystemRepository>((ref) {
  return SosSystemRepository(ref.watch(supabaseClientProvider));
});

class SosSystemRepository {
  final SupabaseClient _supabase;

  SosSystemRepository(this._supabase);

  // --- SOS Message CRUD ---

  Future<void> insertSosMessage(SosMessage message) async {
    try {
      await _supabase.from('sos_messages').insert(message.toJson());
    } catch (e) {
      print('Error inserting SOS message: $e');
      rethrow;
    }
  }

  Future<void> updateSosStatus(String sosId, String status) async {
    try {
      await _supabase
          .from('sos_messages')
          .update({'status': status})
          .eq('id', sosId);
    } catch (e) {
      print('Error updating SOS status: $e');
      rethrow;
    }
  }

  Stream<List<SosMessage>> streamActiveSosMessages(String caregiverId) {
    return _supabase
        .from('sos_messages')
        .stream(primaryKey: ['id'])
        .eq('caregiver_id', caregiverId)
        .order('triggered_at', ascending: false)
        .map((data) => data
            .where((json) => json['status'] != 'resolved')
            .map((json) => SosMessage.fromJson(json))
            .toList());
  }

  // --- Patient Location Tracking ---

  Future<void> upsertPatientLocation(PatientLocation location) async {
    try {
      final payload = location.toJson();
      print('Upserting patient location payload: $payload');
      await _supabase.from('patient_locations').upsert(
        payload,
        onConflict: 'patient_id',
      );
    } catch (e) {
      print('Error upserting patient location: $e');
      // non-critical, so we can ignore or rethrow based on preference
    }
  }

  Stream<PatientLocation?> streamPatientLocation(String patientId) {
    return _supabase
        .from('patient_locations')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .map((data) {
      if (data.isEmpty) return null;
      return PatientLocation.fromJson(data.first);
    });
  }
}
