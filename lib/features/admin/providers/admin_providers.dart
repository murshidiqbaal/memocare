import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/supabase_provider.dart';
import '../../auth/models/caregiver_request.dart';
import '../repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AdminRepository(supabase);
});

final pendingCaregiverRequestsProvider =
    FutureProvider<List<CaregiverRequest>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getPendingRequests();
});
