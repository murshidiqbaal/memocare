import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/caregiver_request.dart';

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  Future<List<CaregiverRequest>> getPendingRequests() async {
    final response = await _supabase
        .from('caregiver_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((e) => CaregiverRequest.fromJson(e)).toList();
  }

  Future<void> approveRequest(String requestId) async {
    await _supabase
        .from('caregiver_requests')
        .update({'status': 'approved'}).eq('id', requestId);
  }

  Future<void> rejectRequest(String requestId) async {
    await _supabase
        .from('caregiver_requests')
        .update({'status': 'rejected'}).eq('id', requestId);
  }
}
