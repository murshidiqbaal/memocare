import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/service_providers.dart';
import '../data/repositories/location_request_repository.dart';
import '../models/location_request.dart';

final locationRequestRepositoryProvider =
    Provider<LocationRequestRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LocationRequestRepository(supabase);
});

final pendingRequestsProvider =
    FutureProvider<List<LocationRequest>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repo = ref.watch(locationRequestRepositoryProvider);
  return repo.getPendingRequests(user.id);
});

final approveLocationRequestProvider =
    AsyncNotifierProvider<ApproveLocationAction, void>(
        ApproveLocationAction.new);

class ApproveLocationAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> approve(LocationRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(locationRequestRepositoryProvider)
          .approveLocationRequest(request);
      ref.invalidate(pendingRequestsProvider);
    });
  }
}

final rejectLocationRequestProvider =
    AsyncNotifierProvider<RejectLocationAction, void>(RejectLocationAction.new);

class RejectLocationAction extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> reject(String requestId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(locationRequestRepositoryProvider)
          .rejectLocationRequest(requestId);
      ref.invalidate(pendingRequestsProvider);
    });
  }
}
