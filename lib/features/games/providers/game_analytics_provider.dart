import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';
import '../../games/data/game_analytics_repository.dart';

/// Provide the new GameAnalyticsRepository
final gameAnalyticsRepositoryProvider =
    Provider<GameAnalyticsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return GameAnalyticsRepository(supabase);
});

/// RLS Safe & Realtime Auto-refreshing caregiver provider for game analytics
final caregiverPatientAnalyticsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final supabase = ref.watch(supabaseClientProvider);

  // Use a FutureProvider inside to lazily get caregiver ID, then switch to a stream!
  return Stream.fromFuture(supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle())
      .asyncExpand((caregiverData) {
    if (caregiverData == null) {
      return Stream.value([]);
    }

    final String caregiverId = caregiverData['id'];

    return supabase
        .from('game_analytics_daily') // Stream listening to the table
        .stream(primaryKey: ['id']).map((data) {
      // Refetch filtered list due to the stream not supporting inner joins well
      // So, on every realtime change, we fetch the fully joined data!
      final repo = ref.read(gameAnalyticsRepositoryProvider);
      return Stream.fromFuture(repo.getCaregiverPatientAnalytics(caregiverId));
    }).asyncExpand((events) => events);
  });
});
